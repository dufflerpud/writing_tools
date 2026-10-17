#!/bin/sh
#
#indx#	setup_writing.sh - Add stuff to current directory to attach it to writing tools
#@HDR@	$Id$
#@HDR@
#@HDR@	Copyright (c) 2026 Christopher Caldwell (Christopher.M.Caldwell0@gmail.com)
#@HDR@
#@HDR@	Permission is hereby granted, free of charge, to any person
#@HDR@	obtaining a copy of this software and associated documentation
#@HDR@	files (the "Software"), to deal in the Software without
#@HDR@	restriction, including without limitation the rights to use,
#@HDR@	copy, modify, merge, publish, distribute, sublicense, and/or
#@HDR@	sell copies of the Software, and to permit persons to whom
#@HDR@	the Software is furnished to do so, subject to the following
#@HDR@	conditions:
#@HDR@	
#@HDR@	The above copyright notice and this permission notice shall be
#@HDR@	included in all copies or substantial portions of the Software.
#@HDR@	
#@HDR@	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
#@HDR@	KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
#@HDR@	WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
#@HDR@	AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
#@HDR@	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
#@HDR@	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#@HDR@	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#@HDR@	OTHER DEALINGS IN THE SOFTWARE.
#
#hist#	2026-10-16 - Christopher.M.Caldwell0@gmail.com - Created header
########################################################################
#doc#	Add stuff to current directory to attach it to writing tools
########################################################################

MUST_BE_EXECUTABLE="index.cgi"
MUST_BE_READABLE="characters.xml Makefile"

[ -h writing ] || ln -s ../writing
[ -h Makefile ] || ln -s writing/Makefiles/Makefile.simple Makefile
mkdir -p build published
touch index.ok
ls -l
for fn in $MUST_BE_EXECUTABLE ; do
    [ -x $fn ] || echo "$fn must exist and be executable."
done
for fn in $MUST_BE_READABLE ; do
    [ -r $fn ] || echo "$fn must be readable."
done
