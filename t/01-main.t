use strict;
use warnings;
use utf8;

use Test::More;
 
use_ok('Test::Mojo');

my $t = Test::Mojo->new(MyApp->new());
 
$t->get_ok('/ep')->status_is(200)
  ->content_like(qr'EP');
  
$t->get_ok('/cgi')->status_is(200)
  ->content_like(qr'CGI')
  ->content_like(qr'Transitional')
  ->content_like(qr'not exists')
  ;

$t->get_ok('/inline')->status_is(200)
  ->content_like(qr'Online')
  ;


done_testing();

package MyApp;

use Mojolicious::Lite;

plugin 'RenderCGI';

get '/cgi' => sub {
	my $c = shift;
} => 'index';

get '/inline' => sub {
	my $c = shift;
	$c->render(inline=><<'EOT');
h1 'Online!'
EOT
};

get '/ep' => sub {
	my $c = shift;
	$c->render(handler => 'ep');
} => 'index';

#~ app->renderer->default_handler('cgi');
app->defaults(handler=>'cgi');
# app->log->level('error');

app->start;

__DATA__

@@ index.html.ep
% layout 'main';
% title 'EP';
<h1>EP - OK!</h1>

@@ index.html.cgi
$c->layout('main',);# handler=>'ep'
$c->title('CGI');
h1({}, 'CGI - фарева!'),
$c->include('part', handler=>'cgi',),# handler still cgi? NO: Template "part.html.ep" not found!

@@ part.html.cgi
$c->include('not exists',),
hr,
<<HTML,
<!-- end part -->
HTML
$self->app->log->info("The part has done")
  && undef,

@@ layouts/main.html.ep
<html>
<head><title><%= title %></title></head>
<body><%= content %></body>
</html>

@@ layouts/main.html.cgi
charset('utf-8');
start_html(-title => $c->title,  -lang => 'ru-RU',),
$c->content,
end_html,
