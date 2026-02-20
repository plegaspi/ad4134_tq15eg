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

#define THREAD_STACKSIZE 1024
#define MAX_CONNECTIONS 1
int new_sd[MAX_CONNECTIONS];

u16_t echo_port = 7;

extern uint32_t *dma_buf;
extern uint32_t adc_buffer_len;
extern uint8_t buffer_idx;
extern uint8_t buffer_store_idx;
extern int fill_buffer_to(uint32_t *buf);

uint8_t connection_disconnected = 0;


static uint32_t * const dma_buf0 =
    (uint32_t *)(CN0561_DDR_BASEADDR + DMA_BUFFER_OFFSET);

static uint32_t * const dma_buf1 =
    (uint32_t *)(CN0561_DDR_BASEADDR + DMA_BUFFER_OFFSET + DMA_TRANSFER_BYTES);

void print_echo_app_header(void *arg)
{
    xil_printf("%20s %6d %s\r\n", "streaming server",
                        echo_port,
                        "$ nc <board_ip> 7");
}

void process_stream_request(void *p)
{
    int sd = *(int *)p;

    int flag = 1;
    lwip_setsockopt(sd, IPPROTO_TCP, TCP_NODELAY, (void *)&flag, sizeof(flag));

    uint32_t *fill_buf = dma_buf0;
    uint32_t *send_buf = dma_buf1;

    if (fill_buffer_to(fill_buf) != 0) {
        xil_printf("SPI/DMA error on prime fill, aborting\r\n");
        lwip_close(sd);
        vTaskDelete(NULL);
        return;
    }


    uint32_t *tmp = fill_buf;
    fill_buf = send_buf;
    send_buf = tmp;

    uint32_t t_prev_send_end = 0;

    while (1) {
        uint64_t t0_fill = get_time_us();
        int fill_err = fill_buffer_to(fill_buf);
        uint64_t t1_fill = get_time_us();

        if (fill_err != 0) {
            xil_printf("SPI/DMA error, aborting send\r\n");
            break;
        }


        uint64_t t0_send = get_time_us();
        int sent = lwip_send(sd, (const void *)send_buf, DMA_TRANSFER_BYTES, 0);
        uint64_t t1_send = get_time_us();

        uint64_t deadtime = (t_prev_send_end > 0) ? (t0_send - t_prev_send_end) : 0;

        if (sent <= 0) {
            xil_printf("Client disconnected or send error. Closing socket.\r\n");
            break;
        }

        printf("Fill: %llu us | Send: %llu us | Deadtime: %llu us\r\n",
               t1_fill - t0_fill,
               t1_send - t0_send,
			   deadtime);

        t_prev_send_end = t1_send;

        tmp      = fill_buf;
        fill_buf = send_buf;
        send_buf = tmp;
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

    if (lwip_bind(sock, (struct sockaddr *)&address, sizeof(address)) < 0)
        return;

    lwip_listen(sock, 1);
    size = sizeof(remote);

    xil_printf("Waiting for client to stream data...\r\n");

    while (1) {
        new_sd[0] = lwip_accept(sock, (struct sockaddr *)&remote,
                                (socklen_t *)&size);
        if (new_sd[0] >= 0) {
            xil_printf("Client connected! Starting stream...\r\n");
            sys_thread_new("streambuf", process_stream_request,
                           (void *)&(new_sd[0]),
                           THREAD_STACKSIZE,
                           DEFAULT_THREAD_PRIO);
        }
    }
}
