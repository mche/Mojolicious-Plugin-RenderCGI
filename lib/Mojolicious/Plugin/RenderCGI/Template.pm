package Mojolicious::Plugin::RenderCGI::Template;
use Mojo::Base -base;
use CGI;

has [qw(_import _content)];
has _cgi => sub { CGI->new };

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


sub _compile {
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

sub _run {
  my ($self, $c) = @_;
  
  $self->_content->($self, $c,$self->_cgi);
}

sub esc { escapeHTML(@_) }

#~ our $AUTOLOAD;
sub  AUTOLOAD {
  #~ my ($func) = $AUTOLOAD =~ /([^:]+)$/;
  my ($package, $func) = our $AUTOLOAD =~ /^(.+)::(.+)$/;
  my $tag = $func =~ s/_/-/gr;
  my $package_arg = ref $_[0];
  if ($package eq $package_arg) { # method
    no strict 'refs';
    no warnings 'redefine';
    my $self = shift;
    *{"${package}::$func"} = sub {
      my $self = shift;
      return &CGI::_tag_func($tag,@_);
      
    };
    return $self->$func(@_);
  }
  # non method
    
  *$func = sub { return &CGI::_tag_func($tag,@_); };
  
  return &$func(@_);
}


1;