#!/usr/bin/perl
use 5.010;
use strict;
use warnings;
use LWP::Simple;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;


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
my $ua = LWP::UserAgent->new('IE 9');
$ua->timeout(10);
my $torrentCount = 0;


open(INFILE,$ARGV[0])
	or die "Could not open file '$ARGV[0]' $!";;
=pod
=head1 Reading websites from a file

This file including websites for the script to scan torrent files
The name of the file is specified by the first command line parameter
=cut

#reading websites from the file
while($fileWebsites[$fileLineCount] = <INFILE>){
	chomp $fileWebsites[$fileLineCount];
	scanWebsite($fileWebsites[$fileLineCount]); 
	$fileLineCount++;
}

if($fileLineCount == 0){
	print STDERR "Empty file\n";
}

#debug website list
#foreach my $n (@fileWebsites){
#	say $n;
#}


########## lvl_1 sub declarations come here ##########

=pod
=head2 sacnWebsite Function:

This function goes to the website indicated by the parameter and scan for executable files.
=cut

sub scanWebsite{
	my $req = HTTP::Request->new(GET => @_);
	my $response = $ua->request($req);
 	
 	#debug
 	say @_;
	if ($response->is_success){
   		print $response->content;  
	}
	else {
    	print $response->status_line;
	}
	
	return;
}

sub activeWebsite{ 
	

}


########## lvl_2 sub declarations come here ##########
