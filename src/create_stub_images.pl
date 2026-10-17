#!/usr/bin/perl -w
#
#indx#	create_stub_images.pl - Create jpeg files containing descriptions of what they will be replaced with
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
#doc#	Create jpeg files containing descriptions of what they will be replaced with
########################################################################

use strict;

use lib "/usr/local/lib/perl";
use cpi_file qw( fatal read_lines write_file cleanup );
use cpi_arguments qw( parse_arguments );
use cpi_vars;

our @problems;
our $exit_status = 0;

sub usage
    {
    fatal( @_, "Usage: $cpi_vars::PROG <arguments>",
        "where <arguments> are one zero or more:",
	"-input_file <source xml file>",
	"-output_directory <place to put jpg files>",
	"-verbosity 0|1",
	"-overwrite (will overwrite .jpg files if they already exist)",
	"-text_to_jpeg <program to convert text to jpeg>" );
    }

my %ARGS = &parse_arguments({
    flags			=> [ "-overwrite" ],
    switches =>
    	{
	"input_file"		=> "/dev/stdin",
	"output_directory"	=> ".",
	"verbosity"		=> 0,
	"text_to_jpeg"		=> "nene"
	}
    });

foreach $_ ( &read_lines( $ARGS{input_file} ) )
    {
    my $jpg;
    if( /src='(.*?)'/ )
	{ $jpg=$1; }
    if( /contains="(.*?)"/ )
	{
	my $contains=$1;
	if( -s $jpg && ! $ARGS{overwrite} )
	    {
	    print STDERR "$jpg skipped.\n" if( $ARGS{verbosity} > 1 );
	    }
	else
	    {
	    my $cmd = "| fmt -40 | $ARGS{text_to_jpeg} -.txt $jpg";
	    print STDERR "+ ", $cmd, "\n" if( $ARGS{verbosity} );
	    &write_file( $cmd, $contains, "\n" );
	    print "$jpg created.\n";
	    }
	}
    }

&cleanup( $exit_status );
