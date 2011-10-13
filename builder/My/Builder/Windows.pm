package My::Builder::Windows;

use lib 'builder';
use parent 'My::Builder';

use Carp;

use File::chdir;
use LWP::Simple;
use Archive::Extract;

my $FILE_ROOT = 'http://ultrafast.phy.uic.edu/';
my $FILE      = 'gsl-1-15-win.zip';

sub get_gsl {
  my $self = shift;
  
}

sub fetch {
  my $self = shift;
  my $opt = ref $_[0] ? shift : { @_ };

  my $dir = $opt->{dir} || File::Temp->newdir();
  my $version = $opt->{version} || "";
  
  local $CWD = "$dir";
  
  print "Attempting to download: $FILE_ROOT$FILE\n";
  getstore( $FILE_ROOT . $FILE, $FILE );
  
  print "Extracting $FILE\n";
  my $ae = Archive::Extract->new( archive => $FILE );
  $ae->extract;
  
  return $dir;

}

sub gsl_make_install {
  my $self = shift;
  my ($dir) = @_;
  
  $self->share_dir($dir);
  
  return 1;

}


1;

