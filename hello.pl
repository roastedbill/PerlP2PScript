#!/usr/bin/perl
use 5.010;
use strict;
use warnings;
use Scalar::Util qw(looks_like_number);

use constant false => 0;
use constant true => 1;

=pod
=head1 P2P Fetching Script
=head2 Fuction:

This Perl Script automatically scan and fetching executable files via torrent 
=cut


say "Hello World";
my $name = <STDIN>;
chomp $name;
if(looks_like_number($name)){
    say "hi $name, what's up?";
}