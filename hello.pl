#!/usr/bin/perl
use 5.010;
use strict;
use warnings;
use Scalar::Util qw(looks_like_number);

use constant false => 0;
use constant true => 1;

=pod
=head1 P2P Fetching Script
=head2 Fuction:

This Perl Script automatically scan and fetching executable files via torrent 
=cut

#global variables are defined here

my $fileLineCount = 0;
my @fileWebsites;



open(INFILE,$ARGV[0])
	or die "Could not open file '$ARGV[0]' $!";;
=pod
=head1 Reading websites from a file

This file including websites for the script to scan torrent files
The name of the file is specified by the first command line parameter
=cut

#reading websites from the file
while($fileWebsites[$fileLineCount] = <INFILE>){
	$fileLineCount++;
}

if($fileLineCount == 0){
	print STDERR "Could not open file\n";
}

foreach my $n (@fileWebsites){
	say $n;
}
#chomp $name;
#if(looks_like_number($name)){
#	say "hi $name, what's up?";
#}