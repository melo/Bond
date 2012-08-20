package Bond::Roles::Protocols::PingPong;

use Moo::Role;
use namespace::autoclean;

requires 'dispatch_msg';

after 'dispatch_msg' => sub {
  my ($self, $msg) = @_;

  return unless $msg->{type} eq 'ping';

  $self->send_msg(reply_to => $msg, type => 'pong', body => $msg->{body});
};

1;
