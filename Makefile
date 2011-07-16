#  Master makefile
#
# Copyright (C) 2010-2011  Hector Martin "marcan" <hector@marcansoft.com>
#
# This code is licensed to you under the terms of the GNU GPL, version 2;
# see file COPYING or http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt

all:
	$(MAKE) -C stage1
	$(MAKE) -C stage2
	$(MAKE) -C tools

clean:
	$(MAKE) -C stage1 clean
	$(MAKE) -C stage2 clean
	$(MAKE) -C tools clean

