#!perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/tlib';
use T::Comm;
use T::PingPong;

my $cfg = { comms => { out_addr => 'ipc://out.sock', in_addr => 'ipc://in.sock' } };
END { unlink($_) for 'in.sock', 'out.sock' }


subtest 'ping pong protocol' => sub {
  my $a1 = T::PingPong->new(comm_type => 'agent', config => $cfg, auto_register => 0, id => 'a1');
  my $a2 = T::PingPong->new(comm_type => 'agent', config => $cfg, auto_register => 0, id => 'a2');
  my $cntrl = T::Comm->new(comm_type => 'controller', config => $cfg, auto_register => 0);

  ## This will help make sure our topology is up and running
  my $c = 0;
  $_->send_msg(type => 'ignore'), $c++ for $a1, $a2, $a1, $a2, $a1, $a2, $a1, $a2, $a1, $a2;
  while (deliver_messages($cntrl)) { $c-- }
  diag("Sync agents/controller, delta msg is $c");

  ok($cntrl->send_msg(type => 'ping', body => 42), 'ping sent via controller');

  my $msg;
  ok($msg = deliver_messages($a1), 'got message on agent 1');
  cmp_deeply($msg, { type => 'ping', from => $cntrl->my_addr, to => '*', body => 42 }, '... with the proper content');
  ok($msg = deliver_messages($a2), 'got message on agent 2');
  cmp_deeply($msg, { type => 'ping', from => $cntrl->my_addr, to => '*', body => 42 }, '... with the proper content');

  ok($msg = deliver_messages($cntrl), 'controller gets one message back');
  cmp_deeply(
    $msg,
    { type => 'pong', to => $cntrl->my_addr, from => re(qr{^agent\.a\d$}), body => 42 },
    '... with the proper content'
  );
};


done_testing();

sub deliver_messages {
  my ($peer) = @_;

  my $count = 3;
  sleep(1) until $peer->dispatch_pending_msgs or 0 == --$count;

  return if $count == 0;
  return $peer->last_msg;
}
