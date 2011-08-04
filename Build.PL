use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
  module_name        => 'Alien::GSL',
  dist_version_from  => 'lib/Alien/GSL.pm',
  dist_author        => 'Joel Berger <joel.a.berger@gmail.com>',
  license            => 'perl',
  requires => {
    'perl'              => '5.008',
  #  'File::ShareDir'    => 0,
  #  'File::Spec'        => 0,
  },
  configure_requires => {
    'perl'              => '5.008',
  #  'File::ShareDir'    => 0,
  #  'File::Spec'        => 0,
  #  'File::Path'        => 0,
  #  'File::Temp'        => 0,
  #  'ExtUtils::CBuilder'=> 0,
  #  'ExtUtils::Command' => 0,
  #  'ExtUtils::Liblist' => 0,
  #  'File::Fetch'       => 0,
  #  'Digest::SHA'       => 0,
    'Archive::Extract'  => 0,
  },
  build_requires => {
    'perl'              => '5.008',
    'Test::More'        => 0,
  #  'File::ShareDir'    => 0,
  #  'File::Spec'        => 0,
  #  'File::Path'        => 0,
  #  'File::Temp'        => 0,
  #  'File::Copy'        => 0,
  #  'ExtUtils::CBuilder'=> 0,
  #  'ExtUtils::Command' => 0,
  #  'ExtUtils::Liblist' => 0,
  #  'File::Fetch'       => 0,
  #  'Digest::SHA'       => 0,
    'Archive::Extract'  => 0,
  },
  #share_dir          => 'sharedir',
  #add_to_cleanup     => [ 'Alien-GSL-*', 'build_done' ],
  create_readme      => 1,
  meta_merge => {
    resources  => {
      type => "git",
      url  => "git://github.com:jberger/Alien-GSL.git",
      web  => "http://github.com/jberger/Alien-GSL",
    }
  },
  get_options => { srctarball =>  { type  => '=s' } },  # option: Build.PL --srctarball=<url_or_filename>
);
