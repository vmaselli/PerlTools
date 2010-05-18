=head1 Bio::File

=head2 Authors

=head3 Modified by

             Vincenza Maselli
             v.maselli@ucl.ac.uk

=head3 Created by

              Guglielmo Roma
              guglielmoroma@libero.it

=head2 Description
        
             This module have method to handle with files
             
=head2 Example

	  my $file = Bio::File->writeDataToFile("my file","my dir", "my data", 1);
	  my $read_content = Bio::Unitrap::File->readFileData($file,"my dir",1);
	  my $file = Bio::File->appendDataToFile($file,"my dir", "my new data",, 1);

	  my %hash = Bio::File->fromFastaFileToHash($file,$dir,1);
	  my %hash = Bio::File->fromFastaFormatToHash($read_content,1); 
            
=cut


package Bio::File;

use strict;
use File::Spec;

sub readFileData () {
    my ($self, $file, $dir,$debug) = @_;	
	my $content;
	my $file_path = File::Spec->catfile($dir,$file);
	open (FILE, ($file_path)) || return undef ;
	while (defined (my $line=<FILE>)) {$content .= $line;}
	close (FILE);
	return $content;
}

sub writeDataToFile () {
    my ($self, $file,$dir, $data, $debug) = @_;
	my $file_path = File::Spec->catfile($dir,$file);
	open (FILE, ">$file_path")|| return undef;
	print FILE "$data";
	close (FILE);
    return $file;
}

sub appendDataToFile () {
    my ($self, $file, $dir,$data, $debug) = @_;
	my $file_path = File::Spec->catfile($dir,$file);
	open (FILE, ">>$file_path")|| return undef;
	print FILE "$data";
	close (FILE);
    return $file;	
}

sub fromFastaFileToHash () {
	my ($self, $file,$dir, $debug) = @_;
	my $file_path = File::Spec->catfile($dir,$file);
	my $cnt = $self->readFileData ($file, $dir, $debug);	
	my %hash = $self->fromFastaFormatToHash ($cnt, $debug);
	return %hash;
}

# Convert a multifasta text in a hash of sequences. the Key is the sequence name and the value is the sequence
sub fromFastaFormatToHash () {
    my ($self, $text, $debug) = @_;	
	my @array = split (/>/, $text);
	my ($sequence, %hash);
	foreach my $seq (@array) {
		if ($seq) {
			my @lines = split ("\n", $seq);
			my $description = shift @lines;
			
			my @words = split (" ", $description);
			my $name = $words[0];
			my $desc = $words[1];
			
			foreach my $line (@lines) {$sequence = $sequence.$line;}
			
			$name =~ s/\,//g;
			
			$hash {$name}{'sequence'} = $sequence;
			$hash {$name}{'desc'} = $desc;
			
			undef $name;
			undef $sequence;
			undef $desc;
		}
	}
	return %hash; 
}

1;