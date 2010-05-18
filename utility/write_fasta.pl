#! /usr/bin/perl -w 
=head2 Authors

=head3 Created by

             Vincenza Maselli
             v.maselli@cancer.ucl.ac.uk

=head2 Description
            
            This script retrieves the annotation of the trap sequences from the database ad hoc and stores them in a fasta file

=head2 Usage

            ./update_traptable.pl [-f] [-h help] 

=head2 Options

            -f the fasta file in input
            -h help, type to see the help
           
=head2 CODE BEGIN

=cut

$|=1;
use strict;
BEGIN{

  print "Reading settings from $ENV{'Unitrap'}/unitrap_conf.pl\n";
  require "$ENV{'Unitrap'}/unitrap_conf.pl";
  
}

use DBI;
use Getopt::Long;
use Data::Dumper;

use Bio::SeqIO;
use Bio::Seq;

my $host = 'localhost'	;
my $db= 'UniTrap';
my $user= 'mysql-dev';
my $pass= 'dEvEl0pEr';
my $port;

=pod

      Connecting to unitrap_db 
      
=cut

my $trapdb = DBI->connect("DBI:mysql:database=$db;host=$host;", $user, $pass)|| die "Can't connect: ", $DBI::errst;
$trapdb->{RaiseError}=1;

=pod

  Initializing variables

=cut

my $error;
my $status;

for (my $i = 1; $i <= 901297; $i += 900){

	my $start_id = $i;
	my $end_id = $i + 899;
	
	my $sql = qq{select * from trap where (trap_id >= $start_id AND trap_id < $end_id)};
	print "$sql\n";
	my $sth = $trapdb->prepare($sql) || die;
	$sth->execute;
	
	my $file = "$ENV{'HOME'}/Data/Projects/Trap/fasta/".$start_id."-".($end_id - 1)."trapseq.fa";
	print "$file\n";
	my $seqio = Bio::SeqIO->new(-file => ">$file", -format=>'Fasta');
	
	while (my($traphref) = $sth->fetchrow_hashref){
	#my ($gi,$gino,$gb,$gbacc,$gssid,$gss_name, $clone_id,$dna_type,$strain,$cell_line,$vector)
		last unless $traphref->{'trap_id'};
		my $trapname = "ti|".$traphref->{'trap_id'}."|gi|".$traphref->{'gb_id'}."|gb|".$traphref->{'gb_locus'}."|".$traphref->{'gss_id'}."|".$traphref->{'trap_name'}."|".$traphref->{'clone_id'}."|".$traphref->{'mol_type'}."|".$traphref->{'strain'}."|".$traphref->{'cell_line'}."|".$traphref->{'vector_name'};
		my $sequence = $traphref->{'sequence'};
		my $seq;
		if((length($sequence) > 0) && ($sequence !~ /^[A-Za-z\-\.\*\?]+$/)) {
		   print STDOUT ">$trapname\n$sequence\n";
		   next;
		}
	
		$seq = Bio::Seq->new(-display_id => $trapname, -seq => $sequence);
		#if ($@){print STDOUT ">$trapname\n$sequence\n";}
		$seqio->write_seq($seq);
	
	}
}	
