#!/usr/bin/perl
use 5.010;
use strict;
use warnings;
use File::Find;
use File::Tempdir;
use Win32::Process;
use Switch;
#use DBI;

my $fromDir = 'C:\Users\Rensheng\Desktop\test'; #uTorrent download folder
my @filesToExtract; #hold execytable files inside a folder

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
#$ProcessObj->Kill(0);

#scan through download folder
opendir(downloadFolder, "$fromDir") || die "Can't open directory $fromDir: $!\n";
my @list = readdir(downloadFolder);
closedir(downloadFolder);

#check each download
foreach my $fn (@list) {
	@filesToExtract = ();
	if($fn =~ m/^\./){ #drop out . & ..
		next;
	}
	else{
    	my $fp = $fromDir .'\\' . $fn; 
		my $tmpdir = File::Tempdir->new(); #temp folder, auto delete after each loop
		my $toDir = $tmpdir->name;
		say "start extracting $fn to $toDir ..........";
			
		if($fp =~ m/.*\.(exe|msi|iso|rar|zip|cab)$/){ #for those not inside a folder
			processFile($fp,$toDir); #$toDir
			copy($fp,$toDir);
		}else{			
			processFolder($fp); #work in target folder
			copy($fp,$toDir); #$toDir
		}

		### send temp folder ($toDir) to server here ###








	}
}

$ProcessObj->Kill(0);
#$db->disconnect();

#take 2 paras: file path & destination. 
sub processFolder{
	my $fileProcessed = 0; #num of successfully extracted files
	my $fileFailed = 0; #num of files failed to extract
	find(\&wanted, $_[0]);
	foreach my $fp(@filesToExtract){
		if(processFile($fp,$_[0]) == 0){
			$fileProcessed++;
		}
		else{
			$fileFailed++;
		}
	}
	say "fileProcessed: $fileProcessed";
	say "fileFailed: $fileFailed";
	return;
}

sub processFolderOnlyEXE{
	find(\&wantedEXE, $_[0]);
	foreach my $fp(@filesToExtract){
		processFile($fp,$_[0]);
	}
	return;
}

sub processFolderOnlyRAR{
	find(\&wantedRAR, $_[0]);
	foreach my $fp(@filesToExtract){
		processFile($fp,$_[0]);
	}
	return;
}

#search wanted files from a folder, write to @filesToExtract (full path)
sub wanted {
	if($File::Find::name =~ m/.*\.(exe|msi|iso|rar|zip|cab)$/){
		$File::Find::name =~ s/\//\\/g;
  		push @filesToExtract, $File::Find::name;
  		return;
	}
	return;
}

sub wantedEXE{
	if($File::Find::name =~ m/.*\.exe$/){
		$File::Find::name =~ s/\//\\/g;
  		push @filesToExtract, $File::Find::name;
  		return;
	}
	return;
}

sub wantedRAR{
	if($File::Find::name =~ m/.*\.(rar|zip|cab)$/){
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
		case /.*\.cab$/	{ return processCAB($_[0],$_[1]) }
	}
	return -1;
}

sub processISO{
	my $ISOtemp = createExtractFolder($_[0],$_[1]);
	if(extract($_[0],$ISOtemp) == 0){
		#return processFolderOnlyEXE($ISOtemp);
		return 0;
	}
	else{
		### add something to indicate the extraction is not successful! ###
		return -1;
	}
}

sub processRAR{
	my $RARtemp = createExtractFolder($_[0],$_[1]);
	if(extract($_[0],$RARtemp) == 0){
		return 0;
	}
	else{
		### add something to indicate the extraction is not successful! ###
		return -1;
	}
}

sub processZIP{
	my $ZIPtemp = createExtractFolder($_[0],$_[1]);
	if(extract($_[0],$ZIPtemp) == 0){
		return 0;
	}
	else{
		### add something to indicate the extraction is not successful! ###
		return -1;
	}
}

sub processCAB{
	my $CABtemp = createExtractFolder($_[0],$_[1]);
	if(extract($_[0],$CABtemp) == 0){
		return 0;
	}
	else{
		### add something to indicate the extraction is not successful! ###
		return -1;
	}
}

sub processMSI{
	my $i = 0;
	my $MSItemp = createExtractFolder($_[0],$_[1]);
	while(1){
		if($i<3 && is_folder_empty($MSItemp)){ #try 3 ways to extract (may overwrite) 
			extract($_[0],$MSItemp);
			$i++;
		}
		elsif($i>=3 && is_folder_empty($MSItemp)){
			### add something to indicate the extraction is not successful! ###
			return 0;
		}
		else{
			return processFolderOnlyRAR($MSItemp); #including rar, zip, cab, unzip to a folder under current folder	
		}
	}
}

sub processEXE{
	my $i = 0;
	my $EXEtemp = createExtractFolder($_[0],$_[1]);
	while(1){
		if($i<3 && is_folder_empty($EXEtemp)){ #try 3 ways to extract (may overwrite) 
			extract($_[0],$EXEtemp);
			$i++;
			say $i;
		}
		elsif($i>=3 && is_folder_empty($EXEtemp)){
			### add something to indicate the extraction is not successful! ###
			return -1;
		}
		else{
			say "$_[0] is successfully extracted to $EXEtemp!";
			return 0;
		}
	}
}

#take 2 para: target file and destination, return 0 if success
sub extract{
	return system("UniExtract.exe  "."\"$_[0]\""." \"$_[1]\"");
}

sub copy{
	return system("xcopy \"$_[0]\" \"$_[1]\" \/e \/i \/h");
}

sub is_folder_empty {
    my $dirname = shift;
    opendir(my $dh, $dirname) or die "$dirname Not a directory";
    return scalar(grep { $_ ne "." && $_ ne ".." } readdir($dh)) == 0;
}

# take 2 paras: target path and destination path, return path of new folder to extract to
sub createExtractFolder{
	my @temp = split(/\\/,$_[0]);
		my $fp; #name of the file
		while(@temp){
			$fp = shift @temp;
		}
		if(length($fp) > 4){
			$fp = substr $fp, 0, -4;
		}
		$fp = $_[1] . '\\' . $fp; #new destination folder
		unless(-d $fp){ 
			mkdir $fp;
		}
	return $fp;
}
