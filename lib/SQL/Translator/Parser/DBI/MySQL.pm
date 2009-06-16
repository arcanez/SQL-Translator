package SQL::Translator::Parser::DBI::MySQL;
use Moose;
with 'SQL::Translator::Parser::DBI::Dialect';

sub make_create_string {
   print "MYSQL!\n";
   # .....
}

sub make_update_string {
   print "mYSQL!\n";
}


1;
