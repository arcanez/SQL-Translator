package SQL::Translator::Parser::DBI::Dialect;
use Moose::Role;

requires 'make_create_string',
         'make_update_string';

sub do_common_stuff {
    my ($self, @args) = @_;
    print "COMMON STUFF!\n";
    # ....
}

1;
