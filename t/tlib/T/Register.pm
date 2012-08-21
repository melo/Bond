package T::Register;

use Moo;
use namespace::autoclean;

extends 'T::Comm';
with 'Bond::Roles::Protocols::Register';

has 'register_failed'   => (is => 'rw');
has 'unregister_failed' => (is => 'rw');

before register   => sub { shift->register_failed(0) };
before unregister => sub { shift->unregister_failed(0) };

sub signal_register_failed   { shift->register_failed(1) }
sub signal_unregister_failed { shift->unregister_failed(1) }

1;
