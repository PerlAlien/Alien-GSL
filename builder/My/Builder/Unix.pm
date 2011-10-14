package My::Builder::Unix;

use lib 'builder';
use parent 'My::Builder';

use Carp;

use File::chdir;

sub local_exec_prefix {
  return './';
}

1;

