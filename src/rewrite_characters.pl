#!/usr/bin/perl -w
#
#indx#	rewrite_characters.pl - A filter to rewrite characters in one of several formats
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
#doc#	A file to rewrite characters in one of several formats
########################################################################

use strict;

use lib "/usr/local/lib/perl";

use cpi_file qw( fatal cleanup read_file write_file );
use cpi_arguments qw( parse_arguments );
use cpi_vars;

our %ARGS;
our @problems;
our $exit_status = 0;

# Variables and fields not mentioned will be output in sort order
my @VAR_ORDER = qw(
    HERO HEROINE VILLAIN OLD_MAN OLD_WOMAN BRUTE
    BOY GIRL M0 M1 M2 M3 M4 F0 F1 F2 F3 F4 );
my @FLD_ORDER = qw( TITLE FIRST MIDDLE LAST GENDER JOB REF MEANING );


#########################################################################
#	Print an error message and show how to invoke us.		#
#########################################################################
sub usage
    {
    &fatal( @_, "Usage:  $cpi_vars::PROG <argument>",
        "where <argument> is of:",
	"	-input_file <input file>",
	"	-output_file <output_file>",
	"	-format <format>",
	"	-verbosity 0|1" );
    };

#########################################################################
#	Remove duplicate entries from a list preserving order.		#
#########################################################################
sub remove_dups
    {
    my %seen;
    return grep( !$seen{$_}++, @_ );
    }

#########################################################################
#	Read a character file (in one of two formats)			#
#########################################################################
my $cleardefs = 0;
my %vars;
sub read_characters
    {
    my $variable_fmt_old;
    my $defining_variable;
    foreach my $piece ( split( m:(<.*?>):,&read_file($ARGS{input_file})) )
        {
	if( $piece =~ /^<cleardefs\s*\/>$/ )
	    { $cleardefs = 1; }
	elsif( $piece =~ m:^<setvar\s+name="(.*?)"\s+modifier="(.*?)"\s+value="(.*?)"\s*/>$:ms )
	    { $vars{$1}{$2} = $3; }
	elsif( $piece =~ m:^<setvar\s+name="(.*?)">:ms )
	    { $defining_variable = $1; }
	elsif( $piece =~ m:^</setvar>:ms )
	    { undef $defining_variable; }
	elsif( $defining_variable )
	    { $vars{$defining_variable}{$1} = $2; }
	}
    }

#########################################################################
#	Write character file out in either format.			#
#########################################################################
sub write_characters
    {
    my( $fmt ) = @_;
    my @out;
    push( @out, "<cleardefs/>\n\n" ) if( $cleardefs );

    my $sep = "";
    foreach my $var ( &remove_dups( @VAR_ORDER, sort keys %vars ) )
        {
	next if( ! $vars{$var} );
	push( @out, $sep );
	if( $fmt eq "new0" )
	    { push( @out, "<setvar name=\"$var\">" ); }
	elsif( $fmt eq "new1" )
	    { push( @out, "<setvar name=\"$var\"" ); }

	foreach my $fld ( &remove_dups( @FLD_ORDER, sort keys %{$vars{$var}} ) )
	    {
	    next if( ! $vars{$var}{$fld} );
	    if( $fmt eq "old" )
		{ push(@out, "\n<setvar name=\"$var\" modifer=\"$fld\" value=\"$vars{$var}{$fld}\">"); }
	    else
		{ push(@out, "\n\t$fld=\"$vars{$var}{$fld}\""); }
	    }
	if( $fmt eq "new0" )
	    { push(@out, "\n</setvar>\n"); }
	elsif( $fmt eq "new1" )
	    { push(@out, " />\n"); }
	$sep = "\n";
	}
    &write_file( $ARGS{output_file}, @out );
    }

#########################################################################
#	Main								#
#########################################################################
%ARGS = &parse_arguments({
    switches=>
    	{
	"input_file"	=> "/dev/stdin",
	"output_file"	=> "/dev/stdout",
	"format"	=> "new1",
	"verbosity"	=> 0
	}
    });
$cpi_vars::VERBOSITY = $ARGS{verbosity};

&read_characters();
&write_characters($ARGS{format});

&cleanup( $exit_status );
