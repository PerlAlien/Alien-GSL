package Alien::GSL;

use strict;
use warnings;

our $VERSION = 0.03;
$VERSION = eval $VERSION;

use Carp;
use Alien::GSL::ConfigData;
use File::ShareDir 'module_dir';
use File::chdir;

# if $location eq share_dir then the module was built in share_dir mode 

my $share_dir = (Alien::GSL::ConfigData->config('location') eq 'share_dir') ? module_dir('Alien::GSL') : '';

=head1 NAME 

Alien::GSL - Easy installation of the GSL library

=head1 DESCRIPTION

This module is meant to ease the install of the Gnu Scientific Library (GSL). It also provides version checking and build flags via the gsl-config utility.

=head1 SYNOPSIS

 use Alien::GSL;

 unless (Alien::GSL::require_gsl_version('1.15')) {
   die "This module requires at least GSL 1.15";
 }

=head1 INSTALLATION

L<Alien::GSL> uses the L<Module::Build> system for installation. Therefore the usual build process is

 perl Build.PL
 ./Build
 ./Build test
 ./Build install

It will try (at a minimum) to detect if the GSL library is installed on the local system. If not it will attempt, if possible, to download/build/install it. This build process will likely require the C<Build> script to be run with root privaledges. Future versions of L<Alien::GSL> may try to avoid this problem. This is not necessary if the library is already installed on the system.

=head2 PerlBrew/CPANminus

If using L<perlbrew> to manage local installations of the Perl interpreter, I believe that 

 cpanm --sudo Alien::GSL

will work more correctly than either of

 sudo cpanm Alien::GSL
 sudo cpan Alien::GSL

=head1 EXPORTS

Currently this module does not export any functions or variables. Use instead the fully qualified symbol name, i.e. C<Alien::GSL::gsl_version()>.

=head1 INTERFACE STABILITY

This module is in an alpha state. The author hopes that major functionality will remain. The module now uses L<Module::Build> which allows the install functionality (download, build, install) to be platform specific and separated from the usage functionality described in the L<MODULE FUNCTIONS> section.

=head1 MODULE FUNCTIONS

These functions are basically a functional interface to the C<gsl-config> utility command.

=head2 gsl_version

Takes no options, returns the version number of the installed GSL library.

=cut

sub gsl_version {
  my $version;

  if ($share_dir) {
    $version = Alien::GSL::ConfigData->config('version');
  } else {
    $version = qx/ gsl-config --version /;
    if ($?) {
      carp "Call to gsl-config --version failed: $!";
      $version = '';
    }

    chomp($version);
  }

  return $version;
}

=head2 require_gsl_version( [$version] );

A wrapper around C<gsl_version()> which (optionally) takes a number specifying a minimum GSL version, returns the GSL version if it is greater than or equal to that specified. Returns zero otherwise. May also be called with zero as the version parameter, or no parameter at all, in which case the behavior is the same as C<gsl_version()>.

=cut

sub require_gsl_version {

  my $required = shift;
  $required ||= 0;

  my $have = gsl_version();

  if ($required == 0) {
    return $have if $have;
  } 

  if ($have >= $required) {
    return $have;
  }

  return 0;

}

=head2 gsl_prefix

Takes no options, returns the "GSL installation prefix".

=cut

sub gsl_prefix {
  my $prefix;

  if ($share_dir) {

  } else {
    $prefix = qx/ gsl-config --prefix /;
    if ($?) {
      carp "Call to gsl-config --prefix failed: $!";
      $prefix = '';
    }

    chomp($prefix);
  }

  return $prefix;
}

=head2 gsl_libs( [opts hash or hash reference] )

Takes an optional hash or hash reference, returns "library linking information". A hash key C<cblas>, whose value is false will return the "library linking information, without cblas", though by default the cblas information is included.

=cut

sub gsl_libs {
  my %opts = (ref $_[0] eq 'HASH') ? %{ $_[0] } : @_;

  my $call = 'gsl-config --libs';

  if (! defined $opts{cblas}) {
    $opts{cblas} = 1;
  }
  
  unless ($opts{cblas}) {
    $call .= '-without-cblas';
  } 

  my $libs;
  if ($share_dir) {

    my @libs = Alien::GSL::ConfigData->config('libs');

    unless ($opts{cblas}) {
      @libs = grep { ! /cblas/ } @libs;
    }

    {
      local $CWD = $share_dir;
      push @CWD, 'lib';
      unshift @libs, '-L' . $CWD;
    }

    $libs = join(' ', @libs);
  } else {

    $libs = qx/ $call /;
    if ($?) {
      carp "Call to $call failed: $!";
    }

    chomp($libs);
  }

  return $libs;
}

=head2 gsl_cflags

Takes no options, returns the "pre-processor and compiler flags".

=cut

sub gsl_cflags {
  my $cflags;

  if ($share_dir) {
    local $CWD = $share_dir;
    push @CWD, 'include';
    $cflags = '-I' . $CWD;

  } else {

    my $command = 'gsl-config --cflags';
    $cflags = qx/$command/;
    if ($?) {
      carp "Call to $command failed: $!";
    }

    chomp($cflags);
  }

  return $cflags;
}

=head1 SEE ALSO

=over

=item L<Math::GSL>

=item L<Math::GSLx::ODEIV2>

=item L<GSL|http://www.gnu.org/software/gsl/>

=item L<PDL>, L<website|http://pdl.perl.org> 

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Alien-GSL>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;


