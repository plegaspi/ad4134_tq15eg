#include <stdio.h>
#include <string.h>
#include <stdint.h>

#include "lwip/sockets.h"
#include "netif/xadapter.h"
#include "lwipopts.h"
#include "xil_printf.h"
#include "FreeRTOS.h"
#include "task.h"
#include "vitis/ad4134/ad713x.h"
#include <math.h>
#include "xtime_l.h"

#include "parameters.h"
#include "time_tools.h"

#define THREAD_STACKSIZE 1024
#define MAX_CONNECTIONS 1
int new_sd[MAX_CONNECTIONS];

u16_t echo_port = 7;


//extern uint32_t *adc_buffers[];
//extern aligned_buffers buffers[NUM_BUFFERS];
//extern uint32_t buffer_store[BUFFER_STORE_SIZE];
extern uint32_t *dma_buf;
extern uint32_t adc_buffer_len;
extern uint8_t buffer_idx;
extern uint8_t buffer_store_idx;
extern int fill_buffer(void);

uint8_t connection_disconnected = 0;
uint8_t printed = 0;

void print_echo_app_header(void *arg)
{
    xil_printf("%20s %6d %s\r\n", "streaming server",
                        echo_port,
                        "$ nc <board_ip> 7");
}

void process_stream_request(void *p)
{
	int sd = *(int *)p;
	int connection_alive = 1;

	while (connection_alive) {
		XTime time_start, time_end;
		XTime_GetTime(&time_start);
		if (fill_buffer() != 0) {
		    xil_printf("SPI/DMA error, aborting send\r\n");
		    connection_alive = 0;
		    break;
		}

		XTime_GetTime(&time_end);

		if (printed != 1) {
			printf("Offload Time: %lf s\r\n", ((double)(time_end - time_start) / (double)COUNTS_PER_SECOND));
			printed = 1;
		}

		buffer_idx = 0;
		/*Xil_DCacheInvalidateRange((INTPTR)buffers[buffer_idx].data, SAMPLE_DATA * sizeof(uint32_t));
		for (int i = 0; i < 1; i++ ) {
			int sent = lwip_send(sd, (const void *)&buffers[buffer_idx].data[i*SAMPLE_DATA], SAMPLE_DATA * sizeof(uint32_t), 0);
			if (sent <= 0) {
				xil_printf("Client disconnected or error. Closing socket.\r\n");
				break;
			}
		}*/
		uint64_t start_send_time = get_time_us();

		int sent = lwip_send(sd, (const void *)dma_buf, DMA_TRANSFER_BYTES, 0);
		if (sent <= 0) {
			xil_printf("Client disconnected or error. Closing socket.\r\n");
			break;
		}
		uint64_t end_send_time = get_time_us();
		printf("Send Time: %llu us \r\n", end_send_time - start_send_time);
	}
	lwip_close(sd);
	vTaskDelete(NULL);
}

void open_connection()
{
	int sock;
	int size;
	struct sockaddr_in address, remote;

	memset(&address, 0, sizeof(address));

	if ((sock = lwip_socket(AF_INET, SOCK_STREAM, 0)) < 0)
		return;

	address.sin_family = AF_INET;
	address.sin_port = htons(echo_port);
	address.sin_addr.s_addr = INADDR_ANY;

	if (lwip_bind(sock, (struct sockaddr *)&address, sizeof (address)) < 0)
		return;

	lwip_listen(sock, 1);
	size = sizeof(remote);

	xil_printf("Waiting for client to stream data...\r\n");

	while (1) {
		new_sd[0] = lwip_accept(sock, (struct sockaddr *)&remote, (socklen_t *)&size);
		if (new_sd[0] >= 0) {
			xil_printf("Client connected! Starting stream...\r\n");
			sys_thread_new("streambuf", process_stream_request,
				(void*)&(new_sd[0]),
				THREAD_STACKSIZE,
				DEFAULT_THREAD_PRIO);
		}
	}
}
