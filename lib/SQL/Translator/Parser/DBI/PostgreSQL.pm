package SQL::Translator::Parser::DBI::PostgreSQL;
use Moose;
use MooseX::Types::Moose qw(Str);
with 'SQL::Translator::Parser::DBI::Dialect';

has 'db_schema' => (is => 'ro', isa => Str, default => 'public');

sub make_create_string { 
   print "HELLO WORLD\n";
   # ..... 
}

sub make_update_string {
   print "WOOT\n";
}

1;
