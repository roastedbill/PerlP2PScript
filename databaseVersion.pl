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
my $totalPages;
my $torrentCount=0;
my $lastTimeCount=0;
my $window=10; #add torrent to uTorrent every 10 torrent downloaded
my $title; 
my $i;
my $j;
my $website = 'EXTRATORRENT';


=pod
=head1 Reading websites from a file

This file including websites for the script to scan torrent files
The name of the file is specified by the first command line parameter
=cut

#reading websites from the file



################## Main Function ##################
my $db = DBI->connect('dbi:mysql:torrentlinks', 'root', 'lrs19920827')
or die "Connection Error $DBI::errstr\n";

scanWeb($website);


my $sth3 = $db->prepare_cached('SELECT * FROM piratebaylinks WHERE downloaded = ?')
or die "Couldn't prepare statement: " . $db->errstr;
$sth3->execute('0');  
#my @d= $sth3->fetchrow_array();

while($sth3->rows){	
	downloadTorrent();
	downloadFile();
}

$sth3->finish;
say "All the files are added to uTorrent download queue successfully!";
$db->disconnect();

########## lvl_1 sub declarations come here ##########

=pod
=head2 sacnWebsite Function:

This function goes to the website indicated by the parameter and scan for executable files.
All the links are stored into "torrentLinks" -> "piratebaylinks" (table)
=cut

sub scanWeb{
	if($_[0] eq 'EXTRATORRENT'){
		$title = "Download this torrent using magnet";
		$totalPages = 200;
		for ($i=1111;$i<=1680;$i++){
			$torrentCount = $i;
			scanWebsite("http://extratorrent.cc/category/20/Windows+-+CD-DVD+Tools+Torrents.html?page=${i}&srt=added&order=desc&pp=50");
		}
		for ($i=1;$i<=1158;$i++) {
			$torrentCount++;
			scanWebsite("http://extratorrent.cc/category/25/Windows+-+Other+Torrents.html?page=${i}&srt=added&order=desc&pp=50");
		}
		for ($i=1;$i<=784;$i++) {
			$torrentCount++;
			scanWebsite("http://extratorrent.cc/category/21/Windows+-+Photo+Editing+Torrents.html?page=${i}&srt=added&order=desc&pp=50");
		}
		for ($i=1;$i<=179;$i++) {
			$torrentCount++;
			scanWebsite("http://extratorrent.cc/category/22/Windows+-+Security+Torrents.html?page=${i}&srt=added&order=desc&pp=50");
		}
		for ($i=1;$i<=55;$i++) {
			$torrentCount++;
			scanWebsite("http://extratorrent.cc/category/23/Windows+-+Sound+Editing+Torrents.html?page=${i}&srt=added&order=desc&pp=50");
		}
		for ($i=1;$i<=103;$i++) {
			$torrentCount++;
			scanWebsite("http://extratorrent.cc/category/24/Windows+-+Video+Apps+Torrents.html?page=${i}&srt=added&order=desc&pp=50");
		}
	}
	else{
		say "$_[0] is not a website supported by this script, please chech again!";
	}
	return;
}

sub scanWebsite{
	say "fetching from page $torrentCount";
	my $dom = Mojo::DOM->new($ua->get(@_ => {DNT => 1}) -> res -> body);
	if($dom->match('a[title^="Download "][title$="torrent"]')){
		my @urls =split(/\n/, $dom->find('a[title^="Download "][title$="torrent"]')->attr('href'));

		while(@urls){
			my $url = shift @urls;
			my $sth1 = $db->prepare_cached('SELECT * FROM piratebaylinks WHERE site=?') 
			or die "Couldn't prepare statement: " . $db->errstr;
			$sth1->execute('http://extratorrent.cc'.$url);
			if (!$sth1->rows) {
	    		print 'http://extratorrent.cc'."$url\n";
	    		my $sth2 = $db->prepare_cached('INSERT INTO piratebaylinks(site) VALUES(?)')
	    		or die "Couldn't prepare statement: " . $db->errstr;
	    	
	    		$sth2->execute('http://extratorrent.cc'.$url);
	    		$sth2->finish;
			}
			$sth1->finish;
		}
	}

	return;
}


########## lvl_2 sub declarations come here ##########
=pod
=head2 Download .torrent Functions:

This function downloads the .torrent files using wget and change "downloaded", "downloaddate" attribute of the link.
=cut

sub downloadTorrent{	
	my @data;
	my $db_parser = DateTime::Format::DBI->new($db);
	while(@data = $sth3->fetchrow_array()){
		if(system("wget --no-check-certificate ". "$data[1]". " -P ./torrents/") == 0){
			my $dt = DateTime->now(time_zone => 'local');
			my $sth4 = $db->prepare_cached('UPDATE piratebaylinks SET downloaded=1, downloaddate=? WHERE id=?')
			or die "Couldn't prepare statement: " . $db->errstr;
			$sth4->execute($dt,$data[0]);
			$sth4->finish;
			$torrentCount++;
		}
		last if($torrentCount-$lastTimeCount>=$window);
	}
	$lastTimeCount = $torrentCount;
	return;
}


########## lvl_3 sub declarations come here ##########
=pod
=head2 Download File Functions:

This function downloads the .torrent files using wget and change "downloaded", "downloaddate" attribute of the link.
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

	my $dir = './torrents/';

	my $db_parser = DateTime::Format::DBI->new($db);
	foreach my $fp(glob("$dir/*.torrent")){
		my @temp = split(/\//,$fp);
		my $fn; #name of the file
		while(@temp){
			$fn = shift @temp;
		}
		formatString(\$fn);
		my $dt = DateTime->now(time_zone => 'local');
		my $sth5 = $db->prepare_cached('SELECT * FROM piratebaylinks WHERE filedownloaded=0 and site REGEXP ?')
    	or die "Couldn't prepare statement: " . $db->errstr;
    	$sth5->execute($fn);
    	if($sth5->rows){
    		$utorrent->add_file($fp);
    		my $sth6 = $db->prepare_cached('UPDATE piratebaylinks SET filedownloaded=1, filedownloaddate=? WHERE filedownloaded=0 and site REGEXP ?')
    		or die "Couldn't prepare statement: " . $db->errstr;
    		$sth6->execute($dt,$fn);
			$sth6->finish;
    	}
    	$sth5->finish;
	}

	return;
}

# This subfunction belongs to downloadFile function. It provides formated string for MySQL regular expression 
sub formatString{
	my $string = $_[0];
	$$string =~ s/\(/\\\(/g;
	$$string =~ s/\)/\\\)/g;
	$$string =~ s/\[/\\\[/g;
	$$string =~ s/\]/\\\]/g;	
	$$string =~ s/\{/\\\{/g;
	$$string =~ s/\}/\\\}/g;
	return
}