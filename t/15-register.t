#!perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/tlib';
use T::Comm;
use T::Register;

my $cfg = { comms => { out_addr => 'ipc://out.sock', in_addr => 'ipc://in.sock' } };
END { unlink($_) for 'in.sock', 'out.sock' }


subtest 'register protocol' => sub {
  my $agent = T::Register->new(comm_type => 'agent', config => $cfg, auto_register => 0, id => 'a1');
  my $cntrl = T::Comm->new(comm_type => 'controller', config => $cfg, auto_register => 0);
  is($agent->comm_state, 'up', 'agent starts in the up state');

  $agent->unregister();
  is($agent->comm_state, 'up', 'unregister() on up agents is ignored');

  $agent->register;
  is($agent->comm_state, 'registering', 'register() moves the state to registering');

  my $msg;
  ok($msg = deliver_messages($cntrl), 'got message on controller');
  cmp_deeply(
    $msg,
    { type => 'register',
      from => $agent->my_addr,
      to   => '*',
      body => {
        id   => $agent->id,
        role => undef,
        type => 'agent',
      }
    },
    '... register type, with the proper content'
  );

  sleep(1);
  $agent->dispatch_pending_msgs;
  $agent->dispatch_pending_msgs;
  ok($msg = deliver_messages($cntrl), 'after timeout, another message received by the controller');
  is($msg->{type}, 'register', '... of the proper type');
  ok(!deliver_messages($cntrl), '... but only one message per cycle');

  $cntrl->send_msg(reply_to => $msg, type => 'welcome', body => { controller => $cntrl->my_addr });
  ok($msg = deliver_messages($agent), 'agent got a reply from controller');
  is($msg->{type},       'welcome', '... of the proper type');
  is($agent->comm_state, 'online',  'agent state is online, ready to work');


  ## empty controller and agent of pending messages
  flush_pending_messages($cntrl, $agent);


  $agent->register();
  is($agent->comm_state, 'online', 'register() on online agents is ignored');

  $agent->unregister();
  is($agent->comm_state, 'unregistering', 'unregister() on online agents moves state to unregistering');

  ok($msg = deliver_messages($cntrl), 'got message on controller');
  cmp_deeply(
    $msg,
    { type => 'unregister',
      from => $agent->my_addr,
      to   => '*',
      body => {
        id   => $agent->id,
        role => undef,
        type => 'agent',
      }
    },
    '... unregister type, with the proper content'
  );

  $cntrl->send_msg(reply_to => $msg, type => 'goodbye', body => { controller => $cntrl->my_addr });
  ok($msg = deliver_messages($agent), 'agent got a reply from controller');
  is($msg->{type},       'goodbye', '... of the proper type');
  is($agent->comm_state, 'up',      'agent state is now up again');

  flush_pending_messages($agent, $cntrl);
};


subtest 'register failure' => sub {
  my $agent = T::Register->new(comm_type => 'agent', config => $cfg, id => 'a1');
  my $cntrl = T::Comm->new(comm_type => 'controller', config => $cfg, auto_register => 0);

  is($agent->comm_state,      'registering', 'agent started register() process automatically (auto_register => 1)');
  is($agent->register_failed, 0,             "... register process didn't fail yet");

  while ($agent->comm_state eq 'registering') {
    $agent->dispatch_pending_msgs;
    sleep(1);
  }

  is($agent->comm_state,      'up', 'agent failed registration process');
  is($agent->register_failed, 1,    "... signal_registration_failed() was sent properly");

  flush_pending_messages($agent, $cntrl);
};


done_testing();


sub deliver_messages {
  my ($peer) = @_;

  my $count = 3;
  sleep(1) until $peer->dispatch_pending_msgs or 0 == --$count;

  return if $count == 0;
  return $peer->last_msg;
}

sub flush_pending_messages {
  for my $peer (@_) {
    while (deliver_messages($peer)) { }
  }
}
