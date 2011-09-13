package Alien::GSL;

use strict;
use warnings;

our $VERSION = 0.03;
$VERSION = eval $VERSION;

use Carp;

=head1 NAME 

Alien::GSL - Easy installation of the GSL library

=head1 DESCRIPTION

This module is meant to ease the install of the Gnu Scientific Library (GSL). It also provides version checking and build flags via the gsl-config utility.

=head1 SYNOPSIS

 use Alien::GSL;

 unless (Alien::GSL::require_gsl_version('1.15')) {
   die "This module requires at least GSL 1.15";
 }

 -- or perhaps --

 unless (Alien::GSL::have_gsl_version()) {
   Alien::GSL::install() or die "Cannot install GSL";
 }

=head1 EXPORTS

Currently this module does not export any functions or variables. Use instead the fully qualified symbol name, i.e. C<Alien::GSL::install()> or C<@Alien::GSL::SUPPORTED_OSES>.

=head1 INTERFACE STABILITY

This module is in an alpha state. The author hopes that major functionality will remain. Of particular note is the testability of the installation process. Further at this point only Linux platforms can download, build and install the GSL library. All other platforms will die during configure (C<perl Makefile.PL>) stage if GSL cannot be found. The author hopes to expand any other possible functionality.

=head2 require_gsl_version( [$version] );

A wrapper around C<have_gsl_version()> which (optionally) takes a number specifying a minimum GSL version, returns the GSL version if it is greater than or equal to that specified. Returns zero otherwise. May also be called with zero as the version parameter, or no parameter at all, in which case the behavior is the same as C<have_gsl_version()>.

=cut

sub require_gsl_version {

  my $required = shift;
  $required ||= 0;

  my $have = Alien::GSL::have_gsl_version();

  if ($required == 0) {
    return $have if $have;
  } 

  if ($have >= $required) {
    return $have;
  }

  return 0;

}

=head2 install ( [$version,] [$opts_hashref] );

Delegation function which calls the OS specific install function. Those functions may be called directly but as it is not recommended they are not listed in this document.

May take up to two arguments, a parameter which specifies the desired version to install (i.e. C<1.15> or C<1.1.1>) which must correspond exactly to the version number in the filename of the tarball. The final argument may be hash reference with options. Currently the available options are:

=over

=item *

C<CLEANUP> - if set to a true value the temporary folder create will be removed upon the completion of the script. This is the default.

=back

This function returns zero if the build/install fails and the version number (as returned by C<have_gsl_version()>) if the build/install succeeds.

On *nix systems this function can only be run with root permissions. Other operating systems (if supported) may require elevated permissions as well.

=cut

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



=head1 MODULE FUNCTIONS

These functions are basically a functional interface to the C<gsl-config> utility command.

=head2 gsl_prefix

Takes no options, returns the "GSL installation prefix".

=cut

sub gsl_prefix {
  my $prefix = qx/ gsl-config --prefix /;
  if ($?) {
    warn "Call to gsl-config --prefix failed: $!";
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
  
  if ($opts{cblas} == 0) {
    $call .= '-without-cblas';
  } 

  my $prefix = qx/ $call /;
  if ($?) {
    warn "Call to $call failed: $!";
  }

  return $prefix;
}

=head2 gsl_cflags

Takes no options, returns the "pre-processor and compiler flags".

=cut

sub gsl_cflags {
  my $cflags = qx/ gsl-config --cflags /;
  if ($?) {
    warn "Call to gsl-config --cflags failed: $!";
  }

  return $cflags;
}

=head2 gsl_version

Takes no options, returns "version information". This function is provided for symmetry, however, for flexibility and error handling the C<have_gsl_version()> function is recommended, especially in pre-install usage.

=cut

sub gsl_version {
  my $version = qx/ gsl-config --version /;
  if ($?) {
    warn "Call to gsl-config --version failed: $!";
  }

  return $version;
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


