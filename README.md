# RV6699_firmware_utils
Utilities for managing Sercomm RV6699 firmware images

## Contents
modified https://github.com/Psychotropos/sercomm_fwutils

Broadcom-compatible mkfs.jffs2

makefile for automatization

## Usage:
`make extract STOCK_IMG=/path/to/stock/firmware.img` — unpack stock firmware

`make patch` — replace files in stock with replace contents

`make build` — build new firmware

`make clean` — clean everything
