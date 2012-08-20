package Bond::Roles::Comm;

use Moo::Role;
use ZeroMQ ':all';    ## ZeroMQ::Context and ZeroMQ::Socket
use JSON 'encode_json', 'decode_json';
use namespace::autoclean;

requires 'config', 'init', 'id', 'dispatch_msg';


## Addressing

sub my_addr { my $self = shift; return join('.', $self->comm_type, $self->id) }


## Comm section
has '_comm_ctx'     => (is => 'rw');
has '_in_sock'      => (is => 'rw');
has '_out_sock'     => (is => 'rw');
has 'comm_type'     => (is => 'ro', required => 1);
has 'auto_register' => (is => 'rw', default => sub {1});
has 'comm_state'    => (is => 'rwp', default => sub {'down'});

sub send_msg {
  my ($self, %args) = @_;
  $self->_pid_check;

  die "Tried to send_msg() when comm_state is down" if $self->comm_state eq 'down';

  my $addr = $args{to}   || '*';
  my $type = $args{type} || die "Missing param 'type' on call to send_msg(),";
  my $body = $args{body} || {};
  my $msg = { type => $type, from => $self->my_addr, to => $addr, body => $body };

  my $out = $self->_out_sock;
  ## FIXME: this could block, should we use ZMQ_NOBLOCK and report as error?
  $out->send($addr, ZMQ_SNDMORE);
  $out->send(encode_json($msg));

  return 1;
}

sub dispatch_pending_msgs {
  my ($self) = @_;
  $self->_pid_check;

  my $in    = $self->_in_sock;
  my $count = 0;
  while (1) {
    my $addr = $in->recv(ZMQ_NOBLOCK);
    last unless defined $addr;

    my $msg = $in->recv();
    $msg = eval { decode_json($msg) };
    ## FIXME: should we report bad messages?
    next unless $msg;

    $self->dispatch_msg($msg, $addr);
    $count++;
  }

  return $count;
}


## Initialization
sub _init_comm {
  my ($self) = @_;
  my $type = $self->comm_type;

  $self->_comm_ctx(my $ctx = ZeroMQ::Context->new);
  $self->_in_sock(my $in   = $ctx->socket(ZMQ_SUB));
  $self->_out_sock(my $out = $ctx->socket(ZMQ_PUB));

  my $cfg = $self->config('comms');
  if ($type eq 'agent' or $type eq 'client') {
    $in->connect($cfg->{out_addr});
    $out->connect($cfg->{in_addr});
    $in->setsockopt(ZMQ_SUBSCRIBE, '*');
    $in->setsockopt(ZMQ_SUBSCRIBE, $self->my_addr);
    ## FIXME: set LINGER stuff

    $self->_set_comm_state('up');

    $self->register if $self->auto_register;
  }
  elsif ($type eq 'controller') {
    $in->bind($cfg->{in_addr});
    $out->bind($cfg->{out_addr});
    $in->setsockopt(ZMQ_SUBSCRIBE, '*');
    ## FIXME: set LINGER stuff

    $self->_set_comm_state('up');
  }
  else {
    die "FATAL: comm_type '$type' is not supported, ";
  }
}

after 'init' => sub { shift->_init_comm };

## FIXME: hook DESTROY to make sure we cleanup


## Fork protection
has '_pid' => (is => 'rw', default => sub {$$});

sub _pid_check {
  my ($self) = @_;

  $self->_init_comm() if $self->_pid != $$;
}

1;
