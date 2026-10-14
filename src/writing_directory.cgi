#!/usr/bin/perl -w
#
#indx#	writing_directory.cgi - Show directory of writing included in this directory
#@HDR@	$Id$
#@HDR@
#@HDR@	Copyright (c) 2024-2026 Christopher Caldwell (Christopher.M.Caldwell0@gmail.com)
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
#hist#	2026-10-14 - Christopher.M.Caldwell0@gmail.com - Created header
########################################################################
#doc#	Show directory of writing included in this directory
########################################################################

use strict;

close( STDERR );
open(STDERR,">>/var/log/stderr/writing") || die("Cannot redirect stderr:  $!");
print "Content-type:  text/html\n\n<html><head></head><body><center><table>\n";

use lib "/usr/local/lib/perl";
use cpi_file qw( read_file fatal files_in );

my $TOP = ".";

foreach my $dir ( &files_in( $TOP, "^[a-zA-Z0-9]" ) )
    {
    my $full_dir = "$TOP/$dir";			next if( -l $full_dir );
    my $filename = "$full_dir/index.cgi";	next if( ! -e $filename );
    print
	"<tr>",
	"<th align=left><a href='$dir/index.cgi'>$dir</a></th>",
	"<td>$1</td>",
	"</tr>\n"
	if( &read_file( $filename ) =~ m:bin/story_xml.*?name="(.*?)":ms );
    }
print "</table></center></body></html>\n";
exit( 0 );
