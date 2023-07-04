#  ppu.mak - Common PPU makefile definitions
#
# Copyright (C) 2010-2011  Hector Martin "marcan" <hector@marcansoft.com>
#
# This code is licensed to you under the terms of the GNU GPL, version 2;
# see file COPYING or http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt

PREFIX=ppu-
# $(PS3DEV)/bin/powerpc64-linux-

CFLAGS=-ffreestanding -mbig-endian -m64
LDFLAGS=-nostartfiles -nostdlib -mbig-endian

export PREFIX
export CFLAGS

