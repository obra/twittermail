package Stream::Server::Mailbox;
use Moose;
extends 'Net::IMAP::Server::Mailbox';

use Stream::Server::Message;

sub new {
	my $self = shift;
	warn $self;
	$self->SUPER::new(@_);
}

my $data = <<'EOF';
From: jesse@example.com
To: user@example.com
Subject: This is a test message!

Hello. I am executive assistant to the director of
Bear Stearns, a failed investment Bank.  I have
access to USD6,000,000. ...
EOF


=head2 add_child PARAMHASH

Creates a sub-mailbox of this mailbox; the class of the mailbox
created is determined by the C<class> value in the paramhash.  In all
other respects, identical to L<Net::IMAP::Server::Mailbox/add_child>.

=cut

sub add_child {
    my $self = shift;
    my %args = @_;

    my $class = $args{class} ? "Stream::Server::Mailbox::$args{class}" : "Stream::Server
::Mailbox";
    unless ($class->require) {
        warn "$@: $class";
        $class = "Stream::Server::Mailbox";
    }

    my $node = $class->new( { %args, parent => $self } );
    return unless $node;
    push @{ $self->children }, $node;
    return $node;
}


1;
