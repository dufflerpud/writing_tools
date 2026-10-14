#!/usr/bin/perl -w
#
#indx#	time.pl - Software to test generalized time system
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
#doc#	Software to test generalized time system
########################################################################
use strict; 
my %timelines;

my %SECONDS;				# Number seconds in a
$SECONDS{S}=$SECONDS{s}	= ($_=  1);	#  second
$SECONDS{M}		= ($_*=60);	#  minute
$SECONDS{H}=$SECONDS{h}	= ($_*=60);	#  hour
$SECONDS{D}=$SECONDS{d}	= ($_*=24);	#  day
$SECONDS{m}		= ($_*=30);	#  month
$SECONDS{Y}=$SECONDS{y}	= ($_*=12);	#  year

#########################################################################
#	Return a string showing number of seconds in a readable form.	#
#########################################################################
sub offsetstr
    {
    my( $seconds ) = @_;
    my $ret="";
    foreach my $tt ( qw(Y m D H M) )
        {
	my $t = int( $seconds/$SECONDS{$tt} );
	$seconds %= $SECONDS{$tt};
	$ret .= "$t$tt" if( $t );
	}
    $ret.="$ret${seconds}S" if( !$ret || $seconds );
    return $ret;
    }

#########################################################################
#	Return string representing specified seconds since epoch.	#
#########################################################################
sub timestr
    {
    my($sec,$min,$hour,$mday,$month,$year) = localtime($_[0]);
    return sprintf("%4d-%02d-%02d %02d:%02d:%02d",
        $year+1900,$month+1,$mday,$hour,$min,$sec);
    }

#########################################################################
#       Use binary search to convert min,hour,day,month,year to         #
#       seconds from the epoch.                                         #
#########################################################################
sub revlocaltime
    {
    my( @alist ) = @_;
    my( $base ) = 0;
    my( $bit ) = 0x40000000;
    $alist[5] += 100 if( $alist[5] < 90 );
    $alist[5] -= 1900 if( $alist[5] >= 1900 );
    while( $bit )
        {
        my $try = $base | $bit;
        my @compare = localtime( $try );
        my( $i, $res );
        for( $i=5; $i>=0; $i-- )
            {
            last if( $res = ( $alist[$i] <=> $compare[$i] ) );
            }
        if( $res >= 0 )
            {
            $base = $try;
            last if( $res == 0 );
            }
        $bit >>= 1;
        }
    return $base;
    }

#########################################################################
#	Convert a string in many formats to seconds since epoch.	#
#########################################################################
sub parsedate
    {
    my( $tocvt, $relative_to ) = @_;
    return $tocvt if( $tocvt =~ /^\d\d\d\d\d+/ );
    my($csec,$cmin,$chour,$cmday,$cmonth,$cyear)
	= localtime($relative_to?$relative_to:time);
    my($nsec,$nmin,$nhour,$nmday,$nmonth,$nyear);
    foreach $_ ( split(/\s+/,$tocvt) )
        {
	if( /:/ )
	    { ( $nhour, $nmin, $nsec ) = split(':'); }
	elsif( /\// )
	    {
	    my @left = ();
	    foreach my $part ( split('\/') )
	        {
		if( $part > 31 )
		    { $nyear = $part; }
		elsif( $part > 12 && !defined($nmday) )
		    { $nmday = $part; }
		else
		    { push( @left, $part ); }
		}
	    $nmonth = shift(@left) if( !defined($nmonth) );
	    $nmday  = shift(@left) if( !defined($nmday)  );
	    $nyear  = shift(@left) if( !defined($nyear)  );
	    }
	}
    $nmday = $cmday if( !defined($nmday) );
    $nmonth = ( defined($nmonth)?($nmonth-1):$cmonth );
    $nyear = $cyear if( !defined($nyear) );
    $nhour = $chour if( !defined($nhour) );
    $nmin = $cmin if( !defined($nmin) );
    $nsec = $csec if( !defined($nsec) );
    return &revlocaltime($nsec,$nmin,$nhour,$nmday,$nmonth,$nyear);
    }

#########################################################################
#	Update a particular timeline.					#
#########################################################################
my $current_timeline = "base";
sub parse_time_string
    {
    my( $time_strings ) = @_;

    $time_strings =~ s/(\d)\s+(\d)/$1-QQQ-$2/g;
    $time_strings =~ s/\s+//g;
    $time_strings =~ s/-QQQ-/ /g;
    foreach my $time_string ( split(/,/,$time_strings) )
	{
	if( $time_string =~ /(.*)=(.*)/ )
	    {
	    $current_timeline = $1;
	    $time_string = $2;
	    }

	my @toks = grep( defined($_)&&($_ ne ""), split(/(\+|-)/,$time_string) );

	my $tok = shift(@toks);
	if( $tok eq "." )
	    {}
	elsif( $tok eq "now" )
	    { %{$timelines{$current_timeline}} = (basedon=>"",offset=>time()); }
	elsif($tok=~/^\d/ )
	    { %{$timelines{$current_timeline}} = (basedon=>"",offset=>&parsedate($tok)); }
	elsif($timelines{$tok})
	    { %{$timelines{$current_timeline}} = %{$timelines{$tok}}; }
	elsif( $tok =~ /^[A-Za-z]/ )
	    { %{$timelines{$current_timeline}} = (basedon=>$tok,offset=>0); }
	else
	    { unshift(@toks,$tok); }

	my $offset = $timelines{$current_timeline}{offset};
	while( @toks )
	    {
	    my $mul = {"+"=>1,"-"=>-1} -> { shift(@toks) };
	    foreach my $pc ( split(/(\d+[A-Za-z])/,shift(@toks)) )
		{
		if( $pc =~ /^(\d+)(.*)$/ && $SECONDS{$2} )
		    { $offset += $mul * $1 * $SECONDS{$2}; }
		else
		    {
		    my @hms = split(/:/,$pc);
		    $offset += $mul * shift(@hms)*$SECONDS{H} if( @hms );
		    $offset += $mul * shift(@hms)*$SECONDS{M} if( @hms );
		    $offset += $mul * shift(@hms)*$SECONDS{S} if( @hms );
		    }
		}
	    }
	$timelines{$current_timeline}{offset} = $offset;
	}
    }

#########################################################################
#	Prints a timeline which might include relative information.	#
#########################################################################
sub show_timeline
    {
    my( $timeline ) = @_;

    if( ! $timelines{$timeline}{basedon} )
        {return &timestr( $timelines{$timeline}{offset});}
    elsif( $timelines{$timeline}{offset} < 0 )
	{
	return join("-",
	    $timelines{$timeline}{basedon},
	    &offsetstr(-$timelines{$timeline}{offset}) );
	}
    else
	{
	return join("+",
	    $timelines{$timeline}{basedon},
	    &offsetstr($timelines{$timeline}{offset}) );
	}
    }

#########################################################################
#	Maineline for testing						#
#########################################################################
print "> ";
while( $_ = <STDIN> )
    {
    chomp( $_ );
    if( $_ )
	{
	&parse_time_string( $_ );
	print "\n";
	foreach my $timeline ( sort keys %timelines )
	    {
	    printf("%s%-20s = %s\n",
		( $timeline eq $current_timeline ? "*" : " " ),
		$timeline,
		&show_timeline($timeline) );
	    }
	}
    print "\n> ";
    }
exit(0);
