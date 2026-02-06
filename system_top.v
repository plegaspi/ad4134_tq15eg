// ***************************************************************************
// ***************************************************************************
// Copyright (C) 2023 Analog Devices, Inc. All rights reserved.
// Modified for custom data capture (replacing SPI Engine)
//
// In this HDL repository, there are many different and unique modules, consisting
// of various HDL (Verilog or VHDL) components. The individual modules are
// developed independently, and may be accompanied by separate and unique license
// terms.
//
// The user should read each of these license terms, and understand the
// freedoms and responsibilities that he or she has by using this source/core.
//
// This core is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE.
//
// Redistribution and use of source or resulting binaries, with or without modification
// of this file, are permitted under one of the following two license terms:
//
//   1. The GNU General Public License version 2 as published by the
//      Free Software Foundation, which can be found in the top level directory
//      of this repository (LICENSE_GPL2), and also online at:
//      <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>
//
// OR
//
//   2. An ADI specific BSD license, which can be found in the top level directory
//      of this repository (LICENSE_ADIBSD), and also on-line at:
//      https://github.com/analogdevicesinc/hdl/blob/main/LICENSE_ADIBSD
//      This will allow to generate bit files and not release the source code,
//      as long as it attaches to an ADI device.
//
// ***************************************************************************
// ***************************************************************************

`timescale 1ns/100ps

module system_top (

  // ad4134 SPI configuration interface (directly from PS SPI0 EMIO)
  input           ad4134_spi_sdi,
  output          ad4134_spi_sdo,
  output          ad4134_spi_sclk,
  output          ad4134_spi_cs,

  // ad4134 data interface (directly from custom data capture module)
  output          ad4134_dclk,
  input           ad4134_din0,
  input           ad4134_din1,
  input           ad4134_din2,
  input           ad4134_din3,
  output          ad4134_odr,

  // ad4134 GPIO lines
  inout           ad4134_resetn,
  inout           ad4134_pdn,
  inout           ad4134_mode,
  inout           ad4134_pinbspi,
  inout           ad4134_gpio0,
  inout           ad4134_gpio1,
  inout           ad4134_gpio2,
  inout           ad4134_gpio3,
  inout           ad4134_gpio4,
  inout           ad4134_gpio5,
  inout           ad4134_gpio6,
  inout           ad4134_gpio7,
  inout           ad4134_dclk_mode,
  inout           ad4134_dclkio
);

  // internal signals
  wire    [94:0]  gpio_i;
  wire    [94:0]  gpio_o;
  wire    [94:0]  gpio_t;

  // instantiations

  assign gpio_i[94:46] = gpio_o[94:46];

  ad_iobuf #(
    .DATA_WIDTH(14)
  ) i_iobuf_ad4134_gpio (
    .dio_t(gpio_t[45:32]),
    .dio_i(gpio_o[45:32]),
    .dio_o(gpio_i[45:32]),
    .dio_p({ad4134_dclkio,      // [45]
            ad4134_dclk_mode,   // [44]
            ad4134_gpio7,       // [43]
            ad4134_gpio6,       // [42]
            ad4134_gpio5,       // [41]
            ad4134_gpio4,       // [40]
            ad4134_gpio3,       // [39]
            ad4134_gpio2,       // [38]
            ad4134_gpio1,       // [37]
            ad4134_gpio0,       // [36]
            ad4134_pinbspi,     // [35]
            ad4134_mode,        // [34]
            ad4134_pdn,         // [33]
            ad4134_resetn}));   // [32]

  ad_iobuf #(
    .DATA_WIDTH(32)
  ) i_iobuf (
    .dio_t(gpio_t[31:0]),
    .dio_i(gpio_o[31:0]),
    .dio_o(gpio_i[31:0]));


  system_wrapper i_system_wrapper (
    // GPIO
    .gpio_i (gpio_i),
    .gpio_o (gpio_o),
    .gpio_t (gpio_t),

    // PS SPI0 EMIO for AD4134 configuration interface
    // Clock loopback at top level (ADI pattern)
    .spi0_clk_i (ad4134_spi_sclk),
    .spi0_clk_o (ad4134_spi_sclk),
    .spi0_csn_0_o (ad4134_spi_cs),
    .spi0_csn_1_o (),
    .spi0_csn_2_o (),
    .spi0_csn_i (1'b1),
    .spi0_sdi_i (ad4134_spi_sdi),
    .spi0_sdo_o (ad4134_spi_sdo),
    .spi0_sdo_i (1'b0),

    // Custom data capture interface (directly exposed from block design)
    .ad4134_din0 (ad4134_din0),
    .ad4134_din1 (ad4134_din1),
    .ad4134_din2 (ad4134_din2),
    .ad4134_din3 (ad4134_din3),
    .ad4134_dclk (ad4134_dclk),
    .ad4134_odr (ad4134_odr)

    // ILA probes
    //.probe0_signal (ad4134_odr),
    //.probe1_signal (ad4134_din)
  );

endmodule


