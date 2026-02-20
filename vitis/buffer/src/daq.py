import os
import socket
import struct
import h5py
import numpy as np
import signal
import time
import math
import threading
import queue
from serial import Serial

"""
@todo Update FPGA to output timestamps
@todo Separate logic for polling data and saving data into separate functions.
@todo AD4134 currently uses hard-coded parameters. Add configurable parameters
      (e.g. ODR) for AD4134 before collecting data. ODR is currently configured
      in lines 171 and 179 of main.c. Update FPGA code to listen for incoming
      Ethernet packets with config information.
@todo Support for detecting and logging PLL lock and chip error
@todo Add timestamps for each frame and reconstruction
@todo Increase amount of data transferred in Ethernet buffer.
@todo Real-time plotting
"""


class DAQ:

    BYTES_PER_SAMPLE = 4
    LSB = 4.096 / (2**23)
    TICKS_PER_SECOND = 666_666_687

    def __init__(
        self,
        board_ip: str = "192.168.1.10",
        port: int = 7,
        samples: int = 1024 * 20,
        channels: int = 4,
        timestamp_header: int = 0,
        filename: str = "test.hdf5",
        limit_frames: bool = False,
        num_frames: int = 10,
        uart_port: str = "/dev/ttyACM0",
        debug: bool = False,
        monitor_serial=False,
        keep_code=False,
        crc_check=False,
        padding_right=False,
        recv_queue_size: int = 32,
    ):
        self.board_ip = board_ip
        self.port = port
        self.samples = samples
        self.channels = channels
        self.timestamp_header = timestamp_header
        self.filename = filename
        self.socket = None
        self.connected = False
        self.frame_count = 0
        self.limit_frames = limit_frames
        self.num_frames = num_frames
        self.timestamp = 0
        self.ready = False
        self.uart_port = uart_port
        self.debug = debug
        self.monitor_serial = monitor_serial
        self.keep_code = keep_code
        self.crc_check = crc_check
        self.padding_right = padding_right
        self.recv_queue_size = recv_queue_size

        self.frame_size = (
            self.samples * self.channels + self.timestamp_header
        ) * self.BYTES_PER_SAMPLE

        self.frame_queue = queue.Queue(maxsize=self.recv_queue_size)

    def init_hdf5(self):
        self.file = h5py.File(self.filename, "w", libver="latest")
        self.data_dtype = "float64" if not self.keep_code else "uint32"
        self.data_ds = self.file.create_dataset(
            "data",
            shape=(0, self.channels),
            maxshape=(None, self.channels),
            chunks=(self.samples, self.channels),
            dtype=self.data_dtype,
        )

        self.file.swmr_mode = True

        if self.timestamp_header:
            self.time_ds = self.file.create_dataset(
                "time",
                shape=(0, 1),
                maxshape=(None, 1),
                chunks=(self.samples, 1),
                dtype=self.data_dtype,
            )
        print(f"Writing to '{self.filename}'...")

    @staticmethod
    def pll_settled(code: int) -> bool:
        pll_lock_mask = 0x00000040
        result = (code & pll_lock_mask) >> 6
        return result == 1

    @staticmethod
    def no_chip_error(code: int) -> bool:
        pll_lock_mask = 0x00000080
        result = (code & pll_lock_mask) >> 7
        return result == 1

    @staticmethod
    def reverse_bits(value: int) -> int:
        result = 0
        while value:
            result = (result << 1) | (value & 1)
            value >>= 1
        return result

    @staticmethod
    def convert_to_voltage(code: int, padding_right: bool = False) -> float:
        if padding_right:
            raw24 = (code & 0xFFFFFF00) >> 8
            if raw24 & 0x800000:
                raw24 -= 1 << 24
            return raw24 * DAQ.LSB
        else:
            raw24 = code & 0x00FFFFFF
            raw24 = raw24 * DAQ.LSB
            if raw24 > 4.095:
                raw24 -= 8.192
            return raw24

    @staticmethod
    def convert_voltage_to_code(voltage: float) -> int:
        raw24 = int(round(voltage / DAQ.LSB))
        if raw24 < 0:
            raw24 += 1 << 24
        return raw24

    @staticmethod
    def convert_to_timestamp_sec(header: tuple) -> float:
        hi, lo = header
        ticks = (hi << 32) | lo
        return ticks / DAQ.TICKS_PER_SECOND

    def connect(self):
        if self.monitor_serial:
            self.is_ready()
        time.sleep(5)
        self.socket = socket.create_connection((self.board_ip, self.port))

        self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 1024 * 1024)

        try:
            self.socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_QUICKACK, 1)
        except (AttributeError, OSError):
            pass

        self.socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)

        self.connected = True
        if self.debug:
            print(f"Connected to {self.board_ip}:{self.port}")

    def disconnect(self):
        if self.connected:
            self.socket.shutdown(socket.SHUT_RD)
            self.socket.close()
            self.connected = False
        else:
            if self.debug:
                print("DAQ is already disconnected")

    def _on_term(self, signum, frame):
        raise SystemExit

    def download_frame(self):
        buffer = bytearray(self.frame_size)
        view = memoryview(buffer)
        bytes_received = 0
        while bytes_received < self.frame_size:
            n = self.socket.recv_into(
                view[bytes_received:], self.frame_size - bytes_received
            )
            if not n:
                if self.debug:
                    print("Connection closed by remote.")
                return None
            bytes_received += n
        return bytes(buffer)

    def _receiver_thread(self, stop_event):
        while not stop_event.is_set():
            try:
                buffer = self.download_frame()
                if buffer is None:
                    break
                try:
                    self.socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_QUICKACK, 1)
                except (AttributeError, OSError):
                    pass
                self.frame_queue.put(buffer)
            except OSError:
                break

    def unpack_and_convert(self, buffer):
        offset = self.timestamp_header * self.BYTES_PER_SAMPLE
        raw = buffer[offset:]

        codes = np.frombuffer(raw, dtype=np.uint32).reshape(-1, self.channels)

        if self.keep_code:
            return codes.astype(np.uint32), offset

        if self.padding_right:
            raw24 = ((codes & 0xFFFFFF00) >> 8).astype(np.int32)
            raw24[raw24 & 0x800000 != 0] -= 1 << 24
            voltages = raw24.astype(np.float64) * self.LSB
        else:
            raw24 = (codes & 0x00FFFFFF).astype(np.float64) * self.LSB
            raw24[raw24 > 4.095] -= 8.192
            voltages = raw24

        return voltages, offset

    def write_data(self, data, buffer, offset):
        old_n = self.data_ds.shape[0]
        new_n = old_n + data.shape[0]
        self.data_ds.resize(new_n, axis=0)
        self.data_ds[old_n:new_n] = data

        if self.timestamp_header:
            hdr_words = struct.unpack(f"<{self.timestamp_header}I", buffer[:offset])
            ts = self.convert_to_timestamp_sec(tuple(hdr_words))
            self.time_ds.resize(new_n, axis=0)
            self.time_ds[old_n:new_n, 0] = ts

        self.file.flush()
        self.frame_count += 1
        if self.debug:
            print(f"Frame {self.frame_count} stored (total rows: {new_n})")

    def is_ready(self):
        ser = Serial(self.uart_port, 115200, timeout=1)
        target = "Waiting for client to stream data..."

        while True:
            line = ser.readline().decode(errors="ignore").strip()
            if line:
                if self.debug:
                    print(line)
            if target in line:
                print("Ready to stream data")
                self.ready = True
                break
        ser.close()

    def run(self, stop_event=None):
        signal.signal(signal.SIGTERM, self._on_term)
        if not self.connected:
            self.connect()

        recv_stop = threading.Event()
        recv_thread = threading.Thread(
            target=self._receiver_thread,
            args=(recv_stop,),
            daemon=True,
            name="daq-receiver",
        )
        recv_thread.start()

        frame_times = []

        try:
            while stop_event is None or not stop_event.is_set():
                if self.limit_frames and self.frame_count >= self.num_frames:
                    break

                try:
                    t0 = time.time_ns()
                    buffer = self.frame_queue.get(timeout=5.0)
                    t1 = time.time_ns()
                except queue.Empty:
                    print("Timeout waiting for frame — board may have disconnected.")
                    break

                data, offset = self.unpack_and_convert(buffer)

                if self.crc_check:
                    codes_raw = np.frombuffer(buffer[offset:], dtype=np.uint32).reshape(
                        -1, self.channels
                    )
                    for c in range(self.channels):
                        col = codes_raw[:, c]
                        if not np.all((col & 0x00000040) >> 6):
                            print(f"CH {c}: PLL IS NOT LOCKED (some samples)")
                        if not np.all((col & 0x00000080) >> 7):
                            print(f"CH {c}: CHIP ERROR (some samples)")

                if self.debug:
                    print(data)

                self.write_data(data, buffer, offset)

                elapsed_ns = t1 - t0
                frame_times.append(elapsed_ns)
                if self.debug:
                    print(
                        f"Frame {self.frame_count} | "
                        f"dead time: {elapsed_ns / 1e6:.3f} ms | "
                        f"queue depth: {self.frame_queue.qsize()}"
                    )

        except KeyboardInterrupt:
            print("\nInterrupted by user.")

        except SystemExit:
            print("\nInterrupted by terminate (SIGTERM)")

        finally:
            recv_stop.set()
            recv_thread.join(timeout=2)
            self.disconnect()

            if frame_times:
                avg_ms = np.mean(frame_times) / 1e6
                min_ms = np.min(frame_times) / 1e6
                max_ms = np.max(frame_times) / 1e6
                throughput = (
                    self.frame_size * self.frame_count / (sum(frame_times) / 1e9)
                ) / 1e6
                print(f"\n--- Transfer Stats ---")
                print(f"Frames received  : {self.frame_count}")
                print(f"Avg frame wait   : {avg_ms:.3f} ms")
                print(f"Min frame wait   : {min_ms:.3f} ms")
                print(f"Max frame wait   : {max_ms:.3f} ms")
                print(f"Throughput       : {throughput:.2f} MB/s")

            if hasattr(self, "file") and self.file:
                print("Closing HDF5 file...")
                self.file.close()


if __name__ == "__main__":
    daq = DAQ(
        samples=1024 * 15,
        channels=16,
        board_ip="192.168.0.10",
        filename="continuous-offload.hdf5",
        limit_frames=True,
        num_frames=5,
        debug=True,
        keep_code=False,
    )
    code = 0x00370219
    print(bin(code))
    print(f"PLL Settled: {daq.pll_settled(code)}")
    print(f"No Chip Error: {daq.no_chip_error(code)}")

    codes = [0x00FFA00]
    daq.init_hdf5()
    daq.run()
