package Mojolicious::Plugin::RenderCGI::CGI;
use Mojo::Base -strict;

my $cgi;

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
  push @{$arg{import}}, 'escapeHTML';
  require CGI;
  CGI->import(@{$arg{import}});
  $cgi = CGI->new();
  return $self;
}


sub compile {
  my $self = shift;
  my ($code) = @_;

  my $sub = eval <<CODE;
sub {
my (\$self, \$c,);
\$self = \$c = shift;
$code
}
CODE
  return $@
    if $@;
  return $sub;
}

sub esc { escapeHTML(@_) }

1;