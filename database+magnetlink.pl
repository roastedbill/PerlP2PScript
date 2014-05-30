#!/usr/bin/perl
use 5.010;
use strict;
use warnings;
use Mojo::DOM;
use Mojo::UserAgent;
use Mojo::URL;
use DBI;
use DateTime::Format::DBI;
use Net::uTorrent;

=pod
=head1 P2P Fetching Script
=head2 Fuction:

This Perl Script automatically scan and fetching executable files via torrent 
=cut

#global variables are defined here

my $ua = Mojo::UserAgent->new;
my $torrentCount=0;
my $lastTimeCount=0;
my $window=10; #add torrent to uTorrent every 10 torrent downloaded
my $i=0;
my $j=3;

my $db = DBI->connect('dbi:mysql:torrentlinks', 'root', 'lrs19920827')
or die "Connection Error $DBI::errstr\n";

=pod
=head1 Reading webmagnetlinks from a file

This file including webmagnetlinks for the script to scan torrent files
The name of the file is specified by the first command line parameter
=cut

#reading webmagnetlinks from the file



################## Main Function ##################

for(;$j<5;$j++){
	for ($i=0;$i<100;$i++){
		scanWebsite("http://thepiratebay.se/browse/${j}00/$i/3");
	}
}

downloadFile();

say "All the files are added to uTorrent download queue successfully!";
$db->disconnect();

########## lvl_1 sub declarations come here ##########

=pod
=head2 sacnWebmagnetlink Function:

This function goes to the webmagnetlink indicated by the parameter and scan for executable files.
All the links are stored into "torrentLinks" -> "piratebaymagnetlinks" (table)
=cut

sub scanWebsite{
	my $pageN = 100*($j-3)+$i+1;
	say "fetching from page $pageN out of 200";
	my $dom = Mojo::DOM->new($ua->get(@_ => {DNT => 1}) -> res -> body);
	my @urls =split(/\n/, $dom->find('[title="Download this torrent using magnet"]')->attr('href'));

	while(@urls){
		my $url = shift @urls;
		my $sth1 = $db->prepare_cached('SELECT * FROM piratebaymagnetlinks WHERE magnetlink=?') 
		or die "Couldn't prepare statement: " . $db->errstr;
		$sth1->execute($url);
		if (!$sth1->rows) {
	    	print "$url\n";
	    	my $sth2 = $db->prepare_cached('INSERT INTO piratebaymagnetlinks(magnetlink) VALUES(?)')
	    	or die "Couldn't prepare statement: " . $db->errstr;
	    
	    	$sth2->execute($url);
	    	$sth2->finish;
		}
		$sth1->finish;
	}

	return;
}




########## lvl_2 sub declarations come here ##########
=pod
=head2 Download File Functions:

This function adds magnet links to uTorrent and start download
=cut
sub downloadFile{
	my $utorrent = Net::uTorrent->new (
                                             hostname        =>      'localhost',
                                             port            =>      '10151',
                                             user            =>      'admin',
                                             pass            =>      'admin',
                                       );
	die unless $utorrent->login_success;

	$utorrent->set_settings (
                                             max_ul_rate     =>      3000,
                                             max_dl_rate     =>      5000
                                       );


	my $db_parser = DateTime::Format::DBI->new($db);
	my $sth3 = $db->prepare_cached('SELECT * FROM piratebaymagnetlinks WHERE filedownloaded=?')
    or die "Couldn't prepare statement: " . $db->errstr;
    $sth3->execute('0');
    while(my @data = $sth3->fetchrow_array()){
    	$utorrent->add_url($data[1]);
    	my $dt = DateTime->now(time_zone => 'local');
    	my $sth4 = $db->prepare_cached('UPDATE piratebaymagnetlinks SET filedownloaded=1, filedownloadtime=? WHERE id=?')
    	or die "Couldn't prepare statement: " . $db->errstr;
    	$sth4->execute($dt,$data[0]);
		$sth4->finish;
    }
    $sth3->finish;

	return;
}
