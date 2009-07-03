package SQL::Translator::Producer;
use namespace::autoclean;
use Moose;
use MooseX::Types::Moose qw(Str);
use SQL::Translator::Types qw(Schema);

use Data::Dumper;

has 'schema' => (
  isa => Schema,
  is => 'rw',
  required => 1
);

sub produce {
    my $self = shift;
    my $schema = $self->schema;

    my $tables = $schema->tables;
    foreach my $tname (keys %$tables) {
        $self->_create_table($tables->{$tname});
    }
}

sub _create_table {
    my $self = shift;
    my $table = shift;

    my $no_comments    = 0;
    my $add_drop_table = 1;
    my $sqlite_version = 0;

    my $create_table;

    $create_table .= 'DROP TABLE ' . $table->name . ";\n" if $add_drop_table;
    $create_table .= "CREATE TABLE " . $table->name . " (\n";

    my $columns = $table->columns;
    foreach my $cname (keys %$columns) {
        my $column = $columns->{$cname};
        $create_table .= '    ' . $column->name . ' ' . $column->data_type;
        $create_table .= '(' . $column->size . ')' if $column->size;
        $create_table .= ' NOT NULL' unless $column->is_nullable;
        $create_table .= ",\n";
    }
    $create_table =~ s/,$//;
    $create_table .= ");";
    print $create_table . "\n";
}

__PACKAGE__->meta->make_immutable;

1;
