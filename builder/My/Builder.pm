package My::Builder;

use strict;
use warnings;

use lib 'builder';

use parent 'Module::Build';

use Carp;

use File::Temp ();
use File::chdir;
use LWP::Simple;
use Archive::Extract;
use Capture::Tiny 'capture';

our $FTP_ROOT = 'ftp://ftp.gnu.org/gnu/gsl/';
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
  my $force = $self->args('Force');

  my $have_version = $self->have_gsl_version;

  if ($have_version and !$force) {
    $self->config_data( location => 'system' );
  } else  {
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

sub get_download_dir {
  my $self = shift;
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
  # fetch points to fetch_source unless overridden
  my $self = shift;
  return $self->fetch_source(@_);
}

sub local_exec_prefix {
  return '';
}

## Source Methods ##

=head2 available_source

Takes no parameters. In list context returns an array of the GSL tarballs available from the FTP folder given in the C<$FTP_ROOT> variable. In scalar context returns only the tarball with the highest version number. 

By default the C<$FTP_ROOT> and this tarball name may be joined to form a full download location. If the user specifies a different C<$FTP_ROOT>, be sure to include a trailing slash.

=cut

sub available_source {
  my $self = shift;

  my $index = get( $FTP_ROOT ) or croak "Error retrieving from $FTP_ROOT";

  my @tarballs = ($index =~ /(gsl-[\d\.]+\.tar\.gz)(?!\.sig)/g);
  croak "Could not find any tarballs on $FTP_ROOT" unless @tarballs;

  my %available = 
    map { 
      my $version = $1 if /gsl-([\d\.]+)\.tar\.gz/; 
      ($version => {root => $FTP_ROOT, file => $_ }) 
    }
    @tarballs;

  return \%available;

}

sub fetch_source {
  my $self = shift;
  my $opt = ref $_[0] ? shift : { @_ };

  my $dir = $opt->{dir};
  my $version = $opt->{version} || 0;

  my $available = $self->available_source();
  my @order_available = $self->order_available($available);

  my $file;
  if ($version) {
    unless (exists $available->{$version}) {
      croak "Could not find a GSL source for specified version: $version, available are @order_available";
    }
  } else {
    $version = $order_available[-1];
    print "Found newest source version: $version\n";
  }  

  $self->config_data( version => $version );
  $file = $available->{$version}{file};

  local $CWD = "$dir";

  print "Attempting to download: $FTP_ROOT$file\n";
  getstore( $FTP_ROOT . $file, $file );

  print "Extracting $file\n";
  my $ae = Archive::Extract->new( archive => $file );
  $ae->extract;

  (my $extract_dir = $file) =~ s/(gsl-[\d\.]+)\.tar\.gz/$1/;

  local $CWD = $extract_dir;

  return $CWD;
}

sub gsl_make_install {
  my $self = shift;
  my ($dir) = @_;

  local $CWD = $dir if $dir;
  print "Configuring GSL\n";
  # check that this folder contains a configure script
  croak "Folder does not contain AutoConf scripts" unless (-e 'configure');

  my $configure_command = $self->local_exec_prefix() . 'configure';
  if ($self->args('ShareDir')) {
    # for share_dir install get full path to share_dir
    local $CWD = $self->base_dir();
    push @CWD, 'share_dir';
    $configure_command .= " --prefix=$CWD";

    $self->config_data( location => 'share_dir' );

  } else {
  # for system-wide install check if running as root
    if ($< != 0) {
      print "Installing Alien::GSL requires root permissions or --ShareDir flag to use locally\n";
      return 0;
    }

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

  return 1;

}

## Pre-compiled Methods ##

sub available_compiled {
  my $self = shift;
  croak "Pre-compiled GSL libraries are not available for this system";
}

sub fetch_compiled {
  my $self = shift;
  my $opt = ref $_[0] ? shift : { @_ };

  my $dir = $opt->{dir};
  my $version = $opt->{version} || '1.15';

  my $available = $self->available_compiled();

  my ($root, $file);
  if (exists $available->{$version}) {
    $root = $available->{$version}{root};
    $file = $available->{$version}{file};
    $self->config_data( version => $version);
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

