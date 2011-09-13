package My::Builder;

use strict;
use warnings;

use lib 'builder';

use parent 'Module::Build';

use Carp;

use LWP::Simple;
use File::Temp ();
use File::chdir;
use Archive::Extract;

my $FTP_ROOT = 'ftp://ftp.gnu.org/gnu/gsl/';
my $CMD_GSL_CONFIG = 'gsl-config';

sub ACTION_code {
  my $self = shift;

  $self->args('Force', 1);

  if ($self->args('Force') or !$self->have_gsl_version) {
    my $tmpdir = File::Temp->newdir();

    my $dir = $self->fetch({dir => $tmpdir});

    my $status = $self->gsl_make_install($dir);
    print "Build/Install succeeded\n"; 
  }
  
  $self->SUPER::ACTION_code;
}

sub gsl_make_install {
  my $self = shift;

  carp "Build/Install of GSL not available on this system";

  return 0;
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

  my $dir = $opt->{dir} || File::Temp->newdir();
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

1;

