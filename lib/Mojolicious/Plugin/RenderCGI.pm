package Mojolicious::Plugin::RenderCGI;

use Mojo::Base 'Mojolicious::Plugin';
#~ use Capture::Tiny qw(capture);
use Mojolicious::Plugin::RenderCGI::CGI;
use Mojo::Util qw(encode md5_sum);

our $VERSION = '0.01';
my $pkg = __PACKAGE__;
my %cache = ();

sub register {
  my ($self, $app, $conf) = @_;
  
  $conf->{import} ||= [qw(:html :form)];
  $conf->{import} = [grep /\w/, split(/\s+/, $conf->{import})]
    unless ref $conf->{import};
  #~ $conf->{skip_fatals} //= $app->mode eq 'development' ? 0 : 1;
  $conf->{fatals} //= 'exception';
  #~ $conf->{not_found} //= $app->mode eq 'development' ? 'template' : 'exception';
    
  my $renderer = Mojolicious::Plugin::RenderCGI::CGI->new(
    import=>$conf->{import},
  );
  
  $app->renderer->add_handler(
    cgi => sub {
      my ($r, $c, $output, $options) = @_;
      #~ $app->log->debug($app->dumper($options));
      
      # относительный путь шаблона
      #~ my $name = $r->template_name($options);
      my $content = $options->{inline};# встроенный шаблон
      my $name = defined $content ? md5_sum encode('UTF-8', $content) : undef;
      return unless defined($name //= $r->template_name($options));
      
      my ($error, $rend, $from) = (undef, undef, 'inline')
        if defined $content;
      
      my $stash = $c->stash($pkg);
      $c->stash($pkg => {stack => []})
        unless $stash;
      $stash ||= $c->stash($pkg);
      my $last_template = $stash->{stack}[-1];
      $c->stash('handler'=>'ep')
        and die "Loops template [$name]!"
        if $last_template && $last_template eq $name;
      push @{$stash->{stack}}, $name;
      
      unless (defined $content) {#не инлайн
        # подходящий шаблон из кэша 
        ($rend, $from) = ($cache{$name}, 'cache');
        unless ($rend) {# не кэш
          # подходящий шаблон в секции DATA
          ($content, $from) = ($r->get_data_template($options), 'DATA section');#,, $name
          
          unless (defined $content) {# file
          #  абсолютный путь шаблона
            if (my $path = $r->template_path($options)) {
              my $file = Mojo::Asset::File->new(path => $path);
              ($content, $from) = ($file->slurp, 'file');
              
            } else {
              $error = sprintf(qq{Template "%s" does not found}, $name);
              $app->log->error($error);
              $c->stash('handler'=>'ep')
                and die $error
                if $conf->{fatals} eq 'exception';
              $$output = $conf->{fatals} eq 'template' ? $error : '';
              return;
            }
          }
        }
      }
      
      $$output = '';
      $app->log->debug(sprintf(qq{Empty template "%s"}, $name))
        and return
        unless $rend || defined($content) && $content !~ /^\s*$/;
      
      $rend ||= $renderer->compile($content);

      unless (ref $rend eq 'CODE') {
        $error = sprintf(qq{Compile error template "%s": %s}, $name // $from, $rend);
        $app->log->error($error);
        $c->stash('handler'=>'ep')
          and die $error
          if $conf->{fatals} eq 'exception';
        $$output = $conf->{fatals} eq 'template' ? $error : '';
        return;
      }

      $app->log->debug(sprintf(qq{Rendering template "%s" from the %s}, $name, $from,));
      $cache{$name} ||= $rend;
      
      # Передать rendered результат обратно в рендерер
      my @out = eval { $rend->($c,)};
      if ($@) {
        $error = sprintf(qq{Die on template "%s":\n%s}, $name // $from, $@);
        $app->log->error($error);
        $c->stash('handler'=>'ep')
          and die $error
          if $conf->{fatals} eq 'exception';
        $$output =  $conf->{fatals} eq 'template' ? $error : '';
        return;
      }
      
      $$output = join"\n", grep defined, @out;
      
    }
  );
}



1;


=pod

=encoding utf8

Доброго всем

=head1 Mojolicious::Plugin::RenderCGI

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 VERSION

0.01

=head1 NAME

Mojolicious::Plugin::RenderCGI - Rendering template with Perl code and CGI.pm subs.

=head1 SYNOPSIS

  $app->plugin('RenderCGI');
  
  # Set as default handler
  $app->renderer->default_handler('cgi');
  # or same
  $app->defaults(handler=>'cgi');
 
  # Render without setting as default handler
  $c->render(handler => 'cgi');
  

=head1 Template

File name like "templates/foo/bar.html.cgi"

  # $c and $self already are controller
  # $cgi is a CGI object (OO-style)
  
  $c->layout('default', handler=>'ep',);# set handler 'ep' for all includes !!!
  my $foo = $c->stash('foo')
    or die "Where is your FOO?";
  
  #=======================================
  #======= content comma list! ===========
  #=======================================
  
  h1({}, "Welcome"),
  
  $c->include('foo', handler=>'cgi'),# change handler against layout
  $c->include('bar'); # handler still "cgi" unless template "foo" (and its includes) didn`t changes it
  
  <<END_HTML,
  <!-- comment -->
  END_HTML
  
  $self->app->log->info("Template has done")
    && undef,

There are NO Mojolicious helpers without OO-style: B<$c->> OR B<$self->> prefix.

B<REMEMBER!> Escapes untrusted data. No auto escapes!

  div({}, esc(...UNTRUSTED DATA...)),

C<esc> is a shortcut for &CGI::escapeHTML.

=head1 Options

=head2 import (string (space delims) | arrayref)

What subs do you want from CGI.pm import

  $app->plugin('RenderCGI', import=>':html -any');
  # or 
  $app->plugin('RenderCGI', import=>[qw(:html -any)]);

See at perldoc CGI.pm section "USING THE FUNCTION-ORIENTED INTERFACE".
Default is ':html :form' (string) same as [qw(:html :form)] (arrayref).

  import=>[], # none import, CGI OO-style only

=head2 fatals (string)

To show fatal errors (not found, compile and runtime errors) as content of there template you must set string B<template>.

To show fatals as standard Mojolicious 'exception.<mode>.html.ep' page (handler=>'ep' auto sets) - set B<exception>.

Overwise fatals are skips (empty string whole template).

By default set to B<exception>.

  fatals=>'template', 

=head1 Methods, subs, helpers...

Implements register method only. Register new renderer handler 'cgi'. No new helpers.

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