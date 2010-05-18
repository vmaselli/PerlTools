#! /usr/bin/perl -w

use strict;
use vars;
use Data::Dumper;

use DBI;
use Bio::EnsEMBL::Registry;


my $registry = 'Bio::EnsEMBL::Registry';
$registry->load_registry_from_db(
	      -host => "ensembldb.ensembl.org",
	      -user => "anonymous",
	      -database => "mus_musculus_core_56_37i",
	      -port => "5306"
);
my $slice_adaptor = $registry->get_adaptor( 'Mouse', 'Core', 'Slice' );

unless (defined$slice_adaptor){
print "Second way\n";

my $dba = Bio::EnsEMBL::DBSQL::DBAdaptor->new(
    	-host => "ensembldb.ensembl.org",
        -user => "anonymous",
		-dbname => "mus_musculus_core_56_37i",
		-port =>"5306"
) || die "Can't connect: ", $DBI::errst;


	$slice_adaptor = $dba->get_SliceAdaptor || die  $DBI::errst;
}
my $slice = $slice_adaptor->fetch_by_region ("chromosome",4,1,1000);