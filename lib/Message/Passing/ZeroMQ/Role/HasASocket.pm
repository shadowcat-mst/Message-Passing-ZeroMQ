package Message::Passing::ZeroMQ::Role::HasASocket;
use Moose::Role;
use ZeroMQ ':all';
use Moose::Util::TypeConstraints;
use namespace::autoclean;

with 'Message::Passing::ZeroMQ::Role::HasAContext';

has _socket => (
    is => 'ro',
    isa => 'ZeroMQ::Socket',
    lazy => 1,
    builder => '_build_socket',
    predicate => '_has_socket',
    clearer => '_clear_socket',
);

before _clear_ctx => sub {
    my $self = shift;
    if (!$self->linger) {
        $self->_socket->setsockopt(ZMQ_LINGER, 0);
    }
    $self->_socket->close;
    $self->_clear_socket;
};

requires '_socket_type';

has linger => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
);

sub _build_socket {
    my $self = shift;
    my $type_name = "ZeroMQ::Constants::ZMQ_" . $self->socket_type;
    my $socket = $self->_ctx->socket(do { no strict 'refs'; &$type_name() });
    if (!$self->linger) {
        $socket->setsockopt(ZMQ_LINGER, 0);
    }
    $self->setsockopt($socket);
    if ($self->_should_connect) {
        $socket->connect($self->connect);
    }
    if ($self->_should_bind) {
        $socket->bind($self->socket_bind);
    }
    $socket;
}

sub setsockopt {}

has socket_bind => (
    is => 'ro',
    isa => 'Str',
    predicate => '_should_bind',
);

has socket_type => (
    isa => enum([qw[PUB SUB PUSH PULL]]),
    is => 'ro',
    builder => '_socket_type',
);

has connect => (
    isa => 'Str',
    is => 'ro',
    predicate => '_should_connect',
);

1;

=head1 NAME

Message::Passing::ZeroMQ::Role::HasASocket - Role for instances which have a ZeroMQ socket.

=head1 ATTRIBUTES

=head2 socket_bind

Bind a server to an address.

For example C<< tcp://*:5222 >> to make a server listening
on a port on all of the host's addresses, or C<< tcp://127.0.0.1:5222 >>
to bind the socket to a specific IP on the host.

=head2 connect

Connect to a server. For example C<< tcp://127.0.0.1:5222 >>.

This option is mutually exclusive with socket_bind, as sockets
can connect in one direction only.

=head2 socket_type

The connection direction can be either the same as, or the opposite
of the message flow direction.

The currently supported socket types are:

=head3 PUB

This socket publishes messages to zero or more subscribers.

All subscribers get a copy of each message.

=head3 SUB

The pair of PUB, receives broadcast messages.

=head3 PUSH

This socket type distributes messages in a round-robin fashion between
subscribers. Therefore N subscribers will see 1/N of the message flow.

=head2 PULL

The pair of PUSH, receives a proportion of messages distributed.

=head2 linger

Bool indicating the value of the ZMQ_LINGER options.

Defaults to 0 meaning sockets are lossy, but will not block.

=head3 linger off (default)

Sending messages will be buffered on the client side up to the set
buffer for this connection. Further messages will be dropped until
the buffer starts to empty.

Receiving messages will be buffered by ZeroMQ for you until you're
ready to receive them, after which they will be discarded.

=head3 linger off

Sending messages will be be buffered on the client side up to the set
buffer for this connection. If this buffer fills, then ZeroMQ will block
the program which was trying to send the message. If the client quits
before all messages were sent, ZeroMQ will block exit until they have been
sent.

=head1 METHODS

=head2 setsockopt

For wrapping by sub-classes to set options after the socket
is created.

=head1 SPONSORSHIP

This module exists due to the wonderful people at Suretec Systems Ltd.
<http://www.suretecsystems.com/> who sponsored it's development for its
VoIP division called SureVoIP <http://www.surevoip.co.uk/> for use with
the SureVoIP API - 
<http://www.surevoip.co.uk/support/wiki/api_documentation>

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing::ZeroMQ>.

=cut
