package Mojolicious::Plugin::RenderCGI::CGI;
use Mojo::Base -strict;

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self = {};
    bless ($self, $class);
    $self->init(@_);
    return $self;
}

sub init {
  my $self = shift;
  my %arg = @_;
  require CGI;
  CGI->import(@{$arg{import}});
  return $self;
}


sub renderer {
  my $self = shift;
  my ($code) = @_;
  my $t = <<CODE;
sub {
my (\$self, \$c);
\$self = \$c = shift;
$code
}
CODE
  warn $t;
    my $sub = eval $t;
  return sub {qq{Ошибка компиляции шаблона:\n$@}}
    if $@;
  return $sub;
}

1;