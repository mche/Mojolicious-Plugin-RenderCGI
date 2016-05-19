#!/usr/bin/env perl
package TestApp;

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
% layout 'foo';
% title 'EP';
EP - Работает!

@@ index.html.cgi
$c->layout('foo', handler=>'ep');
$c->title('CGI');
h1({}, 'CGI - фарева!'),
# $c->include('index', handler=>'ep'),

@@ layouts/foo.html.ep
<html>
<head><title><%= title %></title></head>
<body><%= content %></body>
</html>


