use 5.008000;
use ExtUtils::MakeMaker;

use lib 'lib';
use Alien::GSL;

my $gsl_version = Alien::GSL::have();
if ($gsl_version == 0) {
  # if GSL not found, attempt to install if supported
  if (grep {$^O eq $_} @Alien::GSL::SUPPORTED_OSES) {
    $gsl_version = Alien::GSL::install();
  }

  # check if successful
  if ($gsl_version) {
    print "GSL version $gsl_version installed!\n";
  } else {
    print <<MESSAGE;
GSL could not be installed. Perhaps Alien::GSL does not yet support your operating system (currently supports: @Alien::GSL::SUPPORTED_OSES), in which case you are welcome to contribute at this module's GitHub repository. Otherwise the build has failed, this is more likely to do GSL or your system/toolchain, however if it is a bug, please mention that too. 
MESSAGE

  }
} else {
  # if GSL was found
  print "Found GSL version $gsl_version";
}


WriteMakefile(
    NAME              => 'Alien::GSL',
    VERSION_FROM      => 'lib/Alien/GSL.pm',
    CONFIGURE_REQUIRES => {
      'File::Chdir' => 0,
      'LWP::Simple' => 0,
      'Archive::Extract' => 0,
    },
    PREREQ_PM         => {
      parent => 0,
    },
    ABSTRACT_FROM     => 'lib/Alien/GSL.pm',
    AUTHOR            => 'Joel Berger <joel.a.berger@gmail.com>',
    LICENSE           => 'perl',
    META_MERGE        => {
      resources => {
        repository => {
          type => "git",
          url  => "git://github.com:jberger/Alien-GSL.git",
          web  => "http://github.com/jberger/Alien-GSL",
        },
      },
    },
);

