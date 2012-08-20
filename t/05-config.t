#!perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/tlib';
use T::Config;

subtest 'config' => sub {
  my $t = T::Config->new(
    id     => "test.$$",
    config => { comms => { out_addr => 'ipc://out.sock', in_addr => 'ipc://in.sock' }, test => 42 },
  );

  cmp_deeply(
    $t->config('comms'),
    { out_addr => 'ipc://out.sock', in_addr => 'ipc://in.sock' },
    'proper access to configuration',
  );
  is($t->config('test'),      42,    'scalar config, returns expected value');
  is($t->config('no_config'), undef, 'missing config, returns undef');

  cmp_deeply(
    $t->config,
    { comms => { out_addr => 'ipc://out.sock', in_addr => 'ipc://in.sock' },
      test  => 42,
    },
    'no arguments, full config',
  );
};


subtest 'config updated' => sub {
  my $t = T::Config->new(
    id     => "test.$$",
    config => { comms => { out_addr => 'ipc://out.sock', in_addr => 'ipc://in.sock' }, test => 42 },
  );
  is($t->called, 0, 'config updated flag is clear');

  $t->config_update();
  $t->config_update(42);
  $t->config_update([]);
  is($t->called, 0, 'config updated flag is still clear');

  $t->config_update({ good => 'call' });
  is($t->called, 1, 'config updated flag is now set');
  cmp_deeply($t->config, { good => 'call' }, '... config was properly updated');
};


done_testing();
