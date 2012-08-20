package T::Comm;

use Moo;
use namespace::autoclean;

with
  'Bond::Roles::Core',
  'Bond::Roles::Config',
  'Bond::Roles::Role',
  'Bond::Roles::Comm',
  ;

has 'last_msg' => (is => 'rw');

sub dispatch_msg { shift->last_msg(shift) }
sub __timer      { }
sub BUILD        { }
sub DEMOLISH     { }

sub generate_id {$$}

1;
