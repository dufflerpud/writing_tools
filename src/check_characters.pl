#!/usr/bin/perl -w
#
#indx#	check_characters.pl - Check a characters file for syntax
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
#doc#	Check a characters file for syntax.
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
	"-verbosity 0|1" );
    }

my %ARGS = &parse_arguments({
    switches =>
    	{
	"input_file"		=> "/dev/stdin",
	"verbosity"		=> 0,
	}
    });

my %varvals;

foreach my $pc ( split(/(<[^<]*)/,&read_file( $ARGS{input_file} )) )
    {
    if( $pc !~ m:^<(.*)/>\s*$:ms )
        {
	print STDERR "Ignoring=[$pc]\n" if( $ARGS{verbosity} );
	next;
	}
    else
        {
	my $triad = $1;
	#print "Triad was [$triad]\n";
        if( $triad eq "cleardefs" )
	    {
	    %varvals = ();
	    next;
	    }

	if( $triad !~ m:^\s*setvar\s+name="(.*)"\s+modifier="(.*)"\s+value="(.*)"\s*$: )
	    {
	    print STDERR "Badly composed triad:  [$triad]\n";
	    next;
	    }
	else
	    {
	    my( $name, $modifier, $value ) = ( $1, $2, $3 );
	    if( $name !~ /^[A-Z0-9_]+$/ )
		{
		print STDERR "$name is not all capital letters in <$triad/>\n";
		next;
		}
	    if( $modifier !~ /^[A-Z0-9_]+$/ )
		{
		print STDERR "$modifier is not all capital letters in <$triad/>\n";
		next;
		}
	    if( $varvals{$name}{$modifier} )
		{
		print STDERR "$name,$modifier already defined with <$triad/>\n";
		next;
		}
	    if( $modifier eq "SYNONYM" )
		{
		if( ! $varvals{$value} )
		    {
		    print STDERR "$name,$modifier points to non-existant definition $value with <$triad/>\n";
		    next;
		    }
		$varvals{$value}{$modifier} = $value;
		next;
		}
	    $varvals{$value}{$modifier} = $value;
	    }
	}
    }

&cleanup( $exit_status );
