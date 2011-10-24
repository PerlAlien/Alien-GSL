package My::Builder::Windows;

use lib 'builder';
use parent 'My::Builder';

use Carp;

use File::chdir;

my %available = (
  '1.15' => {
    from => 'http://ultrafast.phy.uic.edu/',
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

sub have_gsl_version {
  return 0;
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

sub local_exec_prefix {
  return '';
}


1;

