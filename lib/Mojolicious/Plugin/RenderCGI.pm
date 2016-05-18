package Mojolicious::Plugin::RenderCGI;

use Mojo::Base 'Mojolicious::Plugin';


our $VERSION = '0.001';

sub register
{
  my ($self, $app, $args) = @_;
  $app->renderer->add_handler(
    cgi => sub {
      my ($r, $c, $output, $options) = @_;
     
      # встроенный шаблон
      my $inline = $options->{inline};
     
      # Сформировать относительный путь шаблона
      my $name = $r->template_name($options);
     
      # Попытка найти подходящий шаблон в секции DATA
      my $content = $r->get_data_template($options, $name);
     
      # Сформировать абсолютный путь шаблона
      my $path = $r->template_path($options);
      
      #
    
    
     
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

  use
  

=head1 Template

  my $foo = $c->stash('foo');
  $self->app->log->info("template rendering");
  say h1({}, $foo);
  say <<END_HTML;
  <input name="bar" type="checkbox" />
  END_HTML