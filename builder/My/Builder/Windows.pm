package My::Builder::Windows;

use lib 'builder';
use parent 'My::Builder';

use Carp;

use File::chdir;
use LWP::Simple;
use Archive::Extract;

my %available = (
  '1.15' => {
    root => 'http://ultrafast.phy.uic.edu/',
    file => 'gsl-1-15-win.zip',
  },
);

sub get_download_dir {
  my $self = shift;
  return $self->{share_dir};
}

sub fetch {
  my $self = shift;
  my $opt = ref $_[0] ? shift : { @_ };

  my $dir = $opt->{dir};
  my $version = $opt->{version} || '1.15';

  my ($root, $file);
  if (exists $available{$version}) {
    $root = $available{$version}{root};
    $file = $available{$version}{root};
    $self->config_data('gsl_version' => $version);
  } else {
    croak "Could not find a GSL version $version available"; 
  }
  
  local $CWD = "$dir";
  
  print "Attempting to download: $root$file\n";
  getstore( $root . $file, $file );
  
  print "Extracting $file\n";
  my $ae = Archive::Extract->new( archive => $file );
  $ae->extract;

  print "Removing archive\n";
  $ae = undef;
  unlink($file) or carp "Could not remove archive $file";
  
  return $dir;

}

sub gsl_make_install {
  my $self = shift;
  my ($dir) = @_;
  
  $self->config_data(location => 'share_dir');
  
  return 1;

}


1;

