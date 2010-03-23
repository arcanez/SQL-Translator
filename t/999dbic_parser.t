use strict;
use warnings;
use Test::More;
use SQL::Translator;
use SQL::Translator::Constants qw(:sqlt_types :sqlt_constants);

my $t   = SQL::Translator->new( trace => 0, from => 'DBIx::Class' );
$| = 1;

my $sql = '';

my $data   = $t->parse( $sql );
my $schema = $t->schema;

isa_ok( $schema, 'SQL::Translator::Object::Schema', 'Schema object' );

done_testing;
