use strict;
use warnings;

use lib 'builder';

use Devel::CheckOS 'os_is';
use UNIVERSAL::require;

my $builder_class = 'My::Builder';
if ( os_is('Unix') ) {
  $builder_class .= '::Unix';
}
if ( os_is('MicrosoftWindows') ) {
  $builder_class .= '::Windows';
}
print "Using build class $builder_class\n";

$builder_class->require() or die "Could not load $builder_class";

my $builder = $builder_class->new(
  module_name        => 'Alien::GSL',
  dist_version_from  => 'lib/Alien/GSL.pm',
  dist_author        => 'Joel Berger <joel.a.berger@gmail.com>',
  license            => 'perl',
  requires => {
    'perl'           => '5.008',
    'File::ShareDir' => 0,
  },
  configure_requires => {
    'perl'               => '5.008',
    'parent'             => 0,
    'Devel::CheckOS'     => 0,
    'UNIVERSAL::require' => 0,
  },
  build_requires => {
    'perl'              => '5.008',
    'Test::More'        => 0,
    'Archive::Extract'  => 0,
    'File::chdir'       => 0,
    'LWP::Simple'       => 0,
	'Capture::Tiny'     => 0,
  },
  get_options => {
    'Dir'      => {type => '=s'},
    'TempDir'  => {type => '=s'},
    'Force'    => {default => 0},
    'ShareDir' => {default => 0},
    'Version'  => {default => 0},
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

