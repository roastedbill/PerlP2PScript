#!/usr/bin/perl
use 5.010;
use strict;
use warnings;
use Mojo::DOM;
use Mojo::UserAgent;
use Mojo::URL;


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
my $ua = Mojo::UserAgent->new;
my %downloaded;
my $torrentCount = 0;

=pod
=head1 Reading websites from a file

This file including websites for the script to scan torrent files
The name of the file is specified by the first command line parameter
=cut

#reading websites from the file

################## FILE IN ##################
#open(INFILE,$ARGV[0])
#	or die "Could not open file '$ARGV[0]' $!";;
#
#while($fileWebsites[$fileLineCount] = <INFILE>){
#	chomp $fileWebsites[$fileLineCount];
#	scanWebsite($fileWebsites[$fileLineCount]); 
#	$fileLineCount++;
#}
#if($fileLineCount == 0){
#	print STDERR "Empty file\n";
#}

################## FILE OUT ##################
open(my $outputFile, '>', 'torrentLinks.txt');

################## Main Function ##################
scanWebsite('http://thepiratebay.se/browse/300');
close $outputFile;
########## lvl_1 sub declarations come here ##########

=pod
=head2 sacnWebsite Function:

This function goes to the website indicated by the parameter and scan for executable files.
=cut

sub scanWebsite{
	##### LWP Version #####
	#my $req = HTTP::Request->new(GET => @_);
	#my $response = $ua->request($req);
 	
	#if ($response->is_success){
   	#	my $contents = $response->content; 
 		#say $contents;
   		#print $outputFile, $parser;
	#}
	#else {
    #	print $response->status_line;
	#}
	
	##### Mojo version #####
	my $contents = $ua->get(@_ => {DNT => 1}) -> res -> body;
	chomp $contents;
	my ($line,@lines) = split(/\n/,$contents);
	foreach $line(@lines){
		my $dom = Mojo::DOM -> new($line);
	}
  	#my $url;

	#print "$url\n";
	#print $outputFile "$url\n";

    #$downloaded{$url} = 1;
    #$torrentCount++;         


	return;
}


########## lvl_2 sub declarations come here ##########
=pod
=head2 Paser Functions:

These functions act as website-depended plugin to extract torrent links.
=cut
