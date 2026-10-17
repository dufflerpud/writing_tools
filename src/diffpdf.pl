#!/usr/bin/perl -w
#
#indx#	diffpdf.pl - Diff PDF files looking for useful differences
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
#hist#	2026-10-17 - Christopher.M.Caldwell0@gmail.com - Created header
########################################################################
#doc#	Diff PDF files looking for useful differences.  Result is also PDF file.
########################################################################

use strict;

use lib "/usr/local/lib/perl";
use cpi_file qw( fatal cleanup write_lines );
use cpi_arguments qw( parse_arguments );

my $TMPBASE = "/tmp/$cpi_vars::PROG";

my $DEBUG = 0;

my $MOD_STR = "MOD:";
$MOD_STR = "";

our %ARGS;
our $exit_status = 0;
our @files;
our @problems;

my $STRIKE_OPEN="<strike style='text-decoration:line-through;color:red;background-color:LightGray'><font style='color:DarkGray'>$MOD_STR";
my $STRIKE_CLOSE="</font></strike>";

my $ADDED_OPEN="<font style='font-weight:bold;background-color:LightGreen;color=DarkGreen'>$MOD_STR";
my $ADDED_CLOSE="</font>";

#########################################################################
#	Print an error, a usage message, and die.			#
#########################################################################
sub usage
    {
    &fatal(@_,"\nUsage:  $cpi_vars::PROG <argument>",
        "where <argument> is any of:",
	"	-old_file <old file>",
	"	-new_file <new file>",
	"	-differences_file <differences file>" );
    exit(1);
    }

#########################################################################
#	Convert file to have different words on each file ignoring	#
#	xmlisms.							#
#########################################################################
sub convert
    {
    my( $old_file_name, $new_file_name ) = @_;
    open( INF, $old_file_name )
	|| &usage("Cannot open ${old_file_name}:  $!");
    open( OUT, ">$new_file_name" )
	|| &usage("Cannot write ${new_file_name}:  $!");

    my $hdr = <INF>;		# This gets the #!/ line
    print OUT $hdr;

    foreach my $txt ( split(/(<.*?>)/s,join("",<INF>)) )
        {
	if( $txt =~ /<.*/ )
	    {
	    print OUT $txt if( $txt !~ /<trademark/ && $txt !~ /<\/trademark/ );
	    }
	else
	    {
	    my @pieces = split(/(\s+)/,$txt);
	    while( defined($_ = shift(@pieces)) )
		{
		if( $_ =~ /\n\s*\n/ )
		    { print OUT "\n\n"; }
		elsif( $_ =~ /\s*\n\s*/ )
		    { print OUT "\n"; }
		else
		    {
		    print OUT $_;
		    if( $_ !~ /\s/ )
			{
			if( @pieces && $pieces[0] =~ /^[ 	]+$/ )
			    {
			    shift( @pieces );
			    print OUT "\n";
			    }
			}
		    }
		}
	    }
	}
    close( OUT );
    close( INF );
    }

#########################################################################
#	Glue the tags to the first and last lines.			#
#########################################################################
sub fix_newlines
    {
    my( $start_tag, @lines ) = @_;
    my $end_tag = pop @lines;
    $lines[0] = $start_tag . $lines[0];
    $lines[$#lines] .= $end_tag;
    return @lines;
    }

#########################################################################
#	Main								#
#########################################################################

%ARGS = &parse_arguments({
    non_switches => \@files,
    switches =>
    	{
	"old_file"		=> "",
	"new_file"		=> "",
	"differences_file"	=> ""
	}
    });

foreach my $fld ( qw(old_file new_file differences_file) )
    {
    $ARGS{$fld}=shift(@ARGV) if( $ARGS{$fld} eq "" );
    }

if( ! defined( $ARGS{old_file} ) )
        { push( @problems, "-old_file not specified." ) }
    elsif( ! -f $ARGS{old_file} || ! -r $ARGS{old_file} )
        { push( @problems, "-old_file ($ARGS{old_file}) is not readable."); }
if( ! defined( $ARGS{new_file} ) )
        { push( @problems, "-new_file not specified." ) }
    elsif( ! -f $ARGS{new_file} || ! -r $ARGS{new_file} )
        { push( @problems, "-new_file ($ARGS{new_file}) is not readable."); }
if( ! defined( $ARGS{differences_file} ) )
        { push( @problems, "-differences_file not specified." ) }
    elsif( -e $ARGS{differences_file} )
        { push( @problems, "-differences_file ($ARGS{differences_file}) already exists."); }

push( @problems, "Too many files specified." ) if( @files );

&usage( @problems ) if( @problems );

&convert( $ARGS{old_file}, "$TMPBASE.old" );
&convert( $ARGS{new_file}, "$TMPBASE.new" );
open( INF, "$TMPBASE.old" ) || &usage("$TMPBASE.old not readable:  $!");
my @lines = <INF>;
chomp( @lines );
close( INF );

my $passnum = 0;
&write_lines( "/tmp/".$passnum++, @lines ) if( $DEBUG );
my $cmd = "diff -e '$TMPBASE.old' '$TMPBASE.new'";
open( INF, "$cmd |" ) || &usage("$cmd failed:  $!");
while( $_ = <INF> )
    {
    chomp( $_ );
    $_ = "$1,${1}$2" if( /^(\d+)([acd])/ );
    if( ! /^(\d+),(\d+)([acd])/ )
        {
	print STDERR "Unknown ed commands [$_]\n";
	}
    else
        {
	my( $from_line ) = $1 - 1;
	my( $to_line ) = $2 - 1;
	my( $op ) = $3;
	my @new_lines;
	if( $op eq "d" )
	    {
	    push( @new_lines, @lines[0..$from_line-1] )
		if( $from_line > 0 );
	    push( @new_lines,
	        &fix_newlines(
		    $STRIKE_OPEN, @lines[$from_line..$to_line], $STRIKE_CLOSE ) );
	    push( @new_lines, @lines[$to_line+1..$#lines] )
	        if( $to_line+1 <= $#lines );
	    }
	else		# if( $op eq "a" || $op eq "c" )
	    {
	    my @text;
	    while( $_ = <INF> )
	        {
		chomp( $_ );
		last if( $_ eq "." );
		push( @text, $_ );
		}
	    if( $op eq "a" )
	        {
		push( @new_lines, @lines[0..$from_line] )
		    if( $from_line >= 0 );
		push( @new_lines,
		    &fix_newlines( $ADDED_OPEN, @text, $ADDED_CLOSE ) );
		push( @new_lines, @lines[$from_line+1..$#lines] )
		    if( $from_line+1 <= $#lines );
		}
	    else	# if( $op eq "c" )
	        {
		push( @new_lines, @lines[0..$from_line-1] )
		    if( $from_line-1 >= 0 );
		push( @new_lines,
		    &fix_newlines( $ADDED_OPEN, @text, $ADDED_CLOSE ) );
		push( @new_lines,
		    &fix_newlines(
			$STRIKE_OPEN, @lines[$from_line..$to_line], $STRIKE_CLOSE
			) );
		push( @new_lines, @lines[$to_line+1..$#lines] )
		    if( $to_line+1 <= $#lines );
		}
	    }
	@lines = @new_lines;
	&write_lines( "/tmp/".$passnum++, @lines ) if( $DEBUG );
	}
    }
close( INF );

&write_lines( $ARGS{differences_file}, @lines );

&cleanup($exit_status);
