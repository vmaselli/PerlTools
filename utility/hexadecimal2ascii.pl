#! /user/bin/perl -w
=head1 Description

  This script takes in input a file with hexadecimal characters and convert thes
e in ASCII characters
  
=head2 Synopsis

  perl hexadecimal2ascii -i <input file>

=head3 Author

  Vincenza Maselli vincenza.maselli@gmail.com

=head4 Last Revision
  
  09/01/2009

=cut

use strict;
use vars;
use Getopt::Std;

my %options =();
getopts ("i:h",\%options);
if (scalar (keys %options) == 0){
  print "USAGE: perl hexadecimal2ascii -i <input file> \n";
  print "For help please type perl perl hexadecimal2ascii -h\n";  
  exit;
}
if ($options{'h'}){
  print "perl hexadecimal2ascii <options>
	 -i the complete path of the file to modify  
	 -h this help\n";
}
my $file = $options{'i'};

my $string;
 
open (IN, $file);

while (my $row = <IN>){
  chomp $row;
  $row =~ s/%0A/ /g;
  $row =~ s/%20/ /g;
  $row =~ s/%21/\!/g;
  $row =~ s/%22/\"/g;
  $row =~ s/%23/\#/g;
  $row =~ s/%24/\$/g;
  $row =~ s/%25/\%/g;
  $row =~ s/%26/\&/g;
  $row =~ s/%27/'/g;
  $row =~ s/%28/(/g;
  $row =~ s/%29/)/g;
  $row =~ s/%2A/\*/g;
  $row =~ s/%2B/+/g;
  $row =~ s/%2C/,/g;
  $row =~ s/%2D/-/g;
  $row =~ s/%2E/\./g;
  $row =~ s/%2F/\//g;
  $row =~ s/%3A/:/g;
  $row =~ s/%3B/;/g;
  $row =~ s/%3C/</g;
  $row =~ s/%3D/=/g;
  $row =~ s/%3E/>/g;
  $row =~ s/%3F/?/g;
  $row =~ s/%40/@/g;
  $row =~ s/%5B/[/g;
  $row =~ s/%5C/\\/g;
  $row =~ s/%5D/]/g;
  $row =~ s/%5E/^/g;
  $row =~ s/%5F/_/g;
  $row =~ s/%60/'/g;
  $row =~ s/%7B/{/g;
  $row =~ s/%7C/\|/g;
  $row =~ s/%7D/}/g;
  $row =~ s/%7E/~/g;
  $row =~ s/%7f//g;
  $row =~s/\+/ /g;
  $string .="$row\n";
}
close(IN);
open (OUT, ">$file");
print OUT $string;
close(OUT);
print "Your file $file was rewritten\n";
