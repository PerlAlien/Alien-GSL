use strict;
use warnings;

use lib 'builder';

use My::Builder::Linux;

my $builder = My::Builder::Linux->new(
  module_name        => 'Alien::GSL',
  dist_version_from  => 'lib/Alien/GSL.pm',
  dist_author        => 'Joel Berger <joel.a.berger@gmail.com>',
  license            => 'perl',
  requires => {
    'perl'              => '5.008',
  },
  configure_requires => {
    'perl'              => '5.008',
    'Archive::Extract'  => 0,
    'parent'		=> 0,
  },
  build_requires => {
    'perl'              => '5.008',
    'Test::More'        => 0,
    'Archive::Extract'  => 0,
  },
  meta_merge => {
    resources  => {
      Type => "git",
      Url  => "git://github.com:jberger/Alien-GSL.git",
      Web  => "http://github.com/jberger/Alien-GSL",
    }
  },
);

$builder->create_build_script;

