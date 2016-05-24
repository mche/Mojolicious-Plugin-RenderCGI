#!/usr/bin/env perl
package TestApp;

use Mojolicious::Lite;
use FindBin;
use lib "$FindBin::Bin/lib";

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
#~ app->defaults(handler=>'cgi.pl');
# app->log->level('error');

plugin 'RenderCGI' => {default => 1, exception=> 'template',};#=> { name=>'pl', import=>':foo :bar'};#'name'=>'cgi.pl'

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

@@ index.html.cgi.pl
$c->layout('main',);# handler=>'cgi.pl'
$c->title('CGI');
h1({}, esc '<CGI - фарева!'),
$c->include('part', handler=>'cgi.pl',),# handler still cgi? NO
$c->include('файл',handler=>'cgi.pl',),
$c->include('empty',handler=>'cgi.pl',),

@@ part.html.cgi.pl
$c->include('not exists',),
hr,
<<HTML,
<!-- end part -->
HTML
$self->app->log->info("The part has done")
  && undef,

@@ empty.html.cgi.pl


@@ layouts/main.html.ep
<html>
<head><title><%= title %></title></head>
<body><%= content %></body>
</html>

@@ layouts/main.html.cgi.pl
charset('utf-8');
start_html(-title => $c->title,  -lang => 'ru-RU',),
$c->content,
$cgi->end_html,

