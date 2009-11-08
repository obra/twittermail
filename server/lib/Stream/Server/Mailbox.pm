package Stream::Server::Mailbox;
use Moose;
extends 'Net::IMAP::Server::Mailbox';

use Stream::Server::Message;


my $data = <<'EOF';
From: jesse@example.com
To: user@example.com
Subject: This is a test message!

Hello. I am executive assistant to the director of
Bear Stearns, a failed investment Bank.  I have
access to USD6,000,000. ...
EOF

my $msg = Stream::Server::Message->new($data);

sub load_data {
    my $self = shift;
    $self->add_message($msg);
}

1;
