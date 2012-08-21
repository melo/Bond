#!perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/tlib';
use T::Comm;

my $cfg = { comms => { out_addr => 'ipc://out.sock', in_addr => 'ipc://in.sock' } };
END { unlink($_) for 'in.sock', 'out.sock' }


subtest 'basic comm' => sub {
  my $agent = T::Comm->new(comm_type => 'agent',      config => $cfg, auto_register => 0);
  my $cntrl = T::Comm->new(comm_type => 'controller', config => $cfg, auto_register => 0);

  $agent->send_msg(type => 'ping', body => { answer => 42 });
  my $count = 10;
  sleep(1) until $cntrl->dispatch_pending_msgs or 0 == $count--;

  my $msg = $cntrl->last_msg;
  ok($msg, 'received a message');
  cmp_deeply(
    $msg,
    { type => 'ping',
      from => $agent->my_addr,
      to   => '*',
      body => { answer => 42 },
    },
    '... with the expected content layout'
  );

  $cntrl->send_msg(reply_to => $msg, type => 'pong');
  $count = 10;
  sleep(1) until $agent->dispatch_pending_msgs or 0 == $count--;

  $msg = $agent->last_msg;
  ok($msg, 'received another message');
  cmp_deeply(
    $msg,
    { type => 'pong',
      from => $cntrl->my_addr,
      to   => $agent->my_addr,
      body => {},
    },
    '... with the expected content layout'
  );
};


done_testing();
