#!/usr/bin/perl
use strict;
use warnings;
use Net::FTP;
use Digest::SHA;
use DBI;
use File::Copy qw(move);
use File::Basename;

if ($#ARGV != 0)
{
	printf "Usage: UploadFile <filename or foldername>\n";
	exit;
}

my $errorMessage = undef;

my $database = "dbi:mysql:torrentlinks";
my $username = "root";
my $password = "lrs19920827";

my $file = $ARGV[0];

my $dbh = DBI->connect($database, $username, $password) or do 
{ 
	print "Cannot connect to database: $DBI::errstr\n";
	cleanup();
	exit;
};

my $url = "uav.secureage.com";
my $ftp = Net::FTP->new ($url, Debug => 0) or do
{
	print "Cannot connect to $url: $@\n";
	cleanup();
	exit;
};

$ftp->login("sampleftp", "welcome") or do 
{
	print "Login failed !!! " . $ftp->message . "\n";
	cleanup();
	exit;
};

$ftp->binary;

if (-d $file)
{
	processFolder($file);
}
else
{
	processFile($file);
}

cleanup();
exit;

sub cleanup
{
	if (defined $ftp)
	{
		$ftp->quit;
	}
	
	if (defined $dbh)
	{
		$dbh->disconnect();
	}
}

sub processFolder
{
	my ($foldername) = @_;
	
	my  ($folderHandle);

	opendir ($folderHandle, $foldername) or die $!;
	
	while (my $filenameOnly = readdir($folderHandle))
	{
		if ($filenameOnly ne "." && $filenameOnly ne "..")
		{
			my $filename = $foldername . "\\" . $filenameOnly;
			
			if (-d $filename)
			{
				processFolder($filename);
			}
			else
			{
				processFile($filename);
			}
		}
		
	}

	closedir($folderHandle);
}



sub processFile
{
	my ($filename) = @_;

	my $sha256 = Digest::SHA->new(256);
	$sha256->addfile($filename, "b");
	my $fileHash = $sha256->clone->hexdigest;

	my $sha256Uav = Digest::SHA->new(256);
	$sha256Uav->add("\xF0\x74\x05\x07\x21\x7F\xC5\x2F\x62\xCA\x7E");
	$sha256Uav->add($sha256->digest);
	my $fileHashUav = $sha256Uav->hexdigest;

	my $fileSize = -s $filename;

	my $count = $dbh->selectrow_array("SELECT COUNT(*) FROM uploaded WHERE filesize = ? AND filehash = ?", undef, $fileSize, $fileHash);

	if ($count > 0)
	{
		print "Already uploaded before !!!\n";
	}
	else
	{
		my $fileNameUav = uc($fileHashUav) . "_" . $fileSize;

		$ftp->put($filename, $fileNameUav);

		my $resultFileName = "C:\\Users\\Rensheng\\Desktop\\uploadFile.ret";

		unlink ($resultFileName);

		system ("wget \"http://$url/NotifyFileUpload_v2.php?Version=2.0&Filename=$fileNameUav\" -O $resultFileName");

		if (-e $resultFileName)
		{
			my ($result, $fhandle);
			open ($fhandle, "<", $resultFileName);
			{
				local $/;
				$result = <$fhandle>;
			}
			close ($fhandle);

			if ($result eq "OK")
			{
				my $failed = 0;
				my $sql = "INSERT INTO uploaded (filesize, filehash) VALUES (?, ?)";

				$dbh->do($sql, undef, ($fileSize, $fileHash)) or do 
				{
					print "Insert failed !!! $dbh->errstr\n";
					$failed = 1;
				};
				
				if ($failed == 0)
				{
					my $moveAs = "C:\\Users\\Rensheng\\Desktop\\repo\\" . basename($filename);
					move $filename, $moveAs;
				}
			}
		}
	}
}
