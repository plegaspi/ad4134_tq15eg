#include <stdio.h>
#include "xparameters.h"
#include "netif/xadapter.h"
#include "platform_config.h"
#include "xil_printf.h"
#include "xtime_l.h"

#include "parameters.h"

#if LWIP_IPV6==1
#include "lwip/ip.h"
#else
#if LWIP_DHCP==1
#include "lwip/dhcp.h"
#endif
#endif

// AD4134 Libraries
#include <sleep.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#include "vitis/ad4134/spi_engine.h"
#include "vitis/ad4134/ad713x.h"
#include "vitis/ad4134/no_os_spi.h"
#include "vitis/ad4134/xilinx_spi.h"
#include "vitis/ad4134/no_os_delay.h"
#include "vitis/ad4134/no_os_gpio.h"
#include "vitis/ad4134/xilinx_gpio.h"
#include "vitis/ad4134/no_os_util.h"
#include "vitis/ad4134/no_os_error.h"
#include "vitis/ad4134/no_os_pwm.h"
#include "vitis/ad4134/axi_pwm_extra.h"
#include "vitis/ad4134/clk_axi_clkgen.h"
#include "vitis/ad4134/axi_dmac.h"

#include "xtime_l.h"
#include "xil_cache.h"


int main_thread();
void print_echo_app_header();
void open_connection(void *);

void lwip_init();
#if LWIP_IPV6==0
#if LWIP_DHCP==1
extern volatile int dhcp_timoutcntr;
err_t dhcp_start(struct netif *netif);
#endif
#endif

#define THREAD_STACKSIZE 1024

static struct netif server_netif;
struct netif *echo_netif;

extern uint8_t connection_disconnected;

struct no_os_spi_desc *spi_eng_desc;
struct spi_engine_offload_message spi_engine_offload_message;
struct spi_engine_offload_init_param spi_engine_offload_init_param;




// Buffer Definitions
//aligned_buffers buffers[NUM_BUFFERS];
//uint32_t buffer_store[BUFFER_STORE_SIZE] __attribute__((aligned(1024))) = {0};
uint32_t *dma_buf = (uint32_t *)(CN0561_DDR_BASEADDR + DMA_BUFFER_OFFSET);
uint32_t transfer_id;
uint32_t timeout_cnt;


volatile uint8_t buffer_idx = 0; // For buffer iterator
volatile uint8_t buffer_store_idx = 0;
//uint32_t adc_buffer_len = VALID_BYTES;

uint32_t i = 0, j;
int32_t ret;
const float lsb = 4.096 / (pow(2, 23));
float data;

static inline void dmac_write(uint32_t off, uint32_t val)
{
	Xil_Out32(CN0561_DMA_BASEADDR + off, val);
}

static inline uint32_t dmac_read(uint32_t off)
{
	return Xil_In32(CN0561_DMA_BASEADDR + off);
}

static inline int32_t sign_extend_24(uint32_t word)
{
	uint32_t raw = word & 0x00FFFFFFU;

	if (raw & 0x00800000U)
		raw |= 0xFF000000U;

	return (int32_t)raw;
}




int fill_buffer() {

#if BUFFER_MODE == 0
	buffer_idx = 0;
	//spi_engine_offload_message.rx_addr = buffers[buffer_idx].data;
	//spi_engine_offload_message.rx_addr = (uint32_t)adc_buffers[buffer_idx];
	//ret = spi_engine_offload_transfer(spi_eng_desc, spi_engine_offload_message,
	//	        					  (AD4134_FMC_CH_NO * AD4134_FMC_SAMPLE_NO));
	//	if (ret != 0) {
	//return ret;
	//	}
	/* Capture the transfer ID that will be assigned to this submission */
	transfer_id = dmac_read(AXI_DMAC_REG_TRANSFER_ID) & 0x3;

	/* Configure and submit */
	dmac_write(AXI_DMAC_REG_DEST_ADDRESS, (uint32_t)(uintptr_t)dma_buf);
	dmac_write(AXI_DMAC_REG_X_LENGTH, DMA_TRANSFER_BYTES - 1);
	dmac_write(AXI_DMAC_REG_TRANSFER_SUBMIT, AXI_DMAC_TRANSFER_SUBMIT);

	/* Poll for completion of this specific transfer */
	timeout_cnt = 0;
	while (!(dmac_read(AXI_DMAC_REG_TRANSFER_DONE) & (1u << transfer_id))) {
		no_os_mdelay(1);
		if (++timeout_cnt >= DMA_TIMEOUT_MS) {
			print("ERROR: DMA timeout\n\r");
			return -1;
		}
	}

	/* Invalidate cache so CPU reads DMA-written data from DDR */
	Xil_DCacheInvalidateRange((INTPTR)dma_buf, DMA_TRANSFER_BYTES);

	/*printf("%d, %+ld %+ld %+ld %+ld\n\r", CN0561_FMC_SAMPLE_NO,
			       (long)(sign_extend_24(dma_buf[0]) * 125 / 256),
			       (long)(sign_extend_24(dma_buf[1]) * 125 / 256),
			       (long)(sign_extend_24(dma_buf[2]) * 125 / 256),
			       (long)(sign_extend_24(dma_buf[3]) * 125 / 256));*/
	/*printf("%d, %+d %+d %+d %+d\n\r", CN0561_FMC_SAMPLE_NO,
				       dma_buf[0],
					   dma_buf[1],
					   dma_buf[2],
					   dma_buf[3]);*/
/*#else
	#if TRANSFER_MODE == 0
	for (buffer_idx = 0; buffer_idx < NUM_BUFFERS; buffer_idx++) {
			uint32_t start_index = buffer_store_idx * (AD4134_FMC_CH_NO * AD4134_FMC_SAMPLE_NO);
			//printf("Start Index: %d\r\n", start_index);
			spi_engine_offload_message.rx_addr = &buffer_store[start_index];
			XTime time_start, time_end;
			XTime_GetTime(&time_start);
			ret = spi_engine_offload_transfer(spi_eng_desc, spi_engine_offload_message,
											  (AD4134_FMC_CH_NO * AD4134_FMC_SAMPLE_NO));
			XTime_GetTime(&time_end);
			printf("Offload Time: %lf s\r\n", ((double)(time_end - time_start) / (double)COUNTS_PER_SECOND));

			if (ret != 0) {
				printf("Error\r\n");
				return ret;
			}

			Xil_DCacheInvalidateRange((INTPTR)&buffer_store[start_index], SAMPLE_DATA * sizeof(uint32_t));
			buffer_store_idx += 1;
			//printf("Buffer Store Index: %d\r\n", buffer_store_idx);
		}
	#else
	for (buffer_idx = 0; buffer_idx < NUM_BUFFERS; buffer_idx++) {
		spi_engine_offload_message.rx_addr = buffers[buffer_idx].data;

		ret = spi_engine_offload_transfer(spi_eng_desc, spi_engine_offload_message,
			        					  (AD4134_FMC_CH_NO * AD4134_FMC_SAMPLE_NO));
		if (ret != 0) {
			return ret;
		}
	}
	#endif*/
#endif
	return 0;
}


int main()
{
		struct ad713x_dev *cn0561_dev;
		struct ad713x_init_param cn0561_init_param = {0};
		uint32_t adc_channel;
		int32_t ret;

		static struct xil_spi_init_param spi_ps_init_params = {
			.type = SPI_PS,
		};
		struct xil_gpio_init_param gpio_ps_param;
		struct no_os_gpio_init_param cn0561_pnd = {
			.number = GPIO_PDN,
			.platform_ops = &xil_gpio_ops,
			.extra = &gpio_ps_param
		};
		struct no_os_gpio_init_param cn0561_mode = {
			.number = GPIO_MODE,
			.platform_ops = &xil_gpio_ops,
			.extra = &gpio_ps_param
		};
		struct no_os_gpio_init_param cn0561_resetn = {
			.number = GPIO_RESETN,
			.platform_ops = &xil_gpio_ops,
			.extra = &gpio_ps_param
		};

		gpio_ps_param.device_id = GPIO_DEVICE_ID;
		gpio_ps_param.type = GPIO_PS;

		cn0561_init_param.adc_data_len = ADC_24_BIT_DATA;
		cn0561_init_param.clk_delay_en = false;
		cn0561_init_param.crc_header = CRC_6;
		cn0561_init_param.dev_id = ID_AD4134;
		cn0561_init_param.format = QUAD_CH_PO;
		cn0561_init_param.gpio_dclkio = NULL;
		cn0561_init_param.gpio_dclkmode = NULL;
		cn0561_init_param.gpio_cs_sync = NULL;
		cn0561_init_param.gpio_pnd = &cn0561_pnd;
		cn0561_init_param.gpio_mode = &cn0561_mode;
		cn0561_init_param.gpio_resetn = &cn0561_resetn;
		cn0561_init_param.mode_master_nslave = false;
		cn0561_init_param.dclkmode_free_ngated = false;
		cn0561_init_param.dclkio_out_nin = false;
		cn0561_init_param.pnd = true;
		cn0561_init_param.spi_init_prm.chip_select = CN0561_SPI_CS;
		cn0561_init_param.spi_init_prm.device_id = SPI_DEVICE_ID;
		cn0561_init_param.spi_init_prm.max_speed_hz = 10000000;
		cn0561_init_param.spi_init_prm.mode = NO_OS_SPI_MODE_0;
		cn0561_init_param.spi_init_prm.platform_ops = &xil_spi_ops;
		cn0561_init_param.spi_init_prm.extra = (void *)&spi_ps_init_params;
		cn0561_init_param.spi_common_dev = 0;

		Xil_ICacheEnable();
		Xil_DCacheEnable();

		print("Initializing AD4134...\n\r");
		printf("  SPI device ID: %d, CS: %d\n\r", SPI_DEVICE_ID, CN0561_SPI_CS);
		printf("  GPIO device ID: %d\n\r", GPIO_DEVICE_ID);
		printf("  GPIO RESETN: %d, PDN: %d, MODE: %d\n\r", GPIO_RESETN, GPIO_PDN, GPIO_MODE);
		print("  Calling ad713x_init()...\n\r");
		ret = ad713x_init(&cn0561_dev, &cn0561_init_param);
		if (ret != 0) {
			printf("ERROR: ad713x_init failed with code %ld!\n\r", (long)ret);
			return -1;
		}
		print("  ad713x_init() succeeded\n\r");

		for (adc_channel = CH0; adc_channel <= CH3; adc_channel++) {
			ret = ad713x_dig_filter_sel_ch(cn0561_dev, SINC3, adc_channel);
			if (ret != 0)
				return -1;
		}

		no_os_mdelay(1000);

		ret = ad713x_spi_reg_write(cn0561_dev, AD713X_REG_GPIO_DIR_CTRL, 0xE7);
		if (ret != 0)
			return -1;
		ret = ad713x_spi_reg_write(cn0561_dev, AD713X_REG_GPIO_DATA, 0x84);
		if (ret != 0)
			return -1;
		ad713x_spi_reg_dump(cn0561_dev);
		/* Check DMA base address */
		if (CN0561_DMA_BASEADDR == 0) {
			print("ERROR: DMA base address not found in xparameters.h\n\r");
			print("Make sure FPGA bitstream matches this software\n\r");
			return -1;
		}
		printf("DMA base: 0x%08lx, DDR base: 0x%08lx\n\r",
		       (unsigned long)CN0561_DMA_BASEADDR,
		       (unsigned long)CN0561_DDR_BASEADDR);

		/* Clear buffer and flush so DDR is clean for first DMA write */
		memset(dma_buf, 0, DMA_TRANSFER_BYTES);
		Xil_DCacheFlushRange((INTPTR)dma_buf, DMA_TRANSFER_BYTES);

		/* Enable DMAC */
		dmac_write(AXI_DMAC_REG_CTRL, AXI_DMAC_CTRL_ENABLE);
		no_os_mdelay(1);



	sys_thread_new("main_thrd", (void(*)(void*))main_thread, 0,
	                THREAD_STACKSIZE,
	                DEFAULT_THREAD_PRIO);
	vTaskStartScheduler();
	while(1);
	Xil_DCacheDisable();
	Xil_ICacheDisable();
	return 0;
}

void network_thread(void *p)
{
    struct netif *netif;
    unsigned char mac_ethernet_address[] = { 0x00, 0x0a, 0x35, 0x00, 0x01, 0x02 };
#if LWIP_IPV6==0
    ip_addr_t ipaddr, netmask, gw;
#if LWIP_DHCP==1
    int mscnt = 0;
#endif
#endif

    netif = &server_netif;

    xil_printf("\r\n\r\n");
    xil_printf("----- lwIP TCP Send-Once Server ------\r\n");

#if LWIP_DHCP==0
    IP4_ADDR(&ipaddr,  192, 168, 0, 10);
    IP4_ADDR(&netmask, 255, 255, 255,  0);
    IP4_ADDR(&gw,      192, 168, 0, 1);
    print_ip_settings(&ipaddr, &netmask, &gw);
#endif

#if LWIP_DHCP==1
	ipaddr.addr = 0;
	gw.addr = 0;
	netmask.addr = 0;
#endif

    if (!xemac_add(netif, &ipaddr, &netmask, &gw, mac_ethernet_address, PLATFORM_EMAC_BASEADDR)) {
		xil_printf("Error adding N/W interface\r\n");
		return;
    }

    netif_set_default(netif);
    netif_set_up(netif);

    sys_thread_new("xemacif_input_thread", (void(*)(void*))xemacif_input_thread, netif,
            THREAD_STACKSIZE, DEFAULT_THREAD_PRIO);

#if LWIP_DHCP==1
    dhcp_start(netif);
    while (1) {
		vTaskDelay(DHCP_FINE_TIMER_MSECS / portTICK_RATE_MS);
		dhcp_fine_tmr();
		mscnt += DHCP_FINE_TIMER_MSECS;
		if (mscnt >= DHCP_COARSE_TIMER_SECS*1000) {
			dhcp_coarse_tmr();
			mscnt = 0;
		}
	}
#else
//fill_buffer();

    xil_printf("\r\n");
    sys_thread_new("echod", open_connection, 0,
		THREAD_STACKSIZE, DEFAULT_THREAD_PRIO);
    vTaskDelete(NULL);
#endif
    return;
}

int main_thread()
{
#if LWIP_DHCP==1
	int mscnt = 0;
#endif

	lwip_init();


	sys_thread_new("NW_THRD", network_thread, NULL,
		THREAD_STACKSIZE, DEFAULT_THREAD_PRIO);

#if LWIP_DHCP==1
    while (1) {
		vTaskDelay(DHCP_FINE_TIMER_MSECS / portTICK_RATE_MS);
		if (server_netif.ip_addr.addr) {
			xil_printf("DHCP request success\r\n");
			print_ip_settings(&(server_netif.ip_addr), &(server_netif.netmask), &(server_netif.gw));
			fill_buffer();
			print_echo_app_header();
			xil_printf("\r\n");
			sys_thread_new("echod", open_connection, 0,
					THREAD_STACKSIZE, DEFAULT_THREAD_PRIO);
			break;
		}
		mscnt += DHCP_FINE_TIMER_MSECS;
		if (mscnt >= DHCP_COARSE_TIMER_SECS * 2000) {
			xil_printf("ERROR: DHCP request timed out\r\n");
			xil_printf("Configuring default IP of 192.168.1.10\r\n");
			IP4_ADDR(&(server_netif.ip_addr),  192, 168, 1, 10);
			IP4_ADDR(&(server_netif.netmask), 255, 255, 255,  0);
			IP4_ADDR(&(server_netif.gw),  192, 168, 1, 1);
			print_ip_settings(&(server_netif.ip_addr), &(server_netif.netmask), &(server_netif.gw));
			fill_buffer();
			print_echo_app_header();
			xil_printf("\r\n");
			sys_thread_new("echod", open_connection, 0,
					THREAD_STACKSIZE, DEFAULT_THREAD_PRIO);
			break;
		}
	}
#endif
    vTaskDelete(NULL);
    return 0;
}

void print_ip(char *msg, ip_addr_t *ip)
{
	xil_printf(msg);
	xil_printf("%d.%d.%d.%d\n\r", ip4_addr1(ip), ip4_addr2(ip),
			ip4_addr3(ip), ip4_addr4(ip));
}

void print_ip_settings(ip_addr_t *ip, ip_addr_t *mask, ip_addr_t *gw)
{
	print_ip("Board IP: ", ip);
	print_ip("Netmask : ", mask);
	print_ip("Gateway : ", gw);
}
