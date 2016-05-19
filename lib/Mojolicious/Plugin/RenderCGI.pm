package Mojolicious::Plugin::RenderCGI;

use Mojo::Base 'Mojolicious::Plugin';
#~ use Capture::Tiny qw(capture);
use Mojolicious::Plugin::RenderCGI::CGI;

our $VERSION = '0.001';

sub register
{
  my ($self, $app, $conf) = @_;
  
  my $conf->{import} ||= [':html'];
  $conf->{import} = [split(/\s+/, $conf->{import})]
    unless ref $conf->{import};
  
  $app->renderer->add_handler(
    cgi => sub {
      my ($r, $c, $output, $options) = @_;
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
      #~ my ($stdout, $stderr, @result) = capture {
        #~ # your code here
      #~ };
     
      # Передать rendered результат обратно в рендерер
      $$output = join("\n", Mojolicious::Plugin::RenderCGI::CGI
        ->new(import=>$conf->{import})
        ->renderer(
          $inline // $content //  Mojo::Asset::File->new(path => $path)->slurp
        )
      ->($c, $options)
      );
      #~ $$output = 'The rendered result!';
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