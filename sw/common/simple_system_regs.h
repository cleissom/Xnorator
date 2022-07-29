// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifndef SIMPLE_SYSTEM_REGS_H__
#define SIMPLE_SYSTEM_REGS_H__

#define SIM_CTRL_BASE 0x20000
#define SIM_CTRL_OUT 0x0
#define SIM_CTRL_CTRL 0x8

#define XNORATOR_BASE 0x40000
#define XNORATOR_INPUT_ADDR 0x00
#define XNORATOR_WEIGHT_ADDR 0x04
#define XNORATOR_OUTPUT_ADDR 0x08
#define XNORATOR_INPUT_WIDTH 0x0C
#define XNORATOR_INPUT_HEIGHT 0x10
#define XNORATOR_INPUT_CHANNEL 0x14
#define XNORATOR_OUPUT_CHANNEL 0x18
#define XNORATOR_PADDING 0x1C
#define XNORATOR_START 0x20
#define XNORATOR_DONE 0x24

#endif // SIMPLE_SYSTEM_REGS_H__
