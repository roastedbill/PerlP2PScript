#!/usr/bin/perl
use 5.010;
use strict;
use warnings;
use Mojo::DOM;
use Mojo::UserAgent;
use Mojo::URL;
use DBI;
use DateTime::Format::DBI;

=pod
=head1 P2P Fetching Script
=head2 Fuction:

This Perl Script automatically scan and fetching executable files via torrent 
=cut

#global variables are defined here

my $ua = Mojo::UserAgent->new;
my $torrentCount=0;
my $i=0;
my $j=3;

my $db = DBI->connect('dbi:mysql:torrentlinks', 'root', 'lrs19920827')
or die "Connection Error $DBI::errstr\n";

=pod
=head1 Reading websites from a file

This file including websites for the script to scan torrent files
The name of the file is specified by the first command line parameter
=cut

#reading websites from the file



################## Main Function ##################



for(;$j<5;$j++){
	for ($i=0;$i<100;$i++){
		scanWebsite("http://thepiratebay.se/browse/${j}00/$i/3");
	}
}
 
#say "In total $torrentCount torrent addresses have been successfully fetched!";

downloadTorrent();

$db->disconnect();

########## lvl_1 sub declarations come here ##########

=pod
=head2 sacnWebsite Function:

This function goes to the website indicated by the parameter and scan for executable files.
All the links are stored into "torrentLinks" -> "piratebaylinks" (table)
=cut

sub scanWebsite{
	my $pageN = 100*($j-3)+$i+1;
	say "fetching from page $pageN out of 200";
	my $dom = Mojo::DOM->new($ua->get(@_ => {DNT => 1}) -> res -> body);
	my @urls =split(/\n/, $dom->find('[title="Download this torrent"]')->attr('href'));

	while(@urls){
		my $url = shift @urls;
		my $sth1 = $db->prepare_cached('SELECT * FROM piratebaylinks WHERE site=?') 
		or die "Couldn't prepare statement: " . $db->errstr;
		$sth1->execute('https:'.$url);
		say $sth1->rows;
		if (!$sth1->rows) {
    		$sth1->finish;
	   		$torrentCount++;
			
	    	print 'https:'."$url\n";
	    	my $sth2 = $db->prepare_cached('INSERT INTO piratebaylinks(site) VALUES(?)')
	    	or die "Couldn't prepare statement: " . $db->errstr;
	    
	    	$sth2->execute('https:'.$url);
	    	$sth2->finish;
		}
	}

	return;
}


########## lvl_2 sub declarations come here ##########
=pod
=head2 Paser Functions:

This function downloads the .torrent files using wget and change "downloaded", "downloaddate" attribute of the link.
=cut

sub downloadTorrent{

	my $sth3 = $db->prepare_cached('SELECT * FROM piratebaylinks WHERE downloaded = ?')
    or die "Couldn't prepare statement: " . $db->errstr;
    $sth3->execute('0');    

    if($sth3->rows == 0){
    	say "No new items to download!";
    }
    else{
	    my @data;
	    my $db_parser = DateTime::Format::DBI->new($db);
	   	while(@data = $sth3->fetchrow_array()){
			system("wget --no-check-certificate ". "$data[1]". " -P ./torrents/");
			my $dt = DateTime->now(time_zone => 'local');
			my $sth4 = $db->prepare_cached('UPDATE piratebaylinks SET downloaded=1, downloaddate=? WHERE id=?')
			or die "Couldn't prepare statement: " . $db->errstr;
			$sth4->execute($dt,$data[0]);
			$sth4->finish;
		}
	}
	$sth3->finish;
}