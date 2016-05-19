use Mojo::Base -strict;

my $a = sub {
  use CGI qw(:html);
  my $a =1;
  
  h1({}, "foo"
  ,'bar'),
  3,
  $a,
  
  
};

say $a->();