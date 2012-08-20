package T::Config;

use Moo;
use namespace::autoclean;

with
  'Bond::Roles::Core',
  'Bond::Roles::Config',
  ;

has 'called' => (is => 'rw', default => sub {0});
after 'signal_config_updated' => sub { shift->called(1) };

sub BUILD { }

1;
