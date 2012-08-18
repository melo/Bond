package Bond;

1;

__END__

=encoding utf8

=head1 DESCRIPTION

Bond is a software agent that runs inside your applications and reports
data back to his controller.

A client can then be used to fetch all the collected data from the
controller.


=head1 INTERNALS

There are three types of actors in this framework: agent, controller
and client.

Agents communicate with controllers and clients communicate with
controllers. Agents and clients never communicate directly.

They all share a common asynchronous communication framework that allows
them to talk to one or all of its peers. For example, a controller can
send information to all of its agents, or to all of its clients, or
target just one agent or target.

Agents and clients, when they start up, register themselves with a
controller and provide a transient ID. This ID is used when the
controller needs to communicate with one particular agent.


=head2 Communication layer

Bond uses ZeroMQ PUB/SUB sockets to communicate between peers.

Each peer has one PUB socket to send commands, and one SUB socket to
receive commands.

The topic of the message provides addressing, and uses the first frame
of the message. The second message is the payload as a JSON object.

The controller binds both sockets to well-known addresses. Agents and
clients connect both sockets to those well-known addresses.


=head2 Messages

In this section we will use two new terms. Agents and clients have a lot
of common protocols and messages so we will use slave as a designation
of both of them. The controller is our master.



=head3 Registration

When a slave starts, it connects both sockets and starts the registration protocol.

The protocol consists of sending C<REGISTER> messages until they get
back a C<WELCOME> message. The slave will use increasing backoff period
between each REGISTER message with a upper bound of 5 seconds.

The C<REGISTER> message includes:

=over 4

=item * ID of the slave

Usually a UUID but you can use whatever you want as long as it is unique.

=item * slave type

The type of slave this is, client or agent.

=item * slave role

This is a optional app-specific field, that allows you to group slaves
(usually used with agents) by their role in your app. For example, you
would use different roles for web server process, job workers, crons,
and other elements.


=head3 Status queries

Slaves can query the master to obtain a view of the status.

The C<STATUS> message dumps the entire status view to the slave.



=cut
