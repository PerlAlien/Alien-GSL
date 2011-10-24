package My::Builder;

use strict;
use warnings;

use lib 'builder';

use parent 'Module::Build';

use Carp;

use Scalar::Util 'blessed';
use File::Temp ();
use File::chdir;
use HTTP::Tiny;
use Net::FTP;
use Archive::Extract;
use Capture::Tiny 'capture';

our $FTP_SERVER = 'ftp.gnu.org';
our $FTP_FOLDER = '/gnu/gsl';
our $CMD_GSL_CONFIG = 'gsl-config';

## Generic Methods ##

#sub new {
#  my $class = shift;

#  my $self = $class->SUPER::new(@_);

#  bless($self, $class);

  # default to a share_dir install
  # My::Builder::Unix overrides this to make system default

  #$self->config_data(location => 'share_dir');

#  return $self;
#}

sub have_gsl_version {

  no warnings 'exec';
  
  my $gsl_version;
  
  capture {
    $gsl_version = qx/ $CMD_GSL_CONFIG --version /;
  };
  
  if ($?) {
    $gsl_version = 0;
    warn "Cannot execute '$CMD_GSL_CONFIG --version' or you do not have GSL installed\n";
  }

  chomp $gsl_version;

  return $gsl_version;

}

sub ACTION_code {
  my $self = shift;

  my $have_version = $self->have_gsl_version;

  if ( $have_version and ! $self->args('Force') and ! $self->args('ShareDir') ) {
    print "Found system-wide installation of GSL. This will be used by Alien::GSL.\n";

    $self->config_data( location => 'system' );
  } else  {
    my $download_dir = $self->get_download_dir();

    my $dir = $self->fetch($download_dir, $self->args('Version'));

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

sub get_download_dir {
  my $self = shift;

  if ($self->args('Dir')) {
    return $self->args('Dir');
  }

  my $temp_dir = $self->args('TempDir');
  if ($temp_dir) {
    return File::Temp->newdir(DIR => $temp_dir);
  } else {
    return File::Temp->newdir();
  }
}

#sub gsl_make_install {
#  my $self = shift;
#  carp "Build/Install of GSL not available on this system";
#  return 0;
#}

sub order_available {
  my $self = shift;
  my ($available) = @_;
  croak "must supply one argument to order_available" unless $available;

  my @order = 
    map { $_->[0] }
    sort { 
      push @$a, 0 while @$a < 4;
      push @$b, 0 while @$b < 4;
      $a->[1] <=> $b->[1] ||
      $a->[2] <=> $b->[2] ||
      $a->[3] <=> $b->[3]
    }
    map {  
      [ $_, split /\./ ]
    }
    keys %$available;

  return @order;
}

sub available {
  # available points to available_source unless overridden
  my $self = shift;
  return $self->available_source(@_);
}

sub fetch {
  my $self = shift;
  my ($dir, $version) = @_;

  my $available = $self->available();
  my @order_available = $self->order_available($available);

  if ($version) {
    unless (exists $available->{$version}) {
      croak "Could not find a GSL version: $version, available are @order_available";
    }
  } else {
    $version = $order_available[-1];
    print "Found newest version: $version\n";
  } 

  my $from = $available->{$version}{from};
  my $file = $available->{$version}{file};
  $self->config_data( version => $version );

  local $CWD = "$dir";

  print "Attempting to download: $file\n";
  if (blessed $from and $from->isa('Net::FTP') ) {
    $from->binary();
    $from->get( $file ) or croak "Download failed: " . $from->message();
  } else {
    my $response = HTTP::Tiny->new->mirror( $from . $file, $file );
    croak "Download failed: " . $response->{reason} unless $response->{success};
  }

  print "Extracting $file\n";
  my $ae = Archive::Extract->new( archive => $file );
  $ae->extract;

  print "Removing archive\n";
  $ae = undef;
  unlink($file) or carp "Could not remove archive $file";

  my $extract_dir = $CWD;
  if ($file =~ /(gsl-[\d\.]+)\.tar\.gz/) {
    if (-d $1) {
      local $CWD = $1;
      $extract_dir = $CWD;
    }
  }

  return $extract_dir;
}

sub local_exec_prefix {
  return './';
}

## Source Methods ##

sub available_source {
  my $self = shift;

  my $ftp = Net::FTP->new($FTP_SERVER, Debug => 0)
    or croak "Cannot connect to some.host.name: $@";

  $ftp->login() or croak "Cannot login ", $ftp->message;

  $ftp->cwd($FTP_FOLDER) or croak "Cannot change working directory ", $ftp->message;

  my @tarballs = grep {/^gsl-[\d\.]+\.tar\.gz$/} $ftp->ls();
  croak "Could not find any tarballs at $FTP_SERVER$FTP_FOLDER" unless @tarballs;

  my %available = 
    map { 
      my $version = $1 if /gsl-([\d\.]+)\.tar\.gz/; 
      ($version => {from => $ftp, file => $_ }) 
    }
    @tarballs;

  return \%available;

}

sub gsl_make_install {
  my $self = shift;
  my ($dir) = @_;

  local $CWD = $dir if $dir;
  print "Configuring GSL\n";
  # check that this folder contains a configure script
  croak "Folder does not contain AutoConf scripts" unless (-e 'configure');

  my $configure_command = $self->local_exec_prefix() . 'configure';
  my $is_root = ($< == 0);

  if ($self->args('ShareDir') or ! $is_root) {
    print "Using install method: File::ShareDir\n";

    $self->config_data( location => 'share_dir' );

    # for share_dir install get full path to share_dir
    local $CWD = $self->base_dir();
    push @CWD, 'share_dir';
    $configure_command .= " --prefix=$CWD";

  } else {

    print "Using install method: system-wide\n";

    $self->config_data( location => 'system' );

  }

  system( $configure_command );
  if ($?) {
    print "Configure ($configure_command) Failed!\n";
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

  if ( $self->args('GSLCheck') ) {
    print "Checking GSL compile using 'make check'\n";
    system( 'make check' );
    if ($?) {
      print "GSL check (make check) Failed!\n";
      return 0;
    }
  }

  return 1;

}

## Pre-compiled Methods ##

sub available_compiled {
  my $self = shift;
  croak "Pre-compiled GSL libraries are not available for this system";
}

## System Install Methods ##

## ShareDir Methods ##

sub set_share_dir_data {
  my $self = shift;

  #local $CWD;
  #push @CWD, qw'share_dir bin';
  #my $base_command = $self->local_exec_prefix() . 'gsl-config';

  #{
    # emulate gsl-config --libs

    #my $command = $base_command . ' --libs';
    #my $libs_str = qx/$command/;
    #if ($?) {
    #  carp "Could not execute $command: $!";
    #  $libs_str = '';
    #}

    #chomp($libs_str);
    #my @libs = grep { ! /^-L/ } split(/ /, $libs_str);
    my @libs = qw( -lgsl -lgslcblas -lm ); # hard code libs rather than determine
    $self->config_data( libs => \@libs );

  #}
  
}

1;

