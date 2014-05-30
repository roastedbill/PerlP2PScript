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

This Perl Script automatically scan and fetching executable files via magnet links 
=cut

#global variables are defined here

my $ua = Mojo::UserAgent->new;

#####choose your website here#####
my $website = 'KICKASS'; #'PIRATEBAY','KICKASS'
my $title; 
my $i;
my $j;
my $totalPages;
my $currentPage;
my $lastTimePage;
my $window=10; #add torrent to uTorrent every 10 torrent downloaded

=pod
=head1 Reading webmagnetlinks from a file

This file including webmagnetlinks for the script to scan torrent files
The name of the file is specified by the first command line parameter
=cut

#reading webmagnetlinks from the file



################## Main Function ##################

my $db = DBI->connect('dbi:mysql:torrentlinks', 'root', 'lrs19920827')
or die "Connection Error $DBI::errstr\n";

while(1)
	scanWeb($website);
	downloadFile();
	$lastTimePage = $currentPage;
	last if($currentPage == $totalPages);
}

say "All the files from $website have been added to uTorrent download queue successfully!";
$db->disconnect();

########## lvl_1 sub declarations come here ##########

=pod
=head2 sacnWebmagnetlink Function:

This function goes to the webmagnetlink indicated by the parameter and scan for executable files.
All the links are stored into "torrentLinks" -> "piratebaymagnetlinks" (table)
=cut

sub scanWeb{
	
	if($_[0] eq 'PIRATEBAY'){
		$title = "Download this torrent using magnet";
		$totalPages = 200;
		$lastTimePage = 0;
		$j=3;
		for(;$j<5;$j++){
			for ($i=0;$i<100;$i++){
				$currentPage = 100*($j-3)+$i+1;
				scanWebsite("http://thepiratebay.se/browse/${j}00/$i/3");
				if($currentPage - $lastTimePage >= $window){
					return;
				}
			}
		}
	}
	elsif($_[0] eq 'KICKASS'){
		$title = "Torrent magnet link";
		$totalPages = 800;
		$lastTimePage = 1;
		for ($i=$lastTimePage;$i<401;$i++){
				$currentPage = 2*$i-1;
				scanWebsite("http://kickass.to/applications/$i/");
				$currentPage = 2*$i;
				scanWebsite("http://kickass.to/games/$i/");
				last if($currentPage - $lastTimePage >= $window);
			}

	}
	elsif($_[0] eq 'TORRENTFUNK'){

	}
	else{
		say "$_[0] is not a website supported by this script, please chech again!";
	}
	return;
}

sub scanWebsite{
	say "fetching from page $currentPage out of $totalPages from $website";
	my $dom = Mojo::DOM->new($ua->get(@_ => {DNT => 1}) -> res -> body);
	if ($dom){
		my @urls =split(/\n/, $dom->find("[title=$title]")->attr('href'));

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
