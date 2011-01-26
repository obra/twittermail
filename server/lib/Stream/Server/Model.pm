package Stream::Server::Model;
use Moose;
extends 'Net::IMAP::Server::DefaultModel';

use Stream::Server::Mailbox;

sub init {
    my $self = shift;
    $self->root( Stream::Server::Mailbox->new() );
    $self->root->add_child( name => "Facebook", class => 'Facebook' );
    $self->root->add_child( name => "Twitter", class => 'Twitter' );
}

no Moose;
1;
