package Mojolicious::Plugin::RenderCGI::Template;
use Mojo::Base -base;
use CGI;

has [qw(import cgi content)];
has cgi => sub { CGI->new };

sub new {
    my $self = shift->SUPER::new(@_);
    CGI->import(
      $self->import && ref($self->import) eq 'ARRAY'
        ? @{$self->import}
        : (grep /\w/, split(/\s+/, $self->import)),
      'escapeHTML',
      '-utf8',
    );
    return $self;
}


sub compile {
  my $self = shift;
  my ($code) = @_;

  $self->content(eval <<CODE);
sub {
  my (\$self, \$c, \$cgi) = \@_;
  undef, # может комменты придут без кода
  $code
}
CODE
  return $@
    if $@;
  return $self;
}

sub run {
  my ($self, $c) = @_;
  
  $self->content->($self, $c,$self->cgi);
}

sub esc { escapeHTML(@_) }

#~ our $AUTOLOAD;
sub  AUTOLOAD {
  #~ my ($func) = $AUTOLOAD =~ /([^:]+)$/;
  my ($package, $func) = our $AUTOLOAD =~ /^(.+)::(.+)$/;
  
  my $self = shift;
  *$func = sub { print "I see $name(@_)\n" };
  
  &$func()
}

# Declared here to avoid circular require problems in Mojo::Util
sub _monkey_patch {
  my ($class, %patch) = @_;
  no strict 'refs';
  no warnings 'redefine';
  *{"${class}::$_"} = $NAME->("${class}::$_", $patch{$_}) for keys %patch;
}

1;