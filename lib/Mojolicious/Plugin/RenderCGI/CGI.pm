package Mojolicious::Plugin::RenderCGI::CGI;
use Mojo::Base 'CGI';
#~ use Capture::Tiny qw(capture);

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    $class->import(qw(:html), 'escapeHTML');
    return $class->SUPER::new(@_);
    #~ my $self = {};
    #~ bless ($self, $class);
    #~ $self->init(@_);
    #~ return $self;
}

sub 000init {
  my $self = shift;
  my %arg = @_;
  $arg{import} = [grep /\w/, split(/\s+/, $arg{import})]
    unless ref $arg{import} eq 'ARRAY';
  push @{$arg{import}}, 'escapeHTML';
  require CGI;
  CGI->import(@{$arg{import}});
  $self->{cgi} = CGI->new();
  return $self;
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