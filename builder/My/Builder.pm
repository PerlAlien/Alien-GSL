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
use File::Spec::Functions 'catdir';
use Sort::Versions;

our $FTP_SERVER = 'ftp.gnu.org';
our $FTP_FOLDER = '/gnu/gsl';
our $CMD_GSL_CONFIG = 'gsl-config';

## Generic Methods ##

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

  if ($self->is_share_dir_populated()) {
    print "Found GSL in share_dir\n";

    unless ($self->config_data('location')) {
      $self->config_data('location' => 'share_dir');
    }

    unless ( $self->config_data('location') eq 'share_dir' and $self->config_data( 'libs' ) ) {
      $self->parse_rewrite_pc_file();
    }

  } elsif ( $have_version and ! $self->args('Force') and ! $self->args('ShareDir') ) {
    print "Found system-wide installation of GSL. This will be used by Alien::GSL.\n";

    $self->config_data( location => 'system' );
  } else  {
    my $download_dir = $self->get_download_dir();

    my $extract_dir = $self->fetch($download_dir, $self->args('Version'));

    if ( $self->gsl_make_install($extract_dir) ) {
      print "Build/Install libgsl succeeded\n"; 
      if ($self->config_data('location') eq 'share_dir') {
        #$self->set_share_dir_data();
        $self->parse_rewrite_pc_file();
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

#sub ACTION_install {
#  my $self = shift;

#  $self->SUPER::ACTION_install();

#  if ($self->config_data('location') eq 'share_dir') {
#    $self->rewrite_pc_file();
#  }
#}

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

sub available {
  # available points to available_source unless overridden
  my $self = shift;
  return $self->available_source(@_);
}

sub fetch {
  my $self = shift;
  my ($dir, $version) = @_;

  my $available = $self->available();
  my @order_available = sort versioncmp keys %$available;

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
    or croak "Cannot connect to $FTP_SERVER: $@";

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

sub is_share_dir_populated {
  my $self = shift;

  local $CWD = 'share_dir';
  return 0 unless (-d 'lib');

  push @CWD, 'lib';

  opendir(my $dh, $CWD);
  my @found = grep { /gsl/ } readdir($dh);

  return !! @found;
}

sub parse_rewrite_pc_file {
  my $self = shift;

  my $path = catdir(
    $self->install_destination('lib'),
    qw/auto share dist Alien-GSL/,
  );

  local $CWD = 'share_dir';
  push @CWD, qw/lib pkgconfig/;

  open my $fh, '<', 'gsl.pc' or croak "Could not open gsl.pc (read): $!";
  my @pc = <$fh>;
  chomp @pc;

  open $fh, '>', 'gsl.pc' or croak "Could not open gsl.pc (write): $!";

  my $old_path = '';
  my $lib_path = catdir( $path, 'lib');
  my @libs;

  my $inc_path = catdir( $path, 'include');
  my @inc;

  my %pc_vars;

  foreach (@pc) {
    if (/^prefix=(.*)/) {
      $old_path = $1;
	  #windows compat
	  $old_path =~ s'\\'\\\\'g;
      print $fh "prefix=$path\n";
    } elsif (/^exec_prefix=/) {
      print $fh "exec_prefix=$path\n";
    } elsif (/^libdir=/) {
      print $fh "libdir=$lib_path\n";
    } elsif (/^includedir=/) {
      print $fh "includedir=$inc_path\n";
    } elsif ( s/Libs:\s*// ) {
      @libs = grep {! /^-L$old_path/ } split;
      print $fh "Libs: -L$lib_path " . join(' ', @libs) . "\n";
    } elsif ( s/Cflags:\s*// ) {
      @inc = grep { ! /^-I$old_path/ } split;
      print $fh "Cflags: -I$inc_path " . join(' ', @inc) . "\n";
    } else {
      if (/=/) {
        my ($key, $val) = split /\s*=\s*/, $_ , 2;
        $pc_vars{$key} = $val;
      }
      print $fh "$_\n";
    }
  }

  for (@libs, @inc) {
    if ( /\$\{([^\}]+)\}/ and exists $pc_vars{$1} ) {
      my $rep = $pc_vars{$1};
      s/\$\{$1\}/$rep/;
    }
  }

  $self->config_data( libs => \@libs );
  $self->config_data( inc => \@inc );
}

sub add_share_dir_contents_to_cleanup {
  # not yet implemented
  return 1;
}

1;

