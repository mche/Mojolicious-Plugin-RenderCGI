package Mojolicious::Plugin::RenderCGI;

use Mojo::Base 'Mojolicious::Plugin';
#~ use Capture::Tiny qw(capture);
use Mojolicious::Plugin::RenderCGI::CGI;

our $VERSION = '0.001';
my $pkg = __PACKAGE__;
my %cache = ();

sub register
{
  my ($self, $app, $conf) = @_;
  
  $conf->{import} ||= [qw(:html :form)];
  $conf->{import} = [grep /\w/, split(/\s+/, $conf->{import})]
    unless ref $conf->{import};
  $conf->{skip_fatal} //= $app->mode ne 'development' ? 1 : 0;
    
  my $renderer = Mojolicious::Plugin::RenderCGI::CGI->new(
    import=>$conf->{import},
  );
  
  $app->renderer->add_handler(
    cgi => sub {
      my ($r, $c, $output, $options) = @_;
      #~ $app->log->debug($app->dumper($options));
      
      
      # относительный путь шаблона
      my $name = $r->template_name($options);
      
      my $stash = $c->stash($pkg);
      $c->stash($pkg => {stack => []})
        unless $stash;
      $stash ||= $c->stash($pkg);
      my $last_template = $stash->{stack}[-1];
      die "Loops template [$name]!"
        if $last_template && $last_template eq $name;
      push @{$stash->{stack}}, $name;

      # встроенный шаблон
      my $content = $options->{inline};
      
      my ($error, $rend, $from) = (undef, undef, 'inline');
      
      #~ $$output = '';
      unless (defined $content) {# не inline
        # подходящий шаблон из кэша но не inline
        ($rend, $from) = ($cache{$name}, 'cache');
        
        unless ($rend) {# не кэш
          # подходящий шаблон в секции DATA
          ($content, $from) = ($r->get_data_template($options), 'DATA section');#,, $name
          
          unless (defined $content) {
          #  абсолютный путь шаблона
            if (my $path = $r->template_path($options)) {
              my $file = Mojo::Asset::File->new(path => $path);
              ($content, $from) = ($file->slurp, 'file');
              
            } else {
              $error = sprintf(qq{Template "%s" does not exists}, $name);
              $$output = $conf->{skip_fatal} ? '' : $error;
              $app->log->error($error);
              return;
            }
          }
        }
      }
      
      $$output = ''
        or $app->log->debug(sprintf(qq{Empty template "%s"}, $name))
        and return
        unless $rend || defined($content) && $content !~ /^\s*$/;
      
      $rend ||= $renderer->compile($content)
        or ($error = sprintf(qq{Template "%s" is not found}, $name // $from))
        and (($$output = $conf->{skip_fatal} ? '' : $error) || 1)
        and $app->log->error($error)
        and return;
      
      $error = sprintf(qq{Compile error "%s": %s}, $name // $from, $rend)
        and (($$output = $conf->{skip_fatal} ? '' : $error) || 1)
        and $app->log->error($error)
        and return
        unless ref $rend eq 'CODE';

      $app->log->debug(sprintf(qq{Rendering template "%s" from the %s}, $name, $from,));
      $cache{$name} ||= $rend;
      # Передать rendered результат обратно в рендерер
      my @out = eval { $rend->($c, $renderer->{cgi},)};
      
      $error = sprintf(qq{Die on "%s":\n%s}, $name // $from, $@)
        and (($$output = $conf->{skip_fatal} ? '' : $error) || 1)
        and $app->log->error($error)
        and return
        if $@;
      
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

0.001

=head1 NAME

Mojolicious::Plugin::RenderCGI - Rendering template with Perl code CGI.pm subs imports.

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
  $c->include('far', handler=>'cgi'),# change handler against layout
  $c->include('bax'); # handler still "cgi" unless template "bax" (and its includes) didn`t changed it
  h1({}, "Welcome"),
  <<END_HTML,
  <input id="bah" name="bah" type="checkbox" />
  <label for="bah">$foo</label>
  END_HTML
  $self->app->log->info("Template has done")
    && undef,

There are NO Mojolicious helpers without OO-style: B<$c-\>> OR b<$self-\>> prefix.

=head1 Options

=head2 import (string (space delims) | arrayref)

What subs do you want from CGI.pm import

  $app->plugin('RenderCGI', import=>':html -any');
  # or 
  $app->plugin('RenderCGI', import=>[qw(:html -any)]);

See at perldoc CGI.pm section "USING THE FUNCTION-ORIENTED INTERFACE".
Default is ':html :form' (string) same as [qw(:html :form)] (arrayref).

  import=>[], # none import, CGI OO-style only

=head2 skip_fatal (bool)

Show fatal errors (not found, compile and runtime errors) as content of there template.
By default on development mode set to 0 and 1 on production. Works on cgi handler only.

  skip_fatal=>1, 

=head1 SEE ALSO

L<CGI>

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