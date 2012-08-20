#!perl

use strict;
use warnings;
use lib 't/tlib';
use Test::More;
use Scalar::Util 'weaken';
use T::Comm;

my $copy = my $agent = T::Comm->new(
  comm_type     => 'agent',
  config        => { comms => { out_addr => 'ipc://out.sock', in_addr => 'ipc://in.sock' } },
  auto_register => 0,
);
weaken($copy);

undef $agent;

is($copy, undef, 'proper reference management');


done_testing();
