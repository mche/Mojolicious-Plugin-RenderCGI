use strict;
use warnings;
use utf8;

use Test::More;
use Mojolicious::Lite;

plugin 'RenderCGI' => {exception => 'template',};

get '/ep' => sub {
	my $c = shift;
	$c->render(handler => 'ep');
} => 'index';

get '/cgi' => sub {
	my $c = shift;
} => 'index';

get '/inline' => sub {
	my $c = shift;
	$c->render(inline=><<'EOT');
$c->layout('main',);
$c->title('INLINE');
h1 'Ohline!'
EOT
};

get '/empty' => sub {1};

get '/will_not_found' => sub {1};

#~ app->renderer->default_handler('cgi.pl');
app->defaults(handler=>'cgi.pl');

#====== tests=============

use_ok('Test::Mojo');

my $t = Test::Mojo->new();# MyApp->new()

$t->get_ok('/ep')->status_is(200)
  ->content_like(qr'EP');
  
$t->get_ok('/cgi')->status_is(200)
  ->content_like(qr'CGI')
  ->content_like(qr'Transitional')
  ;

$t->get_ok('/inline')->status_is(200)
  ->content_like(qr'Ohline')
  ;

$t->get_ok('/empty')->status_is(200)
  ->content_is('')
  ;

$t->get_ok('/will_not_found')->status_is(200)
  ->content_is('Template "will_not_found.html.cgi.pl" does not found')
  ;

plugin 'RenderCGI' => {exception =>'skip',};

$t = Test::Mojo->new;

$t->get_ok('/will_not_found')->status_is(200)
  ->content_is('')
  ;

plugin 'RenderCGI';

$t->get_ok('/cgi')->status_is(500)
  ->content_like(qr'Die')
  ->content_like(qr'not found')
  ;

$t->get_ok('/inline')->status_is(200)
  ->content_like(qr'Ohline')
  ;

done_testing();

__DATA__

@@ index.html.ep
% layout 'main';
% title 'EP';
<h1>EP - OK!</h1>

@@ index.html.cgi.pl
$c->layout('main',);# handler=>'ep'
$c->title('CGI');
h1({}, esc '<CGI - фарева!>'),
$c->include('part', handler=>'cgi.pl',),# handler still cgi? NO: Template "part.html.ep" not found!

@@ part.html.cgi.pl
$c->include('not exists',),
$c->include('empty',),
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
