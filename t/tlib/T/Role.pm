package T::Role;

use Moo;
use namespace::autoclean;

with 'Bond::Roles::Core', 'Bond::Roles::Role';

sub BUILD { }

sub generate_id {$$}

1;
