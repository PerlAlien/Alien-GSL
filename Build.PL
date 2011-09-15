use strict;
use warnings;

use lib 'builder';

my $builder_class = 'My::Builder';
if ($^O eq 'linux') { 
  $builder_class .= '::Unix';
}

eval "require $builder_class" or die "Could not load $builder_class";

my $builder = $builder_class->new(
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

