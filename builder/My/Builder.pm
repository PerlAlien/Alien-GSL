package My::Builder;

use strict;
use warnings;

use lib 'builder';

use parent 'Module::Build';

use Carp;

use File::Temp ();
use File::chdir;

my $CMD_GSL_CONFIG = 'gsl-config';

sub get_download_dir {
  my $self = shift;
  my $temp_dir = $self->args('TempDir');
  if ($temp_dir) {
    return File::Temp->newdir(DIR => $temp_dir);
  } else {
    return File::Temp->newdir();
  }
}

sub ACTION_code {
  my $self = shift;

  if ($self->have_gsl_version) {
    $self->config_data( location => 'system' );
  }

  if ($self->args('Force') or !$self->have_gsl_version) {
    my $download_dir = $self->args('Dir') || $self->get_download_dir();

    my $fetch_args = {dir => $download_dir};
    if ($self->args('Version')) {
      $fetch_args->{version} = $self->args('Version');
    }

    my $dir = $self->fetch($fetch_args);

    if ( $self->gsl_make_install($dir) ) {
      print "Build/Install libgsl succeeded\n"; 
      if ($self->config_data('location') eq 'share_dir') {
        $self->set_share_dir_data();
      }
    } else {
      print "Build/Install libgsl failed\n";
    }
  }
  
  unless ($self->config_data('location')) {
    $self->config_data(location => 'unknown');
    warn "Error unknown location, please fix!";
  }

  $self->SUPER::ACTION_code;
}

sub set_share_dir_data {
  my $self = shift;

  local $CWD;
  push @CWD, qw'share_dir bin';
  my $base_command = $self->exec_prefix() . 'gsl-config';

  {
    # emulate gsl-config --libs

    my $command = $base_command . ' --libs';
    my $libs_str = qx/$command/;
    if ($?) {
      carp "Could not execute $command: $!";
      $libs_str = '';
    }

    chomp($libs_str);
    my @libs = grep { ! /^-L/ } split(/ /, $libs_str);
    $self->config_data( libs => \@libs );

  }

  {
    # emulate gsl-config --version

    my $command = $base_command . ' --version';
    my $version = qx/$command/;
    if ($?) {
      carp "Could not execute $command: $!";
      $version = '';
    }

    chomp($version);
    $self->config_data(version => $version);
  }
  
}

sub gsl_make_install {
  my $self = shift;

  carp "Build/Install of GSL not available on this system";

  return 0;
}

sub have_gsl_version {

  no warnings 'exec';

  my $gsl_version = qx/ $CMD_GSL_CONFIG --version /;
  if ($?) {
    $gsl_version = 0;
    carp "Cannot execute $CMD_GSL_CONFIG --version or you do not have GSL installed";
  }

  chomp $gsl_version;

  return $gsl_version;

}

sub exec_prefix {
  return '';
}

1;

