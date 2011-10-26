use strict;
use warnings;

use lib 'builder';

use Module::Build;

my %conf_req;

BEGIN {

  %conf_req = (
    'perl'                  => '5.008',
    'lib'                   => 0,
    'parent'                => 0,
    'Module::Build'         => '0.38',
    'Carp'                  => 0,
    'Scalar::Util'          => 0,
    'File::Temp'            => 0,
    'File::chdir'           => 0,
    'HTTP::Tiny'            => 0,
    'Net::FTP'              => 0,
    'Archive::Extract'      => 0,
    'Capture::Tiny'         => 0,
    'File::Spec::Functions' => 0,
    'Sort::Versions'        => 0,
  );

  my @failed = 
    grep { ! Module::Build->check_installed_version($_, $conf_req{$_}) } 
    grep { $_ ne 'perl' } 
    keys %conf_req;

  if (@failed) {
    local $" = ' ';
    my $message = "Some needed modules are missing or must be upgraded before configuring Alien::GSL.\nThose modules are:\t@failed\n";
    if ($ENV{AUTOMATED_TESTING}) {
      print $message;
      exit 0;
    } else {
      print $message;
      exit 1;
      ## personnally I like die better, but it adds a "BEGIN failed--compilation aborted" message which clutters up the warning the user sees
      #die $message;
    }
  }

}

my $builder_class = 'My::Builder';
if ( Module::Build->is_unixish() ) {
  $builder_class .= '::Unix';
}
if ( Module::Build->is_windowsish() ) {
  $builder_class .= '::Windows';
}
print "Using build class $builder_class\n";

#from UNIVERSAL::require; keeping this line in case A::G switches back to it
#$builder_class->require() or die "Could not load $builder_class";
eval "require $builder_class" or die "Could not load $builder_class";

my $builder = $builder_class->new(
  module_name        => 'Alien::GSL',
  dist_version_from  => 'lib/Alien/GSL.pm',
  dist_author        => 'Joel Berger <joel.a.berger@gmail.com>',
  license            => 'perl',
  requires => {
    'perl'            => '5.008',
    'Carp'            => 0,
    'File::ShareDir'  => 0,
    'File::chdir'     => 0,
    'List::MoreUtils' => 0,
  },
  configure_requires => \%conf_req,
  build_requires => \%conf_req,
  get_options => {
    'Dir'      => {type => '=s'},
    'TempDir'  => {type => '=s'},
    'Force'    => {default => 0},
    'ShareDir' => {default => 0},
    'Version'  => {type => '=s', default => 0},
    'GSLCheck' => {default => 0},
  },
  share_dir   => 'share_dir',
  meta_merge => {
    resources  => {
      repository => #{
      #  type => "git",
      #  url  => "git://github.com:jberger/Alien-GSL.git",
      #  web  => 
        "http://github.com/jberger/Alien-GSL",
      #},
    },
  },
);

$builder->create_build_script;

