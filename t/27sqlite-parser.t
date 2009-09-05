use strict;
use warnings;
use Test::More;
use FindBin qw/$Bin/;
use SQL::Translator;
use SQL::Translator::Constants qw(:sqlt_types :sqlt_constants);

my $file = "$Bin/data/sqlite/create.sql";

{
    local $/;
    open my $fh, "<$file" or die "Can't read file '$file': $!\n";
    my $data = <$fh>;
    my $t = SQL::Translator->new({ from => 'SQLite' });
    $t->parse($data);

    my $schema = $t->schema;

    my @tables = $schema->get_tables;
    is( scalar @tables, 2, 'Parsed two tables' );

    my $t1 = shift @tables;
    is( $t1->name, 'person', "'Person' table" );

    my @fields = $t1->get_fields;
    is( scalar @fields, 6, 'Six fields in "person" table');
    my $fld1 = shift @fields;
    is( $fld1->name, 'person_id', 'First field is "person_id"');
    is( $fld1->is_auto_increment, 1, 'Is an autoincrement field');

    my $t2 = shift @tables;
    is( $t2->name, 'pet', "'Pet' table" );

    my @constraints = $t2->get_constraints;
    is( scalar @constraints, 3, '3 constraints on pet' );

    my $c1 = pop @constraints;
    is( $c1->type, 'FOREIGN KEY', 'FK constraint' );
    is( $c1->reference_table, 'person', 'References person table' );
    is( join(',', $c1->reference_fields), 'person_id', 
        'References person_id field' );

    my @views = $schema->get_views;
    is( scalar @views, 1, 'Parsed one views' );

    my @triggers = $schema->get_triggers;
    is( scalar @triggers, 1, 'Parsed one triggers' );

    done_testing;
}
