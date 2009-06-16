package SQL::Translator::Parser::DBI::Sybase;
use Moose;
with 'SQL::Translator::Parser::DBI::Dialect';

sub make_create_string {
   print "Sybase!\n";
   # .....
}

sub make_update_string {
   print "Sybase!\n";
}


1;
