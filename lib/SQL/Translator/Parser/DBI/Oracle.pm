package SQL::Translator::Parser::DBI::Oracle;
use Moose;
with 'SQL::Translator::Parser::DBI::Dialect';

sub make_create_string {
   print "Oracle!\n";
   # .....
}

sub make_update_string {
   print "Oracle!\n";
}


1;
