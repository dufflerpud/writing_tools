#!/usr/bin/perl -w
#
#indx#	timeindex.cgi - Show timeline of story in current working directory
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
#hist#	2026-10-17 - Christopher.M.Caldwell0@gmail.com - Created header
########################################################################
#doc#	Show timeline of story in current working directory
########################################################################

use strict;

use lib "/usr/local/lib/perl";
use cpi_time qw(at at_dur at_dur_add at_string);

# Put constants here

my $TMP = "/tmp/$cpi_vars::PROG.$$";

$cpi_vars::BASEDIR = "/usr/local/projects/$cpi_vars::PROG" if( ! -d $cpi_vars::BASEDIR );

our %ONLY_ONE_DEFAULTS =
    (
    "input_file"	=>	"/dev/stdin",
    "output_file"	=>	"/dev/stdout",
    "directory"		=>	".",
    "verbosity"		=>	0
    );

# Put variables here.

my @problems;
our %ARGS;
my @files;
my $exit_stat = 0;

#=======================================================================#
#	New code not from prototype.pl					#
#		Should at least include:				#
#			parse_arguments()				#
#			CGI_arguments()					#
#			usage()						#
#=======================================================================#

#########################################################################
#	Setup arguments if CGI.						#
#########################################################################
sub CGI_arguments
    {
    &CGIreceive();
    grep( $ARGS{$_}=(defined($ARGS{$_})?$ARGS{$_}:$ONLY_ONE_DEFAULTS{$_}),
	keys %ONLY_ONE_DEFAULTS );
    }

#########################################################################
#	Print usage message and die.					#
#########################################################################
sub usage
    {
    &fatal( @_, "",
	"Usage:  $cpi_vars::PROG <possible arguments>","",
	"where <possible arguments> is:",
	"    -i <input file>",
	"    -o <output file>",
	"    -v <verbosity>",
	"    -d <directory>"
	);
    }

#########################################################################
#	Read directory of stories.					#
#########################################################################
sub read_directory
    {
    my $writing_base = "$ARGS{d}/stories";
    my $series_contents = "$writing_base/series/series.xml";
    my %tok_to_name;
    my %tok_to_dir;
    my %tok_to_when;
    my @ret;
    opendir( D, $writing_base ) || &fatal("Cannot opendir( $writing_base ):  $!");
    foreach my $dir_name ( readdir(D) )
        {
	my $contents = &read_file("$writing_base/$dir_name/index.cgi","" );
	if( $contents =~ /<story.*?name="(.*?)"/ms )
	    {
	    my $story_tok = $1;
	    my $story_name = $1;
	    $story_tok =~ s/s's/s/g;
	    $story_tok =~ s/'s/s/g;
	    $story_tok =~ s/[^\w_]+/_/g;
	    $story_tok=$1 if( $story_tok =~ /^_*(.*?)_*$/ );

	    $tok_to_name{$story_tok}=$tok_to_name{$dir_name} = $story_name;
	    $tok_to_dir{$story_tok}=$tok_to_dir{$dir_name} = $dir_name;
	    }
	}
    closedir( D );

    my $contents = &read_file($series_contents);
    $contents =~ s+\s*#[^\n]*$++msg;
    my $last_time = &at();
    foreach my $pc ( split(/(<.*?)/ms, $contents ) )
        {
	if( $pc =~ m:^\s*setvar\s+name\s*=\s*"timeline"(.*)/>:ms )
	    {
	    my $timeline_clause = $1;
	    foreach my $tpc ( split(/([\w_]+\s*=\s*".*?")/, $timeline_clause ) )
	        {
		if( $tpc =~ /^\s*([\w_]+)\s*=\s*"(.*)"/ && $1 ne "alt" )
		    {
		    my( $tok, $timestr ) = ( $1, $2 );
		    if( $timestr =~ /^\s*([\-\d].*?)\s*$/ )
		        { $tok_to_when{$tok} = &at($1); }
		    elsif( $timestr eq "now" )
		        { $tok_to_when{$tok} = &at(); }
		    elsif( $timestr =~ /^(.*)([+|-].*)$/ )
		        {
			my( $start, $offset ) = ( $1, $2 );
			if( $start eq "now" )
			    { $start = &at(); }
			elsif( $start eq "." )
			    { $start = $last_time; }
			elsif( $tok_to_when{$start} )
			    { $start = $tok_to_when{$start}; }
			else
			    { &fatal("Don't know how to parse [$start]"); }
			my $duration = &at_dur($offset);
			$tok_to_when{$tok} = &at_dur_add( $start, $duration );
			}
		    $timestr = &at_string( undef, $tok_to_when{$tok} )
			if( $tok_to_when{$tok} );
		    push( @ret, {
			tok=>$tok,
			when=>$timestr,
			name=>$tok_to_name{$tok}||"-",
			dir=>$tok_to_dir{$tok}||"-" } )
		        if( $tok_to_name{$tok} );
		    }
		}
	    }
	}
    return @ret;
    }

#########################################################################
#	Print a simple text version of the directory.			#
#########################################################################
sub directory_text
    {
    foreach my $dp ( &read_directory() )
        {
	printf("%-20s %-25s %-20s\n",
	    map{ $dp->{$_}||"UNDEF" } qw(dir name when) );
	}
    }

#########################################################################
#	Print a simple text version of the directory.			#
#########################################################################
sub directory_cgi
    {
    &CGIheader();
    print "<center><table width=85% frame=border cellspacing=0>\n";
    print "<tr>",
        "<th align=left><a href=/index.cgi>Story</a></th>",
	"<th align=left>Name</th>",
	"<th align=left>When</th></tr>\n";
    foreach my $dp ( &read_directory() )
        {
	print	"<tr><td>",
		"<a href='stories/",$dp->{dir},"'>",$dp->{dir},"</a>",
		"</td><td>",
		$dp->{name}||"-",
		"</td><td>",
		$dp->{when},
		"</td></tr>\n";
	}
    print "</table></center>\n";
    }

#########################################################################
#	Main								#
#########################################################################

if( $ENV{SCRIPT_NAME} )
    {
    &CGI_arguments();
    &directory_cgi();
    }
else
    {
    &parse_arguments();
    &directory_text();
    }

exec("rm -rf $TMP");
