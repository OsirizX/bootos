/*  repo.h - convenience macros and defines for lv1 repo

Copyright (C) 2010-2011  Hector Martin "marcan" <hector@marcansoft.com>

This code is licensed to you under the terms of the GNU GPL, version 2;
see file COPYING or http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt
*/

#ifndef REPO_H
#define REPO_H

#include "types.h"


#define _PS(s) (s "\0\0\0\0\0\0\0\0")
#define S2I(s) ( \
	(((u64)_PS(s)[0])<<56) | \
	(((u64)_PS(s)[1])<<48) | \
	(((u64)_PS(s)[2])<<40) | \
	(((u64)_PS(s)[3])<<32) | \
	(((u64)_PS(s)[4])<<24) | \
	(((u64)_PS(s)[5])<<16) | \
	(((u64)_PS(s)[6])<<8) | \
	(((u64)_PS(s)[7])<<0))

#define PS3_LPAR_ID_PME 1

#define FIELD_FIRST(s, i) ((S2I(s)>>32) + (i))
#define FIELD(s, i) (S2I(s) + (i))

static inline s32 set_repository_node(u64 n1, u64 n2, u64 n3, u64 n4,
										u64 v1, u64 v2)
{
	s32 result;

	result = lv1_create_repository_node(n1, n2, n3, n4, v1, v2);

	if (result)
		return result;

	return lv1_write_repository_node(n1, n2, n3, n4, v1, v2);
}

#endif
