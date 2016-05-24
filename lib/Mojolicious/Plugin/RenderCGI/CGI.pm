package Mojolicious::Plugin::RenderCGI::CGI;
use Mojo::Base 'CGI';
#~ use Capture::Tiny qw(capture);

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    $class->import(@_, 'escapeHTML', '-utf8');
    my $cgi = $class->SUPER::new();
    return $cgi;
}


sub template {
  my $self = shift;
  my ($code) = @_;

  my $sub = eval <<CODE;
sub {
my (\$self, \$c,);
\$self = \$c = shift;
my \$cgi = shift;
undef, # может комменты придут без кода
$code
}
CODE
  return $@
    if $@;
  return $sub;
}

sub esc { escapeHTML(@_) }

1;