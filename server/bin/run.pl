#!/usr/bin/perl

use lib 'lib';
use Stream::Server::Server;
Stream::Server::Server->new(
    auth_class  => "Stream::Server::Auth",
    model_class => "Stream::Server::Model",
    user        => 'nobody',
    port        => 143,
    ssl_port    => 993
)->run();
