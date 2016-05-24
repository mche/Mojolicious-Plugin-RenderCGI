use Mojo::Base -strict;

my $cgi = MyCGI->new;

say $cgi->template("h1('123')")->($cgi);

package MyCGI;
use Mojo::Base 'CGI';

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  $class->import(qw(:html));
  return $class->SUPER::new(@_);
  
}

sub template {
  my $self = shift;
  my $code = shift;
  my $sub = eval <<CODE;
sub {
my \$cgi = shift;
$code
}
CODE
  return $@
    if $@;
  return $sub;
  
}
