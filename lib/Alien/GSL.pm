package Alien::GSL;

use strict;
use warnings;

our $VERSION = 0.01;
$VERSION = eval $VERSION;

use Carp;
use LWP::Simple;
use File::Temp ();
use File::chdir;
use Archive::Extract;

our $FTP_ROOT = 'ftp://ftp.gnu.org/gnu/gsl/';
our $CMD_GSL_CONFIG_VERSION = 'gsl-config --version';

#once you create a branch in in Alien::GSL::install for a new OS
#enter that OS indicator (return from $^O) here
our @SUPPORTED_OSES = ( qw/ 
  linux
/ );

sub available {
  my $index = get( $FTP_ROOT );

  my @tarballs = ($index =~ /(gsl-[\d\.]+\.tar\.gz)(?!\.sig)/g);
  @tarballs = 
    map { $_->[0] }
    sort { 
      push @$a, 0 while @$a < 4;
      push @$b, 0 while @$b < 4;
      $a->[1] <=> $b->[1] ||
      $a->[2] <=> $b->[2] ||
      $a->[3] <=> $b->[3]
    }
    map { 
      my $version = $1 if /-([\d\.]+)\./; 
      [ $_ , split(/\./, $version) ]
    }
    @tarballs;

  if (wantarray) {
    return @tarballs;
  } else {
    return $tarballs[-1];
  }

}

sub have {

  no warnings 'exec';

  my $gsl_version = qx/ $CMD_GSL_CONFIG_VERSION /;
  if ($?) {
    $gsl_version = 0;
    carp "Cannot execute $CMD_GSL_CONFIG_VERSION or you do not have GSL installed";
  }

  return $gsl_version;

}

sub require_gsl_version {

  my $required = shift;
  my $have = Alien::GSL::have();

  if ($required == 0) {
    return $have if $have;
  } 

  if ($have >= $required) {
    return $have;
  }

  return 0;

}

sub install {
  # this function can be used to delegate to individual 
  # OS specific installers once they are created
  # this should test $^O. Be sure to update @SUPPORTED_OSES too!

  # perhaps setting CBLAS env variable should go here? is that OS indep?

  if ($^O eq 'linux') {
    goto &install_linux;
  } else {
    return 0;
  }
}

sub install_linux {

  # check if running as root
  if ($< != 0) {
    print "Must call Alien::GSL::install with root permissions\n";
    return 0;
  }

  my $opts = (@_ and ref $_[-1] eq 'HASH') ? pop : {};
  if (defined $opts->{CBLAS}) {
    $ENV{GSL_CBLAS_LIB} = $opts->{CBLAS};
  }

  my $version = shift;
  my $file;
  if (defined $version) {
    my @available = grep { /gsl-$version\.tar\.gz/ } Alien::GSL::available();
    if (@available > 1) {
      croak "Could not uniquely determine desired version. Files which match your specification (from GSL FTP) are: @available\n";
    } elsif (@available == 0) {
      croak "Could not find desired version on the GSL FTP ftp server";
    } else {
      $file = $available[0];
    }
  } else {
    $file = Alien::GSL::available();
  }

  my $dir = File::Temp->newdir( CLEANUP => defined $opts->{CLEANUP} ? $opts->{CLEANUP} : 1 );
  print "Using temporary directory: $dir\n";

  {

    local $CWD = "$dir";

    print "Attempting to download: $FTP_ROOT$file\n";
    getstore( $FTP_ROOT . $file, $file );

    print "Extracting $file\n";
    my $ae = Archive::Extract->new( archive => $file );
    $ae->extract;
    (my $extract_dir = $file) =~ s/(gsl-[\d\.]+)\.tar\.gz/$1/;

    {
      local $CWD = $extract_dir;

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
    }

    #back in base temporary directory $dir

  }

  return Alien::GSL::have();

}

sub gsl_prefix {
  my $prefix = qx/ gsl-config --prefix /;
  if ($?) {
    warn "Call to gsl-config --prefix failed: $!";
  }

  return $prefix;
}

sub gsl_libs {
  my %opts = @_;
  my $call = 'gsl-config --libs';

  if ($opts{cblas} == 0) {
    $call .= '-without-cblas';
  } 

  my $prefix = qx/ $call /;
  if ($?) {
    warn "Call to $call failed: $!";
  }

  return $prefix;
}

sub gsl_cflags {
  my $cflags = qx/ gsl-config --cflags /;
  if ($?) {
    warn "Call to gsl-config --cflags failed: $!";
  }

  return $cflags;
}

sub gsl_version {
  my $version = qx/ gsl-config --version /;
  if ($?) {
    warn "Call to gsl-config --version failed: $!";
  }

  return $version;
}

1;

__END__
__POD__

=head1 Alien::GSL - Easy installation of the GSL library.
