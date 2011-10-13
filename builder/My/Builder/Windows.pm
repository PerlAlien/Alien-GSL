package My::Builder::Windows;

use lib 'builder';
use parent 'My::Builder';

use Carp;

use File::chdir;
use LWP::Simple;
use Archive::Extract;

my $FILE_ROOT = 'http://ultrafast.phy.uic.edu/';
my $FILE      = 'gsl-1-15-win.zip';

sub get_download_dir {
  my $self = shift;
  return $self->{share_dir};
}

sub fetch {
  my $self = shift;
  my $opt = ref $_[0] ? shift : { @_ };

  my $dir = $opt->{dir};
  my $version = $opt->{version} || "";
  
  local $CWD = "$dir";
  
  print "Attempting to download: $FILE_ROOT$FILE\n";
  getstore( $FILE_ROOT . $FILE, $FILE );
  
  print "Extracting $FILE\n";
  my $ae = Archive::Extract->new( archive => $FILE );
  $ae->extract;

  print "Removing archive\n";
  $ae = undef;
  unlink($FILE) or carp "Could not remove archive $FILE";
  
  return $dir;

}

sub gsl_make_install {
  my $self = shift;
  my ($dir) = @_;
  
  $self->config_data(libs => 'share_dir');
  
  return 1;

}


1;

