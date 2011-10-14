package My::Builder::Unix;

use lib 'builder';
use parent 'My::Builder';

use Carp;

use File::chdir;
use Archive::Extract;
use LWP::Simple;

my $FTP_ROOT = 'ftp://ftp.gnu.org/gnu/gsl/';

sub gsl_make_install {
  my $self = shift;
  my ($dir) = @_;

  local $CWD = $dir if $dir;
  print "Configuring GSL\n";
  # check that this folder contains a configure script
  croak "Folder does not contain AutoConf scripts" unless (-e 'configure');

  my $configure_command = './configure';
  if ($self->args('ShareDir')) {
    # for share_dir install get full path to share_dir
    local $CWD = $self->base_dir();
    push @CWD, $self->{share_dir};
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

=head2 available

Takes no parameters. In list context returns an array of the GSL tarballs available from the FTP folder given in the C<$FTP_ROOT> variable. In scalar context returns only the tarball with the highest version number. 

By default the C<$FTP_ROOT> and this tarball name may be joined to form a full download location. If the user specifies a different C<$FTP_ROOT>, be sure to include a trailing slash.

=cut

sub available {
  my $self = shift;

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

sub fetch {
  my $self = shift;
  my $opt = ref $_[0] ? shift : { @_ };

  my $dir = $opt->{dir};
  my $version = $opt->{version} || "";

  my $file;
  if ($version) {
    my @available = grep { /gsl-$version\.tar\.gz/ } $self->available();
    if (@available > 1) {
      croak "Could not uniquely determine desired version. Files which match your specification (from GSL FTP) are: @available\n";
    } elsif (@available == 0) {
      croak "Could not find desired version on the GSL FTP ftp server";
    } else {
      $file = $available[0];
    }
  } else {
    $file = $self->available();
  }  

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

1;

