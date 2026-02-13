/***************************************************************************//**
 *   @file   parameters.h
 *   @brief  Parameters Definitions.
 *   @author Mihail Chindris (mihail.chindris@analog.com)
********************************************************************************
 * Copyright 2021(c) Analog Devices, Inc.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY ANALOG DEVICES, INC. "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ANALOG DEVICES, INC. BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*******************************************************************************/
#ifndef __PARAMETERS_H__
#define __PARAMETERS_H__

#include <xparameters.h>

#if defined(XPAR_XSPIPS_0_DEVICE_ID)
#define SPI_DEVICE_ID			XPAR_XSPIPS_0_DEVICE_ID
#elif defined(XPAR_PS7_SPI_0_DEVICE_ID)
#define SPI_DEVICE_ID			XPAR_PS7_SPI_0_DEVICE_ID
#else
#define SPI_DEVICE_ID			0
#endif

#if defined(XPAR_XGPIOPS_0_DEVICE_ID)
#define GPIO_DEVICE_ID			XPAR_XGPIOPS_0_DEVICE_ID
#elif defined(XPAR_PS7_GPIO_0_DEVICE_ID)
#define GPIO_DEVICE_ID			XPAR_PS7_GPIO_0_DEVICE_ID
#else
#define GPIO_DEVICE_ID			0
#endif
#define CN0561_SPI_CS			0

/* AXI DMAC (stream to DDR) */
#ifdef XPAR_AXI_AD4134_DMA_BASEADDR
#define CN0561_DMA_BASEADDR		XPAR_AXI_AD4134_DMA_BASEADDR
#else
#define CN0561_DMA_BASEADDR		0
#endif

/* DDR base address */
#ifdef XPAR_DDR_MEM_BASEADDR
#define CN0561_DDR_BASEADDR		XPAR_DDR_MEM_BASEADDR
#elif defined(XPAR_PSU_DDR_0_S_AXI_BASEADDR)
#define CN0561_DDR_BASEADDR		XPAR_PSU_DDR_0_S_AXI_BASEADDR
#elif defined(XPAR_PS7_DDR_0_S_AXI_BASEADDR)
#define CN0561_DDR_BASEADDR		XPAR_PS7_DDR_0_S_AXI_BASEADDR
#else
#define CN0561_DDR_BASEADDR		0x00000000U
#endif

/* DMA configuration for tq15eg_data DMAC design */
#define DMA_WORDS_PER_SAMPLE    4u//16u//4u      /* 128-bit AXIS beat = 4x32-bit */
#define DMA_BYTES_PER_SAMPLE    16u//64u//16u
#define DMA_BUFFER_OFFSET       0x01000000u  /* Offset from DDR base */
#ifdef PLATFORM_ZYNQMP
#define GPIO_OFFSET				78
#else
#define GPIO_OFFSET				54
#endif
#define GPIO_RESETN			GPIO_OFFSET + 32
#define GPIO_PDN			GPIO_OFFSET + 33
#define GPIO_MODE			GPIO_OFFSET + 34
#define GPIO_PINBSPI		GPIO_OFFSET + 35
#define GPIO_0				GPIO_OFFSET + 36
#define GPIO_1				GPIO_OFFSET + 37
#define GPIO_2				GPIO_OFFSET + 38
#define GPIO_4				GPIO_OFFSET + 39
#define GPIO_5				GPIO_OFFSET + 40
#define GPIO_6				GPIO_OFFSET + 41
#define GPIO_7				GPIO_OFFSET + 42
#define CN0561_FMC_CH_NO		1
#define CN0561_FMC_SAMPLE_NO	512

#define AD7134_1_SPI_CS			0
#define AD7134_2_SPI_CS			1
#define GPIO_RESETN_1			GPIO_OFFSET + 32
#define GPIO_RESETN_2			GPIO_OFFSET + 33
#define GPIO_PDN_1			GPIO_OFFSET + 34
#define GPIO_PDN_2			GPIO_OFFSET + 35
#define GPIO_MODE_1			GPIO_OFFSET + 36
#define GPIO_MODE_2			GPIO_OFFSET + 37
#define GPIO_0				GPIO_OFFSET + 38
#define GPIO_1				GPIO_OFFSET + 39
#define GPIO_2				GPIO_OFFSET + 40
#define GPIO_3				GPIO_OFFSET + 41
#define GPIO_4				GPIO_OFFSET + 42
#define GPIO_5				GPIO_OFFSET + 43
#define GPIO_6				GPIO_OFFSET + 44
#define GPIO_7				GPIO_OFFSET + 45
#define GPIO_DCLKIO_1			GPIO_OFFSET + 46
#define GPIO_DCLKIO_2			GPIO_OFFSET + 47
#define GPIO_PINBSPI			GPIO_OFFSET + 48
#define GPIO_DCLKMODE			GPIO_OFFSET + 49
#define GPIO_CS_SYNC			GPIO_OFFSET + 50
#define GPIO_CS_SYNC_1			GPIO_OFFSET + 51

#define ADC_BUFFER_SIZE			CN0561_FMC_SAMPLE_NO

/* Continuous streaming: one line printed per DMA transfer.
 * Print rate = ~161k samples/sec / CN0561_FMC_SAMPLE_NO
 * At 512 samples: ~315 prints/sec; each print ~25 chars = 2.2 ms at 115200 baud.
 * Do not reduce below ~700 or UART becomes the bottleneck. */
#define DMA_TIMEOUT_MS			5000u

//#define CN0561_CORAZ7S_CARRIER
//#define CN0561_ZED_CARRIER
//#define CN0561_REG_DUMP

/* AXI DMAC registers */
/*#define AXI_DMAC_REG_CTRL             0x400
#define AXI_DMAC_CTRL_ENABLE          0x1
#define AXI_DMAC_REG_TRANSFER_ID      0x404
#define AXI_DMAC_REG_TRANSFER_SUBMIT  0x408
#define AXI_DMAC_TRANSFER_SUBMIT      0x1
#define AXI_DMAC_REG_FLAGS            0x40C
#define AXI_DMAC_REG_DEST_ADDRESS     0x410
#define AXI_DMAC_REG_X_LENGTH         0x418
#define AXI_DMAC_REG_Y_LENGTH         0x41c
#define AXI_DMAC_REG_DEST_STRIDE      0x420
#define AXI_DMAC_REG_TRANSFER_DONE    0x428
#define AXI_DMAC_REG_ACTIVE_ID        0x42C
#define AXI_DMAC_REG_STATUS           0x430
#define AXI_DMAC_REG_CURRENT_DEST     0x434*/

#define DMA_TRANSFER_BYTES  (CN0561_FMC_SAMPLE_NO * DMA_BYTES_PER_SAMPLE)


#ifdef IIO_SUPPORT
#define UART_BAUDRATE			115200
#define UART_DEVICE_ID			XPAR_XUARTPS_0_DEVICE_ID
#define UART_IRQ_ID				XPAR_XUARTPS_0_INTR
#define INTC_DEVICE_ID			XPAR_SCUGIC_SINGLE_DEVICE_ID
#endif // IIO_SUPPORT

#endif /* __PARAMETERS_H__ */
