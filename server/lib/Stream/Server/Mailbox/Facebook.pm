package Stream::Server::Mailbox::Facebook;
use Moose;
extends 'Stream::Server::Mailbox';

use autodie;
use WWW::Facebook::API;
use Data::Dumper;
use Config::Tiny;
use JSON::XS;
use YAML;
use DateTime;
use Email::MIME;
use Email::MIME::Creator;

has last_polled => ( is => 'rw', isa => 'Int');
sub load_original {
	my $self = shift;
	$self->inject_posts();
	$self->last_polled(time());
}

sub poll {
	my $self = shift;
    return $self->load_original unless defined $self->last_polled;
	if ($self->last_polled + 60 < time() ) {
		$self->inject_posts();
		$self->last_polled(time);
	}
}


use constant CONFIG_FILE => "/home/jesse/paulbook.ini";

# At the very least, we need an api_key and secret in our config.

my $config = Config::Tiny->read(CONFIG_FILE);

my $connect_config = $config->{connection};

my $fb = WWW::Facebook::API->new(
    desktop => 1,

    throw_errors => 1,
    debug => 0,

    %$connect_config,
);

# Nasty session setup code.

if ( not $connect_config->{session_key} ) {

    if (not $ARGV[0]) {
        print "Login needed...  Go to...\n";
        print $fb->get_infinite_session_url,"\n";
        print "Then run again with your one-time code as a command-line argument\n";

        exit 0;

    } else {
        # Ah! We have a token...

        my $token = $ARGV[0];

        $fb->auth->get_session($token);

        # Now save all the details we got from that login.

        $connect_config->{secret}          = $fb->secret;
        $connect_config->{session_expires} = $fb->session_expires;
        $connect_config->{session_key}     = $fb->session_key;
        $connect_config->{session_uid}     = $fb->session_uid;

        $config->write(CONFIG_FILE);

        print "Login complete.  Please run application again.\n";

        exit 0;

    }
}

my $app_user = $fb->users->get_logged_in_user;
my %perms_result = %{($fb->fql->query( query => qq{SELECT read_stream,publish_stream FROM permissions WHERE uid=}.$app_user))->[0]};
unless ($perms_result{publish_stream} && $perms_result{read_stream}) {
	print "Next up, you need to give this app permissions to see your stream. Visit the url below and the rerun the application\n";
print $fb->get_url('custom', 'http://www.facebook.com/connect/prompt_permissions.php',
	next=>'http://www.facebook.com/connect/login_success.html?xxRESULTTOKENxx',
	display=> 'popup',
	ext_perm=> 'read_stream,publish_stream');
	exit 0;
}

my $seen = {};
sub fetch_stream {
	my $self = shift;
    my $result = $fb->stream->get( metadata => [qw(albums profiles photo_tags)] );
    my $people = { map { $_->{id}      => $_ } @{ $result->{profiles} } };
    my $posts  = { map { $_->{post_id} => $_ } grep {! $seen->{$_->{post_id}}++ } @{ $result->{posts} } };
        return map { $self->format_post($_, $posts,$people)} values %$posts;
}

sub inject_posts {
	my $self = shift;
	my @data = $self->fetch_stream();
	for my $raw (@data) {
		my $msg = Stream::Server::Message->new($raw);
		$self->add_message($msg) 
	}
warn "done";

}


sub format_post {
	my $self = shift;
    my $post = shift;
	my $posts = shift;
	my $people = shift;
    my $date = DateTime->from_epoch( epoch => $post->{updated_time} ||$post->{created_time});
    my $mime = Email::MIME->create(

        header => [ From => $people->{$post->{actor_id}}->{name} . " <".$self->url_to_addr($people->{$post->{actor_id}}->{url}).">",
                    Subject => $post->{message},
                    'Message-Id' => "<".$post->{post_id}."\@faked-message-id.fb-email-proxy>",
                    Date => $date->ymd . " ".$date->hms 
                    ], 
        body => $post->{message}); 
 
    return $mime->as_string 
}

sub url_to_addr {
	my $self = shift;
	my $url = shift;
	if ($url =~ qr|https?://www.facebook.com/(?:profile.php\?)?(.*)$|) {
		return $1.'@facebook.streamserver';
	} else {
		return $url;
	}	
}


1;

