#!/usr/bin/env perl

use Mojolicious::Lite;
use FindBin;
use lib "$FindBin::Bin/lib";

plugin 'RenderCGI';

get '/cgi' => sub {
	my $c = shift;
} => 'index';

get '/ep' => sub {
	my $c = shift;
	$c->render(handler => 'ep');
} => 'index';

app->renderer->default_handler('cgi');
# app->log->level('error');

app->start;

__DATA__

@@ index.html.ep
EP - Работает!

@@ index.html.cgi
'CGI - работает!',
