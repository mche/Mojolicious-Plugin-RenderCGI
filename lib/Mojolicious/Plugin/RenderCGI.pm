package Mojolicious::Plugin::RenderCGI;

use Mojo::Base 'Mojolicious::Plugin';
#~ use Capture::Tiny qw(capture);
use Mojolicious::Plugin::RenderCGI::CGI;

our $VERSION = '0.001';

my %cache = ();
my $last_template;

sub register
{
  my ($self, $app, $conf) = @_;
  
  $conf->{import} ||= [':html'];
  $conf->{import} = [grep $_, split(/\s+/, $conf->{import})]
    unless ref $conf->{import};
    
  my $renderer = Mojolicious::Plugin::RenderCGI::CGI->new(
    import=>$conf->{import}
  );
  
  $app->renderer->add_handler(
    cgi => sub {
      my ($r, $c, $output, $options) = @_;
      #~ $app->log->debug($app->dumper($options));
      
      
      # относительный путь шаблона
      my $name = $r->template_name($options);
      
      die "Loops template [$name]!"
        if $name && $last_template && $last_template eq $name;
      $last_template = $name;
      
      # встроенный шаблон
      my $content = $options->{inline};
      
      my ($rend, $from) = (undef, 'inline');
      
      
      unless (defined $content) {# не inline
        # подходящий шаблон из кэша но не inline
        ($rend, $from) = ($cache{$name}, 'cache');
        
        unless ($rend) {# не кэш
          # подходящий шаблон в секции DATA
          ($content, $from) = ($r->get_data_template($options), 'DATA section');#,, $name
          unless (defined $content) {
          #  абсолютный путь шаблона
            my $path = $r->template_path($options);
            ($content, $from) = (Mojo::Asset::File->new(path => $path)->slurp, 'file');
          }
        }
      }
        
      $rend ||= $renderer->renderer($content)
        if defined $content;
        
      $$output = sprintf(qq{Template "%s" not found}, $name // $from);
      $app->log->debug($$output)
        and return
        unless $rend;

      $app->log->debug(sprintf(qq{Rendering template "%s" from %s}, $name, $from,));
    
      # Передать rendered результат обратно в рендерер
      $$output = join("\n", $rend->($c,), '');
      
      $cache{$name} ||= $rend;
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

Mojolicious::Plugin::RenderCGI - Rendering template with Perl code CGI.pm subs exports.

=head1 SYNOPSIS

  $app->plugin('RenderCGI');
  
  # Set as default handler
  $app->renderer->default_handler('cgi');
 
  # Render without setting as default handler
  $c->render(handler => 'cgi');
  

=head1 Template

  # $c and $self already are controller
  $c->layout('default', handler=>'ep',);
  my $foo = $c->stash('foo');
  $self->app->log->info("template rendering");
  #=======================================
  #======= content comma list! ===========
  #=======================================
  $c->include('far'),
  $c->include('bax', handler=>'ep');
  h1({}, "Welcome"),
  <<END_HTML,
  <input id="bah" name="bah" type="checkbox" />
  <label for="bah">$foo</label>
  END_HTML
  ...

There are NO helpers without B<$c-\>> OR b<$self-\>> prefix.

=head1 Options

=head2 import

  $app->plugin('RenderCGI', import=>':html -any');
  # or 
  $app->plugin('RenderCGI', import=>[qw(:html -any)]);

See at perldoc CGI.pm section "USING THE FUNCTION-ORIENTED INTERFACE". Default is ':html' (string) or [qw(:html)] (arrayref).


=head1 SEE ALSO

L<Mojolicious::Plugin::TagHelpers>

=head1 AUTHOR

Михаил Че (Mikhail Che), C<< <mche[-at-]cpan.org> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests at L<https://github.com/mche/Mojolicious-Plugin-RenderCGI/issues>. Pull requests also welcome.

=head1 COPYRIGHT

Copyright 2016 Mikhail Che.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut