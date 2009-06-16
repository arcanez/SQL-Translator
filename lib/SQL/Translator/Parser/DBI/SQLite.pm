package SQL::Translator::Parser::DBI::SQLite;
use Moose;
with 'SQL::Translator::Parser::DBI::Dialect';

sub make_create_string {
   print "SQLite\n";
   # .....
}

sub make_update_string {
   print "SQLite\n";
}


1;
