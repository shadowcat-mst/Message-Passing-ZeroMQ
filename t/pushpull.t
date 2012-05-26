use strict;
use warnings;

use Test::More;

use Message::Passing::Input::ZeroMQ;
use Message::Passing::Output::ZeroMQ;
use Message::Passing::Output::Test;
my $test = Message::Passing::Output::Test->new;
my $input = Message::Passing::Input::ZeroMQ->new(
        connect => 'tcp://127.0.0.1:5558',
        socket_type => 'PULL',
        output_to => $test,
);

my $output = Message::Passing::Output::ZeroMQ->new(
    socket_bind => 'tcp://127.0.0.1:5558',
    socket_type => 'PUSH',
);
my $cv = AnyEvent->condvar;
my $t; $t = AnyEvent->timer(
    after => 1,
    cb => sub {
        $output->consume({});
        $t = AnyEvent->timer(after => 1, cb => sub { $cv->send });
    },
);
$cv->recv;

is_deeply [$test->messages], [{}];
done_testing;

