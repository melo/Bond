package Bond::Roles::Protocols::Register;

use Moo::Role;
use namespace::autoclean;

requires 'dispatch_msg', 'id', 'role', '__timer';

#############################
# Start the register protocol

has '_rp_retry_count' => (is => 'rw');
has '_rp_last_try_ts' => (is => 'rw');

sub register {
  my ($self) = @_;
  return if $self->comm_state ne 'up';

  $self->_set_comm_state('registering');
  $self->_rp_retry_count(0);
  $self->_rp_last_try_ts(0);
  $self->_rp_tick;
}

sub unregister {
  my ($self) = @_;
  return if $self->comm_state ne 'online';

  $self->_set_comm_state('unregistering');
  $self->_rp_retry_count(0);
  $self->_rp_last_try_ts(0);
  $self->_rp_tick;
}

sub _rp_tick {
  my ($self) = @_;
  my $state = $self->comm_state;
  return unless $state eq 'registering' or $state eq 'unregistering';

  ## See if we should send another msg
  my $now  = time();
  my $last = $self->_rp_last_try_ts;
  return if $now == $last;

  ## fail protocol if too many tries
  my $cnt = $self->_rp_retry_count;
  if ($cnt == 10) {
    $self->_rp_retry_count(-1);
    $state eq 'registering' ? $self->signal_register_failed() : $self->signal_unregister_failed;
    $self->_set_comm_state('up');
    return;
  }

  ## All is well, send the next one
  $self->_rp_retry_count($cnt + 1);
  $self->_rp_last_try_ts($now);

  $self->send_msg(
    type => $state eq 'registering' ? 'register' : 'unregister',
    body => {
      id   => $self->id,
      type => $self->comm_type,
      role => $self->role,
    },
  );

  ## Ask to be called again in a second
  $self->__timer(1, sub { $self->_rp_tick });

  return;
}

sub signal_register_failed { }

sub signal_unregister_failed { }

# Use regular checks for incoming messages as a poor-mans timer
after 'dispatch_pending_msgs' => sub { shift->_rp_tick };


################################
# Listen to our protocol replies

after 'dispatch_msg' => sub {
  my ($self, $msg) = @_;
  my $state = $self->comm_state;
  return unless $state eq 'registering' or $state eq 'unregistering';

  my $type = $msg->{type};
  if ($type eq 'welcome') {
    $self->_set_comm_state('online');
  }
  elsif ($type eq 'goodbye') {
    $self->_set_comm_state('up');
  }
  else {
    ## all oportunities are good to check if we need to send another register message
    $self->_rp_tick();
  }

  return;
};


1;
