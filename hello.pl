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

my $ua = Mojo::UserAgent->new;
my %downloaded;
my $torrentCount=0;
my $i=0;
my $j=3;
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


################## Main Function ##################

#open(my $outputFile, '>', 'torrentLinks.txt');

#for(;$j<5;$j++){
#	for ($i=0;$i<100;$i++){
#		scanWebsite("http://thepiratebay.se/browse/${j}00/$i/3");
#	}
#}
 
#say "In total $torrentCount torrent addresses have been successfully fetched!";

#close $outputFile;
open(my $linkFile, '<', 'torrentLinks.txt') or die "Couldn't Open torrentLinks.txt for reading because: .$!";

while(my $link = <$linkFile>){
	downloadTorrent($link);
}

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
	say @_;
	my $pageN = 100*($j-3)+$i+1;
	say "fetching from page $pageN out of 200";
	my $dom = Mojo::DOM->new($ua->get(@_ => {DNT => 1}) -> res -> body);
	my @urls =split(/\n/, $dom->find('[title="Download this torrent"]')->attr('href'));

	while(@urls){
		my $url = shift @urls;
		if (!$downloaded{$url}){
    	
    		$downloaded{$url} = 1;
	   		$torrentCount++;
			
			#print "torrentCount is now: $torrentCount\n";
	    	print 'https:'."$url\n";
#			print $outputFile 'https:'."$url\n";
		}
	}

	return;
}


########## lvl_2 sub declarations come here ##########
=pod
=head2 Paser Functions:

This function downloads the .torrent files using wget.
=cut

sub downloadTorrent{
	chomp @_;
	system("wget --no-check-certificate ". "@_". " -P ./torrents/");
}