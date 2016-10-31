package Mojolicious::Plugin::RenderCGI;

use Mojo::Base 'Mojolicious::Plugin';
use Mojolicious::Plugin::RenderCGI::CGI;
use Mojo::Util qw(decode encode md5_sum);

our $VERSION = '0.072';
my $pkg = __PACKAGE__;

has name => 'cgi.pl';
has default => 0;
has import => sub { [qw(:html :form)] };
has exception => sub { {'handler'=>'ep', 'layout' => undef,} };
#~ has cgi => sub {
  #~ my $self = shift;
  #~ Mojolicious::Plugin::RenderCGI::CGI->new(
    #~ ref($self->import) eq 'ARRAY'
      #~ ? @{$self->import}
      #~ : (grep /\w/, split(/\s+/, $self->import)),
    #~ )
#~ };
has cache => sub { {} };

sub register {
  my ($plugin, $app, $conf) = @_;
  
  map $plugin->$_($conf->{$_}), grep defined($conf->{$_}), qw(name default import exception);
  #~ $app->renderer->default_handler($plugin->name) не работает
  $app->log->debug("Set default render handler ".$plugin->name)
    and $app->defaults('handler'=>$plugin->name)
    if $plugin->default;
    
  $app->renderer->add_handler(
    $plugin->name => sub {$plugin->handler(@_)}
  );
}

sub handler {
  my ($plugin, $r, $c, $output, $options) = @_;
  my $app = $c->app;
  #~ $app->log->debug($app->dumper($options));
  
  # относительный путь шаблона
  my $content = $options->{inline};# встроенный шаблон
  my $name = defined $content ? md5_sum encode('UTF-8', $content) : undef;
  return unless defined($name //= $r->template_name($options));
  
  my ($template, $from) = ($plugin->cache->{$name}, 'cache');# подходящий шаблон из кэша 
  
  my $stash = $c->stash($pkg);
  $c->stash($pkg => {stack => []})
    unless $stash;
  $stash ||= $c->stash($pkg);
  my $last_template = $stash->{stack}[-1];
  if ($last_template && $last_template eq $name) {
    $$output = $plugin->error("Stop looping template [$name]!", $c);
    return;
  }
  push @{$stash->{stack}}, $name;
  
  $$output = '';
  
  my $cgi = $plugin->cgi;
  
  unless ($template) {#не кэш
    if (defined $content) {# инлайн
      $from = 'inline';
    } else {
      # подходящий шаблон в секции DATA
      ($content, $from) = ($r->get_data_template($options), 'DATA section');#,, $name
      
      unless (defined $content) {# file
      #  абсолютный путь шаблона
        if (my $path = $r->template_path($options)) {
          my $file = Mojo::Asset::File->new(path => $path);
          ($content, $from) = ($file->slurp, 'file');
          
        } else {
          $$output = $plugin->error(sprintf(qq{Template "%s" does not found}, $name), $c);
          return;
        }
      }
    }
    
    $app->log->debug(sprintf(qq{Empty or nothing template "%s"}, $name))
      and return
      unless $content =~ /\w/;
    
    utf8::decode($content);
    
    $template = $cgi->template($content)
      or $$output = $plugin->error(sprintf(qq{Something's wrong for template "%s"}, $name), $c)
      and return;
    
    $$output = $plugin->error(sprintf(qq{Compile time error for template "%s": %s}, $name // $from, $template), $c)
      and return
      unless ref $template eq 'CODE';
    
  }
  
  $app->log->debug(sprintf(qq{Rendering template "%s" from the %s}, $name, $from,));
  $plugin->cache->{$name} ||= $template;
  
  my @out = eval { $template->($c, $cgi)};
  $$output = $plugin->error(sprintf(qq{Die on template "%s":\n%s}, $name // $from, $@), $c)
    and return
    if $@;
  
  $$output = join"\n", grep defined, @out;
  
}

sub error {# харе
    my ($plugin, $error, $c) = @_;
    $c->stash(%{$plugin->exception})
      and die $error
      if ref($plugin->exception) eq 'HASH';
    
    $c->app->log->error($error);# лог после die!
    return $plugin->exception eq 'template' ? $error : '';
  };

1;


=pod

=encoding utf8

Доброго всем

=head1 Mojolicious::Plugin::RenderCGI

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 VERSION

0.072

=head1 NAME

Mojolicious::Plugin::RenderCGI - Rendering template with Perl code and CGI.pm funcs/subs for tags emits.

=head1 SYNOPSIS

  $app->plugin('RenderCGI');

=head1 Template

Template is a Perl code that generate content as list of statements. Similar to C<do BLOCK>. Template file name like "templates/foo/bar.html.cgi.pl"

  # $c and $self already are controller
  # $cgi is a CGI object (OO-style)
  
  $c->layout('default', handler=>'ep',);# set handler 'ep' for all templates/includes !!! even default handler cgi
  my $foo = $c->stash('foo')
    or die "Where is your FOO?";
  
  #=======================================
  #======= content comma list! ===========
  #=======================================
  
  h1({}, "Welcome"),# but this template handlered cgi!
  
  $c->include('foo', handler=>'cgi.pl'),# change handler against layout
  $c->include('bar'); # handler still "ep" unless template "foo" (and its includes) didn`t changes it by $c->stash('handler'=>...)
  
  <<END_HTML,
  <!-- comment -->
  END_HTML
  
  $self->app->log->info("Template has done")
    && undef,

There are NO Mojolicious helpers without OO-style prefixes: C<< $c-> >> OR C<< $self-> >>.

B<REMEMBER!> Escapes untrusted data. No auto escapes!

  div({}, esc(...UNTRUSTED DATA...)),

C<esc> is a shortcut for &CGI::escapeHTML.

=head1 OPTIONS

=head2 name ( string )

  # Mojolicious::Lite
  plugin RenderCGI => {name => 'pl'};

Handler name, defaults to B<cgi.pl>.

=head2 default (bool)

When C<true> then default handler. Defaults - 0 (no this default handler for app).

  default => 1,

Is similar to C<< $app->defaults(handler=> <name above>); >>

=head2 import ( string (space delims) | arrayref )

What subs do you want from CGI.pm import

  $app->plugin('RenderCGI', import=>':html -any');
  # or 
  $app->plugin('RenderCGI', import=>[qw(:html -any)]);

See at perldoc CGI.pm section "USING THE FUNCTION-ORIENTED INTERFACE".
Default is ':html :form' (string) same as [qw(:html :form)] (arrayref).

  import=>[], # none import, CGI OO-style only

=head2 exception ( string | hashref )

To show fatal errors (not found, compile and runtime errors) as content of there template you must set string B<template>.

To show fatals as standard Mojolicious 'exception.<mode>.html.ep' page  - set hashref like {'handler'=>'ep', 'layout' => undef,}.

Overwise fatals are skips (empty string whole template).

By default set to hashref C<< {'handler'=>'ep', 'layout' => undef,} >>.

  exception => 'template', 

=head1 Methods, subs, helpers...

Implements register method only. Register new renderer handler. No new helpers.

=head1 SEE ALSO

L<CGI>

L<CGI::HTML::Functions>

L<Mojolicious::Plugin::TagHelpers>

L<HTML::Tiny>

=head1 AUTHOR

Михаил Че (Mikhail Che), C<< <mche[-at-]cpan.org> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests at L<https://github.com/mche/Mojolicious-Plugin-RenderCGI/issues>. Pull requests also welcome.

=head1 COPYRIGHT

Copyright 2016 Mikhail Che.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut