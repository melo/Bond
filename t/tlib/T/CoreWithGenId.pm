package T::CoreWithGenId;

use Moo;
use namespace::autoclean;

with 'Bond::Roles::Core';

has 'called' => (is => 'rw', default => sub {0});
after 'init' => sub { shift->called(1) };

sub BUILD { }

sub generate_id {$$}

1;
