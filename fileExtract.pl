#!/usr/bin/perl
use 5.010;
use strict;
use warnings;
use File::Find;
use File::Tempdir;
use Win32::Process;
use Switch;
#use DBI;

my $fromDir = 'E:\uTorrentDownload'; #uTorrent download folder

#my $db = DBI->connect('dbi:mysql:torrentlinks', 'root', 'lrs19920827')
#or die "Connection Error $DBI::errstr\n";

#Open autoit script
my $ProcessObj;
Win32::Process::Create($ProcessObj,
		'C:\Users\Rensheng\autoit\autoInstaller.exe',
		"",
		0,
		NORMAL_PRIORITY_CLASS,
		".")or print STDERR "couldn't exec autoInstaller";

#scan through download folder
opendir(downloadFolder, "$fromDir") || die "Can't open directory $fromDir: $!\n";
my @list = readdir(downloadFolder);
closedir(downloadFolder);

#check each download
foreach my $fn (@list) {
	if($fn =~ m/^\./){ #drop out . & ..
		next;
	}else{
    	my $fp = $fromDir .'\\' . $fn; 
		my $tmpdir = File::Tempdir->new(); #temp folder, auto delete after each loop
		my $toDir = $tmpdir->name;
		#print "\$fp = $fp\n";
		#print "\$fn = $fn\n";
		#print "\$toDir = $toDir\n";	
		if($fp =~ m/.*\.(exe|msi|iso|rar|zip)$/){ #for those not inside a folder
			processFile($fp,'C:\Users\Rensheng\Desktop\try'); #$toDir
		}else{
			processFolder($fp,'C:\Users\Rensheng\Desktop\try'); #$toDir
		### send this folder ($toDir) to server here ###
		}
	}
}

#$db->disconnect();

#take 2 paras: file path & destination. 
sub processFolder{
	my $fileProcessed = 0; #num of successfully extracted files
	my $fileFailed = 0; #num of files failed to extract
	my @filesToExtract;
	find(\&wanted, $_[0]);
	foreach my $fp(@filesToExtract){
		if(processFile($fp,'C:\Users\Rensheng\Desktop\try') == 0){
			$fileProcessed++;
		}else{
			$fileFailed++;
		}
	}
	return;
}

#search wanted files from a folder, write to @filesToExtract (full path)
sub wanted {
	if($File::Find::name =~ m/.*\.(exe|msi|iso|rar|zip)$/){
		$File::Find::name =~ s/\//\\/g;
  		push @filesToExtract, $File::Find::name;
  		return;
	}
	return;
}

#implement depends on different data types, take 2 paras: file path & destination. 
#return 0 if success, -1 if not belong to specified data types, pos num if cant extract
sub processFile{
	switch ($_[0]) {
		case /.*\.iso$/	{ return processISO($_[0],$_[1]) }
		case /.*\.rar$/	{ return processRAR($_[0],$_[1]) }
		case /.*\.zip$/	{ return processZIP($_[0],$_[1]) }
		case /.*\.msi$/	{ return processMSI($_[0],$_[1]) }
		case /.*\.exe$/	{ return processEXE($_[0],$_[1]) }
	}
	return -1;
}

sub processISO{
	my $tempF = $_[0];
	$tempF =~ s/.iso$//;
	if(extract($_[0],$tempF) == 0){
		return 0;
	}
}

sub processRAR{

}

sub processZIP{

}

sub processMSI{

}

sub processEXE{

}

#take 2 para: target file and destination, return 0 if success
sub extract{
	return system("UniExtract.exe  "."\"$_[0]\""." $_[1]" );
}

sub copy{
	return system("xcopy \"$_[0]\" $_[1] \/e \/i \/h");
}
