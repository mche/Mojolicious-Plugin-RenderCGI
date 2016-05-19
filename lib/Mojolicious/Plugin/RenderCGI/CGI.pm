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
  CGI->import(@{$arg->{import}})
  
}

