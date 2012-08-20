#!perl

use strict;
use warnings;
use lib 't/tlib';
use Test::More;
use Test::Deep;
use T::Comm;

eval { require AnyEvent; AnyEvent->import };
plan skip_all => 'This test requires AnyEvent' if $@;


my $agent = T::Comm->new(
  { comm_type     => 'agent',
    config        => { comms => { out_addr => 'ipc://out.sock', in_addr => 'ipc://in.sock' } },
    auto_register => 0,
  }
);
my $ctrl = T::Comm->new(
  { comm_type     => 'controller',
    config        => { comms => { out_addr => 'ipc://out.sock', in_addr => 'ipc://in.sock' } },
    auto_register => 0,
  }
);

my $cv = AnyEvent->condvar;
my $io = AnyEvent->io(
  fh   => $ctrl->comm_fd,
  poll => 'r',
  cb   => sub { $ctrl->dispatch_pending_msgs && $cv->send },
);
my $count = 1;
my $timer = AnyEvent->timer(
  after    => 1,
  interval => 1,
  cb       => sub { $agent->send_msg(type => 't', body => $count++); $cv->send if $count > 5 },
);

$cv->recv;

cmp_deeply(
  $ctrl->last_msg,
  { body => num(1, 1),
    from => "agent.$$",
    to   => '*',
    type => 't',
  },
  'Got the message loud and clear',
);


done_testing();
