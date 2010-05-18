=head1 Bio::DBSQL::DB

=head2 Authors

=head3 Modified by

             Vincenza Maselli
             v.maselli@ucl.ac.uk

=head3 Created by

              Guglielmo Roma
              guglielmoroma@libero.it

=head2 Description
        
             This module have method to handle with the database
             
=head2 Example

	my $db_obj = Bio::DBSQL::DB->new;
	$db_obj->db_connection;
	$db_obj->host;

	my $registry = 'Bio::EnsEMBL::Registry';
	$registry->load_registry_from_db(
		      -host => $conf{'dbaccess'}{'enshost'},
		      -user => $conf{'dbaccess'}{'ensuser'},
		      -pass => $conf{'dbaccess'}{'enspass'},
		      -database => $conf{'dbaccess'}{'ensdbname'},
		      -port => $conf{'dbaccess'}{'ensport'}
	);

	$db_obj->ensembl_connection($registry);
	defined $registry->get_adaptor( 'Mouse', 'Core', 'Slice' );

	my $newdb_obj = Bio::DBSQL::DB->new(-dbname =>'UnitrapTest');
	
	my $table_name = "testtable";
	my $column_name = "test_text";
	my $value = "testword";
	my $primary = $table_name."_id";

	my $data = qq{DROP TABLE IF EXISTS $table_name;
	CREATE TABLE IF NOT EXISTS $table_name (
	  $primary int(11) NOT NULL AUTO_INCREMENT,
	  $column_name varchar(40) NOT NULL,
	  PRIMARY KEY (`testtable_id`)
	); \nINSERT INTO $table_name SET $column_name  = \"$value\";};

	use Bio::File;
	my $file = Bio::File->writeDataToFile("testtable.sql",$tmpdir, $data,1);
	
	my $sec_value = "second insert";
	my $par = qq{INSERT INTO $table_name SET $column_name = \"$sec_value\"};
	my $newdbID = $newdb_obj->insert_set($par);
	
	my $condition = "$primary=$newdbID";
	my $uppar = qq{UPDATE $table_name SET $column_name = \"$sec_value\" WHERE $condition};
	my $updbID = $newdb_obj->update_set($uppar);
	
	my $condition = "$primary=$updbID";                                                                              
	my $selpar = qq{SELECT  $column_name FROM $table_name WHERE $condition};
	my $res = $newdb_obj->select_from_table($selpar);

	my $delpar = qq{DELETE FROM $table_name WHERE $condition};
	my $deldbID = $newdb_obj->delete_from_table($delpar);   
            
=cut


package Bio::DBSQL::DB;

use strict;
use DBI;
use Carp;
use Data::Dumper;
use File::Spec;
use vars qw(@ISA);
use Bio::EnsEMBL::Utils::Argument qw(rearrange);
use Bio::EnsEMBL::Utils::Exception qw(throw warning deprecate);
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::Root::Root; 
@ISA = qw(Bio::Root::Root);

require "$ENV{'Unitrap'}/unitrap_conf.pl";

my %conf =  %::conf;
my $debug = $conf{'global'}{'debug'};
my $debugSQL = $conf{'global'}{'debugSQL'};
my $mysql_path =$conf{'default'}{'mysql_path'};
my $tmpdir = $conf{'default'}{'tmp_dir'};

sub new {
  my ($caller) =shift @_;
  my $class = ref($caller) || $caller;
  my $self = $class->SUPER::new(@_);
  my (
    
    $host,
    $db,
    $user,
    $pass,
    $port,
    $sth
    )
    = rearrange( [
    'HOST', 
    'DBNAME',
    'USER',
    'PASS',
    'PORT',
    'STH'
    ],
    @_
    );
  
  unless($host){$host = $conf{'dbaccess'}{'host'}};
  unless($db){$db= $conf{'dbaccess'}{'dbname'}};
  unless($user){$user= $conf{'dbaccess'}{'user'}};
  unless($pass){$pass= $conf{'dbaccess'}{'pass'}};
  unless($port){$port= $conf{'dbaccess'}{'port'}};

  $host && $self->host($host);
  $user && $self->user($user);
  $pass && $self->pass($pass);
  $db && $self->dbname($db);
  $port && $self->port($port);

  my $dbh = DBI->connect("DBI:mysql:database=$db;host=$host;port=$port", $user, $pass);
  unless ($dbh){warning("Can't connect $db; I'll try to create\n");$dbh = $self->create_db} ;
  unless ($dbh){die "Can't create $db: ", $DBI::errst}
  $dbh && $self->db_connection($dbh);

  return $self;
}

sub db_connection {
    my ($self, $dbh) = @_;
    $self->{'db_connection'} = $dbh if $dbh;
    return $self->{'db_connection'};
}


sub host {
    my ($self, $host) = @_;
    $self->{'host'} = $host if $host;
    return $self->{'host'};
}
sub user {
    my ($self, $user) = @_;
    $self->{'user'} = $user if $user;
    return $self->{'user'};
}

sub dbname {
    my ($self, $dbname) = @_;
    $self->{'dbname'} = $dbname if $dbname;
    return $self->{'dbname'};
}

sub port {
    my ($self, $port) = @_;
    $self->{'port'} = $port if $port;
    return $self->{'port'};
}

sub pass {
    my ($self, $pass) = @_;
    $self->{'pass'} = $pass if $pass;
    return $self->{'pass'};
}

sub ensembl_connection {
    my ($self, $registry) = @_;
    $self->{'ensembl_connection'} = $registry if $registry;
    return $self->{'ensembl_connection'};
}

sub create_db () {
    my ($self) = @_;
    my $user  = $self->user;
    my $pass = $self->pass;
    my $host = $self->host;
    my $dbname = $self->dbname;
    my $port = $self->port;
    my $mysql = $mysql_path."mysqladmin";
    my $res = `$mysql -u $user -p$pass -h $host CREATE $dbname`;
    my $dbh = DBI->connect("DBI:mysql:database=$dbname;host=$host;port=$port", $user, $pass);
    $self->{'create_db'} = $self->db_connection($dbh);
    return $self->{'create_db'};
}

sub exec_import () {
    my ($self, $file) = @_;
    my $user  = $self->user;
    my $pass = $self->pass;
    my $host = $self->host;
    my $db = $self->dbname;
    my $res = system $mysql_path."mysql -u $user -p$pass -h $host $db < $file";
    unless ($res){$self->{'exec_import'} = 1}
    else{$self->{'exec_import'} = 0}
    return $self->{'exec_import'}; 
}

sub prepare_stmt {
    my ($self,$stmt) = @_;
    my $dbh = $self->db_connection;
    my $sth = $dbh->prepare($stmt)|| die "cannote prepare $stmt : $DBI::errstr";
    $self->{'prepare_stmt'} = $sth;
    return $self->{'prepare_stmt'};
}

sub insert_set {
    my ($self,$par)=@_;
 
    my $sth = $self->prepare_stmt($par);    
    my $dbID;
    $sth->execute() || die "Can't execute $par: ", $DBI::errst;
    $self->{'sth'} = $sth;
    $dbID = $sth->{'mysql_insertid'};
    $self->{'insert_set'} = $dbID;
    return $self->{'insert_set'};
}

sub update_set {
    my ($self, $par) = @_;
    my $sth = $self->prepare_stmt($par);
    my $dbID;
    $sth->execute() || die "Can't execute $par: ";
    $self->{'sth'} = $sth;
    $dbID = $sth->rows;
    $self->{'update_set'} = $dbID;
    return $self->{'update_set'};
}

sub select_from_table {
    my ($self, $par) = @_;
    my @array;
    my $sth = $self->prepare_stmt($par);
    $sth->execute() || die "Can't execute $par: ", $DBI::errst;
    $self->{'sth'} = $sth;
    $self->{'select_from_table'} = $sth->fetchrow_hashref();
    return $self->{'select_from_table'};
}

sub select_many_from_table {
    my ($self, $par) = @_;
    my @array;
    my $sth = $self->prepare_stmt($par);
    $sth->execute()|| die "Can't execute $par: ", $DBI::errst;
    $self->{'sth'} = $sth;
    while (my $href = $sth->fetchrow_hashref()){
  		push (@array, $href);
    }
    $self->{'select_many_from_table'} = \@array;
    return $self->{'select_many_from_table'};
}

sub sth {
    my ($self, $sth) = @_;
    $self->{'sth'} = $sth if $sth;
    return $self->{'sth'};
}

sub exec_dump () {
    my ($self, $no_data) = @_;
    
    my $attr;
    my $user  = $self->user;
    my $pass = $self->pass;
    my $host = $self->host;
    my $db = $self->dbname;
    if ($no_data) {
        $attr = "--no_data";
    }
    my $file = File::Spec->catfile($tmpdir,$db.".sql");	  
    eval{system $mysql_path."mysqldump -u $user -p$pass -h $host $attr $db > $file"};
    unless($@){$self->{'exec_dump'} = $db.".sql";}
    return $self->{'exec_dump'};
}

sub delete_from_table {
    my ($self,$par) = @_;
    my $sth = $self->prepare_stmt($par);
    my $dbID;
    $sth->execute()|| die "Can't execute $par: ", $DBI::errst;
    $dbID = $sth->rows;
    $self->{'delete_from_table'} = $dbID;
    return $self->{'delete_from_table'};
}


sub check_return {
    my ($self,$value, $table_name, $table_column) = @_;
    my $sth = $self->sth;
    my $r = $sth->rows;
    if ($r == 0) {
	$debug && print STDERR "DB:check_return  => CANNOT FIND THIS $value IN THE $table_name TABLE AND $table_column COLUMN\n";
    } 
    $self->{'_check_return'} = $r;
    return $self->{'_check_return'};
}


#sub exec_command_sql () {
#     my ($self, $path, $user, $pass, $db, $host, $file, $sql, $debug) = @_;
# 
#     $debug && print STDOUT $path."mysql -u $user -h $host -p$pass $db -e \"$sql\" > $file\n";
#     system $path."mysql -u $user -h $host -p$pass $db -e \"$sql\" > $file";
# }

#sub import_into_table () {
#     my ($self, $fields, $file) = @_;
#     my $user  = $self->user;
#     my $pass = $self->pass;
#     my $host = $self->host;
#     my $db = $self->dbname;
#     $debug && print "$mysql_path"."mysqlimport -u $user -p$pass -h $host $db -c $fields $file\n";
#     system $mysql_path."mysqlimport -u $user -p$pass -h $host $db -c $fields $file";
# }



1;
