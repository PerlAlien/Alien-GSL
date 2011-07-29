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
    exit 0 if $ENV{AUTOMATED_TESTING};

    die <<MESSAGE;
GSL could not be installed. This could be due to a few reasons.
1) Perhaps Alien::GSL does not yet support your operating system (currently supports: @Alien::GSL::SUPPORTED_OSES), in which case you are welcome to contribute at this module's GitHub repository. Until then you may install the GSL libraries (and the gsl-config utility) on your own, which will work too.
2) Maybe you just need to run the installer as root/administrator (did it tell you this above?). 
3) Otherwise the build has failed, this is more likely to do GSL or your system/toolchain, however if it is a bug, please mention that too. 
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

