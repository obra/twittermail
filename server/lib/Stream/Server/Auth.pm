package Stream::Server::Auth;
use Moose;
extends 'Net::IMAP::Server::DefaultAuth';

sub auth_plain {
    my ( $self, $user, $pass ) = @_;

    # XXX DO AUTH CHECK
    $self->user($user);
    return 1;
}

no Moose;
1;
