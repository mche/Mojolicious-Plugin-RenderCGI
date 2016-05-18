package Mojolicious::Plugin::RenderCGI;

use Mojo::Base 'Mojolicious::Plugin';
use Capture::Tiny qw(capture);

our $VERSION = '0.001';

sub register
{
  my ($self, $app, $args) = @_;
  $app->renderer->add_handler(
    cgi => sub {
      my ($r, $c, $output, $options) = @_;
      $options->{'format'} = 'cgi';
     
      # встроенный шаблон
      my $inline = $options->{inline};
     
      # относительный путь шаблона
      my $name = $r->template_name($options);
     
      # подходящий шаблон в секции DATA
      my $content = $r->get_data_template($options, $name);
     
      #  абсолютный путь шаблона
      my $path = $r->template_path($options);
      
      #
      # capture from arbitrary code (Perl or external)
 
      my ($stdout, $stderr, @result) = capture {
        # your code here
      };
    
     
      # Передать rendered результат обратно в рендерер
      $$output = 'The rendered result!';
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
  

=head1 Template

  my $foo = $c->stash('foo');
  $self->app->log->info("template rendering");
  $c->include('far');
  say h1({}, $foo);
  say <<END_HTML;
  <input name="bah" type="checkbox" />
  END_HTML
  

There are NO helpers without B<$c-\>> OR b<$self-\>> prefix.

=head1 Options

=head2 import

  $app->plugin('RenderCGI', import=>':html -any');

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