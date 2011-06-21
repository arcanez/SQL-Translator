$| = 1;
use warnings;
use strict;
use Test::More; # tests => 238;
use Test::Exception;
use SQL::Translator::Constants qw(:sqlt_types :sqlt_constants);

require_ok( 'SQL::Translator' );
require_ok( 'SQL::Translator::Object::Column' );
require_ok( 'SQL::Translator::Object::Constraint' );
require_ok( 'SQL::Translator::Object::Index' );
require_ok( 'SQL::Translator::Object::Procedure' );
require_ok( 'SQL::Translator::Object::Schema' );
require_ok( 'SQL::Translator::Object::Table' );
require_ok( 'SQL::Translator::Object::Trigger' );
require_ok( 'SQL::Translator::Object::View' );

{
    #
    # Schema
    #
    my $schema = SQL::Translator::Object::Schema->new( 
        name => 'foo',
        database => 'MySQL',
    );
    isa_ok( $schema, 'SQL::Translator::Object::Schema' );

    is( $schema->name, 'foo', 'Schema name is "foo"' );
    is( $schema->name('bar'), 'bar', 'Schema name changed to "bar"' );

    is( $schema->database, 'MySQL', 'Schema database is "MySQL"' );
    is( $schema->database('PostgreSQL'), 'PostgreSQL', 
        'Schema database changed to "PostgreSQL"' );

    is( $schema->is_valid, undef, 'Schema not valid...' );
#    like( $schema->error, qr/no tables/i, '...because there are no tables' );

    #
    # $schema->add_*
    #
    my $foo_table = SQL::Translator::Object::Table->new({ name => 'foo' });
    $schema->add_table($foo_table) or warn $schema->error;
    isa_ok( $foo_table, 'SQL::Translator::Object::Table', 'Table "foo"' );

    my $bar_table = SQL::Translator::Object::Table->new({ name => 'bar' }) or 
        warn SQL::Translator::Object::Table->error;
    $schema->add_table( $bar_table );
    isa_ok( $bar_table, 'SQL::Translator::Object::Table', 'Table "bar"' );
    is( $bar_table->name, 'bar', 'Add table "bar"' );

    $schema = $bar_table->schema( $schema );
    isa_ok( $schema, 'SQL::Translator::Object::Schema', 'Schema' );

    dies_ok(sub { $bar_table->name('foo') }, '...because "foo" exists');

#    is( $bar_table->name('foo'), undef, 
#        q[Can't change name of table "bar" to "foo"...]);
#    like( $bar_table->error, qr/can't use table name/i, 
#        q[...because "foo" exists] );

    my $redundant_table = new SQL::Translator::Object::Table({ name => 'foo' });
    dies_ok(sub { $schema->add_table($redundant_table) }, '...because "foo" exists"');
    #is( $redundant_table, undef, qq[Can't create another "foo" table...] );
    #like( $schema->error, qr/can't use table name/i, 
    #    '... because "foo" exists' );

    $redundant_table = new SQL::Translator::Object::Table({ name => '' });
#    is( $redundant_table, undef, qq[Can't add an anonymous table...] );
#    like( $schema->error, qr/No table name/i,
#        '... because it has no name ' );
    dies_ok(sub { $schema->add_table($redundant_table) }, '...because it has no name'); 

    $redundant_table = SQL::Translator::Object::Table->new({ name => '' });
    #is( $redundant_table, undef, qq[Can't create an anonymous table] );
    #like( SQL::Translator::Object::Table->error, qr/No table name/i,
    #    '... because it has no name ' );
    dies_ok(sub { $schema->add_table($redundant_table) }, '...because it has no name');

    #
    # $schema-> drop_table
    #
    my $dropped_table = $schema->drop_table($foo_table->name, cascade => 1);
    isa_ok($dropped_table, 'SQL::Translator::Object::Table', 'Dropped table "foo"' );
    $schema->add_table($foo_table);
    my $dropped_table2 = $schema->drop_table($foo_table, cascade => 1);
    isa_ok($dropped_table2, 'SQL::Translator::Object::Table', 'Dropped table "foo" by object' );
    dies_ok(sub { my $dropped_table3 = $schema->drop_table($foo_table->name, cascade => 1) }, qq[Can't drop non-existant table "foo"]);
#    my $dropped_table3 = $schema->drop_table($foo_table->name, cascade => 1);
#    like( $schema->error, qr/doesn't exist/, qq[Can't drop non-existant table "foo"] );

    $schema->add_table($foo_table);
    #
    # Table default new
    #
    is( $foo_table->name, 'foo', 'Table name is "foo"' );
    is( "$foo_table", 'foo', 'Table stringifies to "foo"' );
    is( $foo_table->is_valid, undef, 'Table "foo" is not yet valid' );

    my $fields = $foo_table->get_fields;
    is( scalar @{ $fields || [] }, 0, 'Table "foo" has no fields' );
    #like( $foo_table->error, qr/no fields/i, 'Error for no fields' );

    is( $foo_table->comments, '', 'No comments' );

    #
    # New table with args
    #
    my $person_table = SQL::Translator::Object::Table->new({ 
        name     => 'person', 
        schema   => $schema,
        comments => 'foo',
    });

    $schema->add_table($person_table);
    is( $person_table->name, 'person', 'Table name is "person"' );
    is( $person_table->is_valid, undef, 'Table is not yet valid' );
    is( $person_table->comments, 'foo', 'Comments = "foo"' );
    is( join(',', $person_table->comments('bar')), 'foo,bar', 'Table comments = "foo,bar"' );
    is( $person_table->comments, "foo\nbar", 'Table comments = "foo,bar"' );

    #
    # Field default new
    #
    my $person_table_column = SQL::Translator::Object::Column->new( name => 'foo', extra => { foo => 'bar', baz => 'quux' } );
    my $f1 = $person_table->add_column($person_table_column);
    isa_ok( $f1, 'SQL::Translator::Object::Column', 'Column' );
    is( $f1->name, 'foo', 'Field name is "foo"' );
    is( $f1->full_name, 'person.foo', 'Field full_name is "person.foo"' );
    is( "$f1", 'foo', 'Field stringifies to "foo"' );
    is( $f1->data_type, '', 'Field data type is blank' );
    is( $f1->size, 0, 'Field size is "0"' );
    is( $f1->is_primary_key, '0', 'Field is_primary_key is false' );
    is( $f1->is_nullable, 1, 'Field can be NULL' );
    is( $f1->default_value, undef, 'Field default is undefined' );
    is( $f1->comments, '', 'No comments' );
    is( $f1->table, 'person', 'Field table is person' );
    is( $f1->schema->database, 'PostgreSQL', 'Field schema shortcut works' );

    my $f2 = SQL::Translator::Object::Column->new ({ name => 'f2', });
    $f2->comments('foo');
    $f2 = $person_table->add_column( $f2 );
    isa_ok( $f1, 'SQL::Translator::Object::Column', 'f2' );
    is( $f2->name, 'f2', 'Add field "f2"' );
    is( $f2->is_nullable(0), 0, 'Field cannot be NULL' );
#    is( $f2->is_nullable(''), 0, 'Field cannot be NULL' );
    is( $f2->is_nullable('0'), 0, 'Field cannot be NULL' );
    is( $f2->default_value(''), '', 'Field default is empty string' );
    is( $f2->comments, 'foo', 'Field comment = "foo"' );
    is( join(',', $f2->comments('bar')), 'foo,bar', 'Field comment = "foo,bar"' );
    is( $f2->comments, "foo\nbar", 'Field comment = "foo,bar"' );

    $person_table = $f2->table( $person_table );
    isa_ok( $person_table, 'SQL::Translator::Object::Table', 'person_table' );

    #is( $f2->name('foo'), undef, q[Can't set field name of "f2" to "foo"...] );
    dies_ok(sub { $f2->name('foo') }, q[Can't set field name of "f2" to "foo"...] . '...because name exists');
    #like( $f2->error, qr/can't use field name/i, '...because name exists' );

#    my $redundant_field = $person_table->add_field(name => 'f2');
#    is( $redundant_field, undef, qq[Didn't create another "f2" field...] );
#    like( $person_table->error, qr/can't use field/i, 
#        '... because it exists' );
    dies_ok(sub { my $redundant_field = $person_table->add_column({ name => 'f2' }); }, qq[Didn't create another "f2" field...] . '... because it exists' );

#    my $redundant_field = $person_table->add_column({ name => '' });
#    is( $redundant_field, undef, qq[Didn't add a "" field...] );
#    like( $person_table->error, qr/No field name/i,
#        '... because it has no name' );
    dies_ok(sub { my $redundant_field = $person_table->add_column({ name => '' }) }, qq[Didn't add a "" field...] . '... because it has no name' );

#    my $redundant_field = SQL::Translator::Object::Column->new(name => '');
#    is( $redundant_field, undef, qq[Didn't create a "" field...] );
#    like( SQL::Translator::Object::Column->error, qr/No field name/i,
#        '... because it has no name' );
     dies_ok(sub { my $redundant_field = SQL::Translator::Object::Column->new({ name => '' }) }, qq[Didn't create a "" field...] . '... because it has no name' );

    my @fields = $person_table->get_fields;
    is( scalar @fields, 2, 'Table "foo" has 2 fields' );

    is( $fields[0]->name, 'foo', 'First field is "foo"' );
    is( $fields[1]->name, 'f2', 'Second field is "f2"' );
    is( join(",",$person_table->fields), 'foo,f2', 'field_names is "foo,f2"' );

    #
    # $table-> drop_column
    #
    my $dropped_field = $person_table->drop_column($f2->name, cascade => 1);
    isa_ok($dropped_field, 'SQL::Translator::Object::Column', 'Dropped field "f2"' );
    $person_table->add_column($f2);
    my $dropped_field2 = $person_table->drop_column($f2, cascade => 1);
    isa_ok($dropped_field2, 'SQL::Translator::Object::Column', 'Dropped field "f2" by object' );
#    my $dropped_field3 = $person_table->drop_column($f2->name, cascade => 1);
#    like( $person_table->error, qr/doesn't exist/, qq[Can't drop non-existant field "f2"] );
    dies_ok(sub { $person_table->drop_column($f2->name, cascade => 1); }, qq[Can't drop non-existant field "f2"]);

    $person_table->add_field($f2);

    #
    # Field methods
    #
    is( $f1->name('person_name'), 'person_name', 'Field name is "person_name"' );
    is( $f1->data_type('varchar'), 'varchar', 'Field data type is "varchar"' );
    is( $f1->size('30'), '30', 'Field size is "30"' );
    is( $f1->is_primary_key(0), '0', 'Field is_primary_key is negative' );
    $person_table->add_field( $f1 );

    my %extra = $f1->extra;
    is( $extra{'foo'}, 'bar', 'Field extra "foo" is "bar"' );
    is( $extra{'baz'}, 'quux', 'Field extra "baz" is "quux"' );

    #
    # New field with args
    #
    my $age       = $person_table->add_field({
        name      => 'age',
        data_type => 'float',
        size      => '10,2',
    });

    is( $age->name, 'age', 'Field name is "age"' );
    is( $age->data_type, 'float', 'Field data type is "float"' );
    is( $age->size, '10,2', 'Field size is "10,2"' );
    is( $age->size(10,2), '10,2', 'Field size still "10,2"' );
    is( $age->size([10,2]), '10,2', 'Field size still "10,2"' );
    is( $age->size(qw[ 10 2 ]), '10,2', 'Field size still "10,2"' );
    is( join(':', $age->size), '10:2', 'Field size returns array' );

    #
    # Index
    #
    my @indices = $person_table->get_indices;
    is( scalar @indices, 0, 'No indices' );
    #like( $person_table->error, qr/no indices/i, 'Error for no indices' );
#    my $index1 = $person_table->add_index(SQL::Translator::Object::Index->new( name => "foo" )) ;
    my $index1 = $person_table->add_index({ name => "foo" });
    isa_ok( $index1, 'SQL::Translator::Object::Index', 'Index' );
    is( $index1->name, 'foo', 'Index name is "foo"' );

    is( $index1->is_valid, undef, 'Index name is not valid...' );
#    like( $index1->error, qr/no fields/i, '...because it has no fields' );

#    is( join(':', $index1->fields('foo,bar')), 'foo:bar', 'Index accepts fields');

#    is( $index1->is_valid, undef, 'Index name is not valid...' );
#    like( $index1->error, qr/does not exist in table/i, '...because it used fields not in the table' );
    dies_ok(sub { $index1->fields('foo,bar') }, 'because it used fields not in the table');

    is( join(':', $index1->fields('person_name,age')), 'person_name:age', 'Index accepts fields');
    #is( join(':', $index1->fields(qw/foo age/)), 'foo:age', 'Index accepts fields');
    is( $index1->is_valid, 1, 'Index name is now valid' );

    is( $index1->type, NORMAL, 'Index type is "normal"' );

    my $index2 = SQL::Translator::Object::Index->new( name => "bar" );

    $index2 = $person_table->add_index( $index2 );
    isa_ok( $index2, 'SQL::Translator::Object::Index', 'Index' );
    is( $index2->name, 'bar', 'Index name is "bar"' );

    @indices = $person_table->get_indices;
    is( scalar @indices, 2, 'Two indices' );
    is( $indices[0]->name, 'foo', '"foo" index' );
    is( $indices[1]->name, 'bar', '"bar" index' );

    #
    # $table-> drop_index
    #
    my $dropped_index = $person_table->drop_index($index1->name);
    isa_ok($dropped_index, 'SQL::Translator::Object::Index', 'Dropped index "foo"' );
    $person_table->add_index($index1);
    my $dropped_index2 = $person_table->drop_index($index1);
    isa_ok($dropped_index2, 'SQL::Translator::Object::Index', 'Dropped index "foo" by object' );
    is($dropped_index2->name, $index1->name, 'Dropped correct index "foo"');
#    my $dropped_index3 = $person_table->drop_index($index1->name);
#    like( $person_table->error, qr/doesn't exist/, qq[Can't drop non-existant index "foo"] );
    dies_ok(sub { $person_table->drop_index($index1->name) }, qq[Can't drop non-existant index "foo"] );

    $person_table->add_index($index1);

    #
    # Constraint
    #
    my @constraints = $person_table->get_constraints;
    is( scalar @constraints, 0, 'No constraints' );
    #like( $person_table->error, qr/no constraints/i, 'Error for no constraints' );
    my $constraint1 = $person_table->add_constraint({ name => 'foo', type => 'bar' });

    isa_ok( $constraint1, 'SQL::Translator::Object::Constraint', 'Constraint' );
    is( $constraint1->name, 'foo', 'Constraint name is "foo"' );

    $fields = join(',', $constraint1->fields('age') );
    is( $fields, 'age', 'Constraint field = "age"' );

    $fields = $constraint1->fields;
    ok( ref $fields[0] && $fields[0]->isa("SQL::Translator::Object::Column"),
        'Constraint fields returns a SQL::Translator::Object::Column' );

    $fields = join(',', $constraint1->fields('age,age') );
    is( $fields, 'age', 'Constraint field = "age"' );

#    $fields = join(',', $constraint1->fields('age', 'name') );
#    is( $fields, 'age,person_name', 'Constraint field = "age,name"' );

    $fields = join(',', $constraint1->fields( 'age,person_name,age' ) );
    is( $fields, 'age,person_name', 'Constraint field = "age,name"' );

    $fields = join(',', $constraint1->fields( 'age, person_name' ) );
    is( $fields, 'age,person_name', 'Constraint field = "age,name"' );

    $fields = join(',', $constraint1->fields( [ 'age', 'person_name' ] ) );
    is( $fields, 'age,person_name', 'Constraint field = "age,name"' );

#    $fields = join(',', $constraint1->fields( qw[ age person_name ] ) );
#    is( $fields, 'age,person_name', 'Constraint field = "age,name"' );

    $fields = join(',', $constraint1->field_names );
    is( $fields, 'age,person_name', 'Constraint field_names = "age,name"' );

    is( $constraint1->match_type, '', 'Constraint match type is empty' );
#    is( $constraint1->match_type('foo'), undef, 
#        'Constraint match type rejects bad arg...' );
#    like( $constraint1->error, qr/invalid match type/i,
#        '...because it is invalid');
    dies_ok(sub { $constraint1->match_type('foo') }, '...because it is invalid');
    is( $constraint1->match_type('FULL'), 'full', 
        'Constraint match type = "full"' );

    my $constraint2 = SQL::Translator::Object::Constraint->new( name => 'bar', type => 'baz' );
    $constraint2    = $person_table->add_constraint( $constraint2 );
    isa_ok( $constraint2, 'SQL::Translator::Object::Constraint', 'Constraint' );
    is( $constraint2->name, 'bar', 'Constraint name is "bar"' );

    my $constraint3 = $person_table->add_constraint({
        type       => 'check',
        expression => 'foo bar',
    }); # or die $person_table->error;
    isa_ok( $constraint3, 'SQL::Translator::Object::Constraint', 'Constraint' );
    is( $constraint3->type, 'check', 'Constraint type is "CHECK"' ); ## CHECK_C
    is( $constraint3->expression, 'foo bar', 'Constraint expression is "foo bar"' );

    @constraints = $person_table->get_constraints;
    is( scalar @constraints, 3, 'Three constraints' );
    is( $constraints[0]->name, 'foo', '"foo" constraint' );
    is( $constraints[1]->name, 'bar', '"bar" constraint' );

    #
    # $table-> drop_constraint
    #
    my $dropped_con = $person_table->drop_constraint($constraint1->name);
    isa_ok($dropped_con, 'SQL::Translator::Object::Constraint', 'Dropped constraint "foo"' );
    $person_table->add_constraint($constraint1);
    my $dropped_con2 = $person_table->drop_constraint($constraint1);
    isa_ok($dropped_con2, 'SQL::Translator::Object::Constraint', 'Dropped constraint "foo" by object' );
    is($dropped_con2->name, $constraint1->name, 'Dropped correct constraint "foo"');
#    my $dropped_con3 = $person_table->drop_constraint($constraint1->name);
#    like( $person_table->error, qr/doesn't exist/, qq[Can't drop non-existant constraint "foo"] );
    dies_ok(sub { $person_table->drop_constraint($constraint1->name) }, qq[Can't drop non-existant constraint "foo"] );

    $person_table->add_constraint($constraint1);

    #
    # View
    #
    my $view = $schema->add_view({ name => 'view1' }) or warn $schema->error;
    isa_ok( $view, 'SQL::Translator::Object::View', 'View' );
    my $view_sql = 'select * from table';
    is( $view->sql( $view_sql ), $view_sql, 'View SQL is good' );

    my $view2 = SQL::Translator::Object::View->new(name => 'view2') or
        warn SQL::Translator::Object::View->error;
    my $check_view = $schema->add_view( $view2 );
    is( $check_view->name, 'view2', 'Add view "view2"' );

    dies_ok(sub { my $redundant_view = $schema->add_view({ name => 'view2' }) }, '... because it exists');
#    my $redundant_view = $schema->add_view({ name => 'view2' });
#    is( $redundant_view, undef, qq[Didn't create another "view2" view...] );
#    like( $schema->error, qr/can't create view/i, '... because it exists' );

    #
    # $schema-> drop_view
    #
    my $dropped_view = $schema->drop_view($view->name);
    isa_ok($dropped_view, 'SQL::Translator::Object::View', 'Dropped view "view1"' );
    $schema->add_view($view);
    my $dropped_view2 = $schema->drop_view($view);
    isa_ok($dropped_view2, 'SQL::Translator::Object::View', 'Dropped view "view1" by object' );
    is($dropped_view2->name, $view->name, 'Dropped correct view "view1"');
#    my $dropped_view3 = $schema->drop_view($view->name);
#    like( $schema->error, qr/doesn't exist/, qq[Can't drop non-existant view "view1"] );
    dies_ok(sub { my $dropped_view3 = $schema->drop_view($view->name) }, qq[Can't drop non-existant view "view1"] );

    $schema->add_view($view);

    #
    # $schema->get_*
    #
    
TODO: {
    local $TODO = 'patch Moose Native::Trait';
    dies_ok( sub { my $bad_table = $schema->get_table }, 'Error on no arg to get_table' );
}
    is($schema->get_table('baz'), undef, 'Nonexistant table returns undef');

TODO: {
    local $TODO = 'patch Moose Native::Trait';
    dies_ok( sub { my $bad_view = $schema->get_view }, 'Error on no arg to get_view' );
}
    is($schema->get_view('baz'), undef, 'Nonexistant view returns undef');

    my $good_table = $schema->get_table('foo');
    isa_ok( $good_table, 'SQL::Translator::Object::Table', 'Table "foo"' );

    my $good_view = $schema->get_view('view1');
    isa_ok( $good_view, 'SQL::Translator::Object::View', 'View "view1"' );
    is( $view->sql( $view_sql ), $view_sql, 'View SQL is good' );

    #
    # $schema->get_*s
    #
    my @tables = $schema->get_tables;
    is( scalar @tables, 3, 'Found 2 tables' );

    my @views = $schema->get_views;
    is( scalar @views, 2, 'Found 1 view' );

}

#
# Test ability to introspect some values
#
{ 
    my $s        =  SQL::Translator::Object::Schema->new( 
        name     => 'foo',
        database => 'PostgreSQL',
    );
    my $t = $s->add_table({ name => 'person' }) or warn $s->error;
    my $f = $t->add_field({ name => 'person_id' }) or warn $t->error;
    $f->data_type('serial');

    my $c          = $t->add_constraint({
        type       => PRIMARY_KEY,
#        fields     => 'person_id',
    }) or warn $t->error;
    $c->add_column($f);

    is( $f->is_primary_key, 1, 'Field is PK' );
    is( $f->is_auto_increment, 1, 'Field is auto inc' );
}

#
# FK constraint validity
#
{
    my $s = SQL::Translator::Object::Schema->new;
    my $t = $s->add_table({ name => 'person' });
#    my $c = $t->add_constraint({ });

    dies_ok( sub { my $c = $t->add_constraint({ }) }, '...because it has no type' );

#    is( $c->is_valid, undef, 'Constraint on "person" not valid...');
#    like( $c->error, qr/no type/i, '...because it has no type' );

#    is( $c->type( FOREIGN_KEY ), FOREIGN_KEY, 'Constraint type now a FK' );

#    is( $c->is_valid, undef, 'Constraint on "person" not valid...');
#    like( $c->error, qr/no fields/i, '...because it has no fields' );
#    dies_ok( sub { my $c = $t->add_constraint({ type => FOREIGN_KEY }) }, '...because it has no fields' );

#    is( join('', $c->fields('foo')), 'foo', 'Fields now = "foo"' );
    dies_ok( sub { my $c = $t->add_constraint({ type => FOREIGN_KEY, fields => 'foo' }) }, q[...because field "foo" doesn't exist] );

#    is( $c->is_valid, undef, 'Constraint on "person" not valid...');
#    like( $c->error, qr/non-existent field/i, q[...because field "foo" doesn't exist] );

    my $fk = $t->add_field({ name => 'pet_id' });
    is( $fk->name, 'pet_id', 'Added field "pet_id"' );
#    is( join('', $c->fields('pet_id')), 'pet_id', 'Fields now = "pet_id"' );

    $t->add_field({ name => 'f1' });
    $t->add_field({ name => 'f2' });
#    is( join(',', $c->fields('f1,f2')), 'f1,f2', 'Fields now = "f1,f2"' );
#    is( $c->is_valid, undef, 'Constraint on "person" not valid...');
#    like( $c->error, qr/only one field/i, 
#        q[...because too many fields for FK] );

#    $c->fields('f1');

#    is( $c->is_valid, undef, 'Constraint on "person" not valid...');
#    like( $c->error, qr/no reference table/i, 
#        q[...because there's no reference table] );

#    is( $c->reference_table('foo'), 'foo', 'Reference table now = "foo"' );
#    is( $c->is_valid, undef, 'Constraint on "person" not valid...');
#    like( $c->error, qr/no table named/i, 
#        q[...because reference table "foo" doesn't exist] );

    dies_ok( sub { my $c = $t->add_constraint({ type => FOREIGN_KEY, fields => [ 'f1', 'f2' ], reference_table => 'foo'}) }, "...because reference table foo doesn't exist" );

    my $t2 = $s->add_table({ name => 'pet' });
    is( $t2->name, 'pet', 'Added "pet" table' );

    dies_ok( sub { my $c = $t->add_constraint({ type => FOREIGN_KEY, reference_table => 'pet' }) }, '...because there are no reference fields' );

#    is( $c->reference_table('pet'), 'pet', 'Reference table now = "pet"' );

#    is( $c->is_valid, undef, 'Constraint on "person" not valid...');
    #like( $c->error, qr/no reference fields/i,
    #    q[...because there're no reference fields]);

##    is( join('', $c->reference_fields('pet_id')), 'pet_id', 
##        'Reference fields = "pet_id"' );

##    is( $c->is_valid, undef, 'Constraint on "person" not valid...');
    #like( $c->error, qr/non-existent field/i,
    #    q[...because there's no "pet_id" field in "pet"]);

    my $pet_id = $t2->add_column({ name => 'pet_id' });
    is( $pet_id->name, 'pet_id', 'Added field "pet_id"' );
    
##    is( $c->is_valid, 1, 'Constraint now valid' );
}

#
# $table->primary_key test
#
{
    my $s = SQL::Translator::Object::Schema->new;
    my $t = $s->add_table({ name => 'person' });

    is( $t->primary_key, undef, 'No primary key' );

#    is( $t->primary_key('person_id'), undef, 
#            q[Can't make PK on "person_id"...] );
#    like( $t->error, qr/invalid field/i, "...because it doesn't exist" );
    dies_ok( sub { $t->primary_key('person_id') }, "...because it doesn't exist" );

    $t->add_field({ name => 'person_id' });
    my $c = $t->primary_key('person_id');

    isa_ok( $c, 'SQL::Translator::Object::Constraint', 'Constraint' );

    is( join('', $c->fields), 'person_id', 'Constraint now on "person_id"' );

    $t->add_field({ name => 'name' });
    $c = $t->primary_key('name');
    is( join(',', $c->fields), 'person_id,name', 
        'Constraint now on "person_id" and "name"' );

    #is( scalar @{ $t->get_constraints }, 1, 'Found 1 constraint' );
    is( scalar $t->get_constraints, 1, 'Found 1 constraint' );
}

#
# FK finds PK
#
{
    my $s  = SQL::Translator::Object::Schema->new;
    my $t1 = $s->add_table({ name => 'person' });
    my $t2 = $s->add_table({ name => 'pet' });
    $t1->add_field({ name => 'id' });
    my $c1 = $t1->primary_key( 'id' );
    is( $c1->type, PRIMARY_KEY, 'Made "person_id" PK on "person"' );

    $t2->add_field({ name => 'person_id' });
    my $c2 = $t2->add_constraint({
        type            => PRIMARY_KEY,
        fields          => 'person_id',
        reference_table => 'person',
        table           => $t1,
#        reference_fields => 'id',
    });
    $c2->add_reference_column($t1->get_column('id'));

    is( join('', $c2->reference_fields), 'id', 'FK found PK "person.id"' );
}

#
# View
#
{
    my $s      = SQL::Translator::Object::Schema->new({ name => 'ViewTest' });
    my $name   = 'foo_view';
    my $sql    = 'select name, age from person';
    my $fields = 'name, age';
    my $v      = $s->add_view({
        name   => $name,
        sql    => $sql,
#        fields => $fields,
#        columns => $fields,
        schema => $s,
    });

    $v->add_column({ name => 'name' });
    $v->add_column({ name => 'age' });

    isa_ok( $v, 'SQL::Translator::Object::View', 'View' );
    isa_ok( $v->schema, 'SQL::Translator::Object::Schema', 'Schema' );
    is( $v->schema->name, 'ViewTest', qq[Schema name is "'ViewTest'"] );
    is( $v->name, $name, qq[Name is "$name"] );
    is( $v->sql, $sql, qq[Name is "$sql"] );
    is( join(':', $v->fields), 'name:age', qq[Fields are "$fields"] );

    my @views = $s->get_views;
    is( scalar @views, 1, 'Number of views is 1' );

    my $v1 = $s->get_view( $name );
    isa_ok( $v1, 'SQL::Translator::Object::View', 'View' );
    is( $v1->name, $name, qq[Name is "$name"] );
}

#
# Trigger
#
{
    my $s                   = SQL::Translator::Object::Schema->new(name => 'TrigTest');
    $s->add_table({ name => 'foo' }) or die "Couldn't create table: ", $s->error;
    my $name                = 'foo_trigger';
    my $perform_action_when = 'after';
    my $database_events     = 'insert';
    my $on_table            = 'foo';
    my $action              = 'update modified=timestamp();';
    my $t                   = $s->add_trigger({
        name                => $name,
        perform_action_when => $perform_action_when,
        database_events     => $database_events,
        on_table            => $on_table,
        table               => $s->get_table('foo'),
        action              => $action,
    }) or die $s->error;

    isa_ok( $t, 'SQL::Translator::Object::Trigger', 'Trigger' );
    isa_ok( $t->schema, 'SQL::Translator::Object::Schema', 'Schema' );
    is( $t->schema->name, 'TrigTest', qq[Schema name is "'TrigTest'"] );
    is( $t->name, $name, qq[Name is "$name"] );
    is( $t->perform_action_when, $perform_action_when, 
        qq[Perform action when is "$perform_action_when"] );

    is( join(',', $t->database_events), $database_events, 
        qq[Database event is "$database_events"] );
    isa_ok( $t->table, 'SQL::Translator::Object::Table', qq[table is a Table"] );
    is( $t->action, $action, qq[Action is "$action"] );

    my @triggs = $s->get_triggers;
    is( scalar @triggs, 1, 'Number of triggers is 1' );

    my $t1 = $s->get_trigger( $name );
    isa_ok( $t1, 'SQL::Translator::Object::Trigger', 'Trigger' );
    is( $t1->name, $name, qq[Name is "$name"] );



    my $s2                   = SQL::Translator::Object::Schema->new(name => 'TrigTest2');
    $s2->add_table({ name => 'foo' }) or die "Couldn't create table: ", $s2->error;
    my $t2                   = $s2->add_trigger({
        name                => 'foo_trigger',
        perform_action_when => 'after',
        database_events     => [qw/insert update/],
        on_table            => 'foo',
        action              => 'update modified=timestamp();',
    }) or die $s2->error;

    isa_ok( $t2, 'SQL::Translator::Object::Trigger', 'Trigger' );
    isa_ok( $t2->schema, 'SQL::Translator::Object::Schema', 'Schema' );
    is( $t2->schema->name, 'TrigTest2', qq[Schema name is "'TrigTest2'"] );
    is( $t2->name, 'foo_trigger', qq[Name is "foo_trigger"] );
    is_deeply(
        [$t2->database_events],
        [qw/insert update/],
        "Database events are [qw/insert update/] "
    );

    #isa_ok($t2->database_events,'ARRAY','Database events');
    
    #
    # Trigger equal tests
    #
#    isnt(
#        $t1->equals($t2),
#        1,
#        'Compare two Triggers with database_event and database_events'
#    );

    $t1->database_events($database_events);
    $t2->database_events($database_events);
#    is($t1->equals($t2),1,'Compare two Triggers with database_event');

    $t2->database_events('');
    $t1->database_events([qw/update insert/]);
    $t2->database_events([qw/insert update/]);
#    is($t1->equals($t2),1,'Compare two Triggers with database_events');
    
    #
    # $schema-> drop_trigger
    #
    my $dropped_trig = $s->drop_trigger($t->name);
    isa_ok($dropped_trig, 'SQL::Translator::Object::Trigger', 'Dropped trigger "foo_trigger"' );
    $s->add_trigger($t);
    my $dropped_trig2 = $s->drop_trigger($t);
    isa_ok($dropped_trig2, 'SQL::Translator::Object::Trigger', 'Dropped trigger "foo_trigger" by object' );
    #is($dropped_trig2->name, $t->name, 'Dropped correct trigger "foo_trigger"');
    my $dropped_trig3 = $s->drop_trigger($t->name);
    #like( $s->error, qr/doesn't exist/, qq[Can't drop non-existant trigger "foo_trigger"] );

    $s->add_trigger($t);
}
 
#
# Procedure
#
{
    my $s          = SQL::Translator::Object::Schema->new( name => 'ProcTest' );
    my $name       = 'foo_proc';
    my $sql        = 'select foo from bar';
    my $parameters = 'foo, bar';
    my $owner      = 'Nomar';
    my $comments   = 'Go Sox!';
    my $p          = $s->add_procedure({
        name       => $name,
        sql        => $sql,
        parameters => $parameters,
        owner      => $owner,
        comments   => $comments,
    }); # or die $s->error;
    $p->parameters([ qw/foo bar/ ]);

    isa_ok( $p, 'SQL::Translator::Object::Procedure', 'Procedure' );
    isa_ok( $p->schema, 'SQL::Translator::Object::Schema', 'Schema' );
    is( $p->schema->name, 'ProcTest', qq[Schema name is "'ProcTest'"] );
    is( $p->name, $name, qq[Name is "$name"] );
    is( $p->sql, $sql, qq[SQL is "$sql"] );

    is_deeply( $p->parameters, [ qw/foo bar/ ], qq[Params = 'foo,bar'] );
    is( $p->comments, $comments, qq[Comments = "$comments"] );

    my @procs = $s->get_procedures;
    is( scalar @procs, 1, 'Number of procedures is 1' );

    my $p1 = $s->get_procedure( $name );
    isa_ok( $p1, 'SQL::Translator::Object::Procedure', 'Procedure' );
    is( $p1->name, $name, qq[Name is "$name"] );

    #
    # $schema-> drop_procedure
    #
    my $dropped_proc = $s->drop_procedure($p->name);
    isa_ok($dropped_proc, 'SQL::Translator::Object::Procedure', 'Dropped procedure "foo_proc"' );
    $s->add_procedure($p);
    my $dropped_proc2 = $s->drop_procedure($p);
    isa_ok($dropped_proc2, 'SQL::Translator::Object::Procedure', 'Dropped procedure "foo_proc" by object' );
    #is($dropped_proc2->name, $p->name, 'Dropped correct procedure "foo_proc"');
    my $dropped_proc3 = $s->drop_procedure($p->name);
    #like( $s->error, qr/doesn't exist/, qq[Can't drop non-existant procedure "foo_proc"] );

    $s->add_procedure($p);
}

done_testing;
