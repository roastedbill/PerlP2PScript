use strict;
use warnings;
use File::Copy qw(move);
use File::Find;
use Digest::SHA;

use constant false => 0;
use constant true => 1;

print "\nValidating files...\n";

my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);

$year += 1900;
$mday = substr("0" . $mday, -2);
$mon += 1;
$mon = substr("0" . $mon, -2);

my $notExeFolder = 'C:\Users\Rensheng\Desktop\notExeToday';
#my $notExeTodayFolder = "/etc/script/files/notExe/$year$mon$mday";
my $notExeTodayFolder = 'C:\Users\Rensheng\Desktop\notExe';
my $newFilesFolder = $ARGV[0];
print ("$newFilesFolder\n");
my $filesFolder = 'C:\Users\Rensheng\Desktop\transfer';

unless (-d $notExeFolder)
{
	qx (mkdir $notExeFolder);
}

unless (-d $notExeTodayFolder)
{
	qx (mkdir $notExeTodayFolder);
}

unless (-d $filesFolder)
{
	qx (mkdir $filesFolder);
}

my @filesToExtract;

find(\&wanted, $newFilesFolder);
	
foreach my $filename(@filesToExtract)
{
	if ($filename ne "." && $filename ne "..")
	{
		my $filenameOnly;
		my @temp = split(/\\/,$filename);
		while(@temp){
			$filenameOnly = shift @temp;
		}	

		if (!open (INFILE, $filename))
		{
		 	print "File $filename not found";
			next;
		}
		
		binmode(INFILE);
		
		my ($fileHeader, $bytesRead);
		
		$bytesRead = read(INFILE, $fileHeader, 2);

		close INFILE;

		my $sha512 = Digest::SHA->new(512);
		$sha512->addfile($filename, "b");
		my $fileHash = $sha512->clone->hexdigest;
		
		if ($bytesRead == 2 && $fileHeader ne "MZ")
		{
			

			my $moveTo = $notExeTodayFolder . "\\" . $fileHash . "\.exe";
			
			unless (-e $moveTo)
			{
				print "($fileHeader) move $filenameOnly to $notExeTodayFolder\n";
		
				rename $filename, $moveTo;
			}
			else
			{
				print "($fileHeader) $filenameOnly already exist. Delete it.\n";
				
				unlink $filename;
			}
		}
		else
		{
			print "($fileHeader) move $filenameOnly to $filesFolder\n";
		
			my $moveTo = $filesFolder . "\\" . $fileHash . "\.exe";
			rename $filename, $moveTo;
		}
	}
	
}

#closedir(DIR);

sub wanted {
	if($File::Find::name =~ m/.*\.exe$/){
		$File::Find::name =~ s/\//\\/g;
  		push @filesToExtract, $File::Find::name;
  		return;
	}
	return;
}