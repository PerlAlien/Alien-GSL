package My::Builder::Windows;

use lib 'builder';
use parent 'My::Builder';

use Carp;

use File::chdir;

my %available = (
  '1.15' => {
    root => 'http://ultrafast.phy.uic.edu/',
    file => 'gsl-1-15-win.zip',
  },
);

sub available {
  my $self = shift;
  return $self->available_compiled(@_);
}

sub available_compiled {
  return \%available;
}

sub get_download_dir {
  my $self = shift;
  return 'share_dir';
}

sub gsl_make_install {
  my $self = shift;
  my ($dir) = @_;
  
  $self->config_data(location => 'share_dir');
  
  return 1;

}


1;

