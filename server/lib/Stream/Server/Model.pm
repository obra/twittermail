package Stream::Server::Model;
use Moose;
extends 'Net::IMAP::Server::DefaultModel';

use Stream::Server::Mailbox;

sub init {
    my $self = shift;
    $self->root( Stream::Server::Mailbox->new() );
    $self->root->add_child( name => "INBOX" );
}

no Moose;
1;
