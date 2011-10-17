package My::Builder::Unix;

use lib 'builder';
use parent 'My::Builder';

use Carp;

sub new {
  my $class = shift;

  my $self = $class->SUPER::new(@_);

  bless($self, $class);

  # default to a system install
  if ($self->args('ShareDir')) {
    $self->config_data(location => 'share_dir');
  } else {
    $self->config_data(location => 'system');
  }

  return $self;
}

sub local_exec_prefix {
  return './';
}

1;

