package My::Builder::Unix;

use lib 'builder';
use parent 'My::Builder';

use Carp;

use File::chdir;

sub gsl_make_install {
  my $self = shift;
  my ($dir) = @_;

  local $CWD = $dir if $dir;

  # check that this folder contains a configure script
  croak "Folder does not contain AutoConf scripts" unless (-e 'configure');

  # check if running as root
  if ($< != 0) {
    print "Installing Alien::GSL requires root permissions\n";
    return 0;
  }

  print "Configuring GSL\n";
  system( './configure' );
  if ($?) {
    print "Configure Failed!\n";
    return 0;
  }

  print "Building GSL\n";
  system( 'make' );
  if ($?) {
    print "Build (make) Failed!\n";
    return 0;
  }

  print "Installing GSL\n";
  system( 'make install' );
  if ($?) {
    print "Install (make install) Failed!\n";
    return 0;
  }

  return 1;

}

1;

