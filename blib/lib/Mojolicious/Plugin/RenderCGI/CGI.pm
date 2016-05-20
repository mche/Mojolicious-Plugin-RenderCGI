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
  CGI->import(@{$arg{import}})
    if @{$arg{import}};
  $self->{cgi} = CGI->new();
  return $self;
}


sub compile {
  my $self = shift;
  my ($code) = @_;

  my $sub = eval <<CODE;
sub {
my (\$self, \$c,);
\$self = \$c = shift;
my \$cgi = shift;
$code
}
CODE
  return qq{Ошибка компиляции шаблона:\n$@}
    if $@;
  return $sub;
}

1;