package T::PingPong;

use Moo;
use namespace::autoclean;

extends 'T::Comm';
with 'Bond::Roles::Protocols::PingPong';

1;
