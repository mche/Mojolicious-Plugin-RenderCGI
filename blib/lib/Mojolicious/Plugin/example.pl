#!/usr/bin/env perl
package TestApp;

use Mojolicious::Lite;
use FindBin;
use lib "$FindBin::Bin/lib";

plugin 'RenderCGI'=> {exception=> 'template0'};

get '/cgi' => sub {
	my $c = shift;
} => 'index';

get '/inline' => sub {
	my $c = shift;
	$c->render(inline=><<'EOT');
h1 'Inline!'
EOT
};

get '/empty' => sub {1};

get '/will_not_found' => sub {1};

get '/ep' => sub {
	my $c = shift;
	$c->render(handler => 'ep');
} => 'index';

get '/ep404' => sub {
	my $c = shift;
	$c->render(handler => 'ep');
};

#~ app->renderer->default_handler('cgi');
app->defaults(handler=>'cgi');
# app->log->level('error');

app->start;

__DATA__

@@ index.html.ep
% layout 'main';
% title 'EP';
<h1>EP - OK!</h1>
% include 'loop1';

@@ loop1.html.ep
%# include 'loop2';

@@ loop2.html.ep
% include 'loop1';

@@ index.html.cgi
$c->layout('main',);# handler=>'ep'
$c->title('CGI');
h1({}, esc '<CGI - фарева!'),
$c->include('part', handler=>'cgi',),# handler still cgi? NO: Template "part.html.ep" not found!
$c->include('файл',),
$c->include('empty',),

@@ part.html.cgi
$c->include('not exists',),
hr,
<<HTML,
<!-- end part -->
HTML
$self->app->log->info("The part has done")
  && undef,

@@ empty.html.cgi


@@ layouts/main.html.ep
<html>
<head><title><%= title %></title></head>
<body><%= content %></body>
</html>

@@ layouts/main.html.cgi
charset('utf-8');
start_html(-title => $c->title,  -lang => 'ru-RU',),
$c->content,
$cgi->end_html,

