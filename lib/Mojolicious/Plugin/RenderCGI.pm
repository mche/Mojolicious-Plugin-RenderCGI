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
  #~ $conf->{fatals} //= $app->mode eq 'development' ? 'exception' : 'template';
  $conf->{fatals} = 'exception';
  $conf->{not_found} //= $app->mode eq 'development' ? 'template' : 'reply';
    
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
                and $c->reply->not_found
                and return
                if $conf->{not_found} eq 'reply';
              $$output = $error;
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
      #~ unless 
        #~ or ($error = sprintf(qq{Template "%s" does not exists?}, $name // $from))
        #~ and $app->log->error($error)
        #~ and $c->stash('handler'=>'ep')
        #~ and ($$output = )
        #~ and (($$output = $conf->{skip_fatals} ? '' : $error) || 1)
        
        #~ and return;
      
      unless (ref $rend eq 'CODE') {
        $error = sprintf(qq{Compile error template "%s": %s}, $name // $from, $rend);
        $app->log->error($error);
        $c->stash('handler'=>'ep')
          and $c->reply->exception($error)
          and return
          if $conf->{fatals} eq 'exception';
        $$output = $error;
        return;
      }

      $app->log->debug(sprintf(qq{Rendering template "%s" from the %s}, $name, $from,));
      $cache{$name} ||= $rend;
      # Передать rendered результат обратно в рендерер
      my @out = eval { $rend->($c,)};
      if ($@) {
        $error = sprintf(qq{Die on "%s":\n%s}, $name // $from, $@);
        $app->log->error($error);
        $c->stash('handler'=>'ep')
          and $c->reply->exception($error)
          and return
          if $conf->{fatals} eq 'exception';
        $$output = $error;
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
  $c->include('far', handler=>'cgi'),# change handler against layout
  $c->include('bax'); # handler still "cgi" unless template "bax" (and its includes) didn`t changes it
  h1({}, "Welcome"),
  <<END_HTML,
  <!-- comment -->
  END_HTML
  $self->app->log->info("Template has done")
    && undef,

There are NO Mojolicious helpers without OO-style: B<$c->> OR B<$self->> prefix.

=head1 Options

=head2 import (string (space delims) | arrayref)

What subs do you want from CGI.pm import

  $app->plugin('RenderCGI', import=>':html -any');
  # or 
  $app->plugin('RenderCGI', import=>[qw(:html -any)]);

See at perldoc CGI.pm section "USING THE FUNCTION-ORIENTED INTERFACE".
Default is ':html :form' (string) same as [qw(:html :form)] (arrayref).

  import=>[], # none import, CGI OO-style only

=head2 skip_fatals (bool)

Show fatal errors (not found, compile and runtime errors) as content of there template.
By default on B<development mode> set to 0 and 1 on B<production>. Works on cgi handler only.

  skip_fatals=>1, 

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