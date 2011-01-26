package Stream::Server::Server;
use Moose;
extends 'Net::IMAP::Server';
use Module::Refresh;

sub capability {
	my $self = shift;
	my $c = $self->SUPER::capability;
	return $c;

}

after process_request => sub {
	Module::Refresh->refresh();
};

1;
