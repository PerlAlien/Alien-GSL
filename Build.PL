use strict;
use warnings;

use Alien::Base::ModuleBuild;

my $builder = Alien::Base::ModuleBuild->new(
  module_name => 'Alien::GSL',
  dist_abstract => 'Easy installation of the GNU Scientific Library',
  license => 'perl',
  configure_requires => {
    'Alien::Base::ModuleBuild' => 0,
    'Module::Build'            => '0.38',
  },
  test_requires => {
    'Test2::V0'   => 0,
    'Test::Alien' => 0,
  },
  requires => {
    'perl'        => '5.8.1',
    'parent'      => 0,
    'Alien::Base' => 0,
  },
  dist_author => 'Joel A. Berger <joel.a.berger@gmail.com>',
  alien_name => 'gsl',
  alien_repository => [
    {
      protocol => 'https',
      host     => 'ftp.gnu.org',
      location => '/gnu/gsl',
      pattern  => qr/^gsl-([\d\.]+)\.tar\.gz$/,
    },
  ],
  alien_isolate_dynamic => 1,
  meta_merge => {
    resources => {
      repository => 'https://github.com/PerlAlien/Alien-GSL',
      bugtracker => 'https://github.com/PerlAlien/Alien-GSL/issues',
    },
  },
);
$builder->create_build_script;


