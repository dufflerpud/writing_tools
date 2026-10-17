#!/usr/bin/perl -w
#
#indx#	refmt_xml.pl - Redo spacing of XML file to make it easier to edit
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
#doc#	Redo spacing of XML file to make it easier to edit
########################################################################

use strict;

use lib "/usr/local/lib/perl";
use cpi_file qw( fatal read_lines write_file cleanup );
use cpi_arguments qw( parse_arguments );
use cpi_vars;

our @problems;
our $exit_status = 0;

my $COLS = 75;
my $indent;
my $bld_ln;
my @out_lines;

#########################################################################
#	Print a usage message and exit.					#
#########################################################################
sub usage
    {
    fatal( @_, "Usage: $cpi_vars::PROG <arguments>",
        "where <arguments> are one zero or more:",
	"-input_file <source xml file>",
	"-verbosity 0|1",
	"-overwrite (will overwrite .jpg files if they already exist)",
	"-text_to_jpeg <program to convert text to jpeg>" );
    }

#########################################################################
#	Dump string built up in $bld_ln and print it out as if it had	#
#	run through fmt, but honoring spacing over in $indent.		#
#########################################################################
sub dump_so_far
    {
    return if( ! defined( $bld_ln ) );

    $indent =~ s/\t/        /g;
    my $spaceout = length( $indent );

    my $pos = 10000;
    my $need_cr = "";
    foreach my $tok ( split(/\s/,$bld_ln) )
        {
	my $l = length($tok);
	if( ($pos + $l) > $COLS )
	    {
	    push( @out_lines,  $need_cr, $indent, $tok );
	    $need_cr = "\n";
	    $pos = $spaceout + $l;
	    }
	else
	    {
	    push( @out_lines, " ", $tok );
	    $pos += (1 + $l);
	    }
	}
    push( @out_lines, $need_cr );
    undef $bld_ln;
    }

#########################################################################
#	Main								#
#########################################################################

my %ARGS = &parse_arguments({
    flags			=> [ "-overwrite" ],
    switches =>
    	{
	"input_file"		=> "/dev/stdin",
	"verbosity"		=> 0,
	}
    });

my $ln;
my @in_lines = &read_lines( $ARGS{input_file} );
while( defined($ln = shift(@out_lines) ) )
    {
    if( $ln =~ /^\s*</ || $ln =~ /^\s*$/ )
        {
	&dump_so_far();
	push( @out_lines, $ln, "\n" );
	if( $ln =~ /</ && $ln !~ />\s*$/ )
	    {
	    while( defined($ln = shift(@in_lines) ) )
	        {
		push( @out_lines, $ln, "\n" );
		last if( $ln =~ />/ );
		}
	    }
	}
    elsif( $ln =~ /^(\s*)([^\s].*)/ )
        {
	if( defined($bld_ln) )
	    { $bld_ln .= " " . $2; }
	else
	    { $bld_ln = $2; }
	$indent = $1;
	}
    else
        {
	print STDERR "No idea what to do with [$ln].\n";
	}
    }
&dump_so_far();
&write_file( $ARGS{output_file}, @out_lines );
&cleanup( $exit_status );
