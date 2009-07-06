package SQL::Translator::Producer::SQLite;
use namespace::autoclean;
use Moose::Role;

sub _create_table {
    my $self = shift;
    my $table = shift;

    my $no_comments    = 0;
    my $add_drop_table = 1;
    my $sqlite_version = 0;

    my $create_table;
    my (@create, @column_defs, @index_defs, @constraint_defs);

    $create_table .= 'DROP TABLE '   . $table->name . ";\n" if $add_drop_table;
    $create_table .= 'CREATE TABLE ' . $table->name . " (\n";

    push @column_defs, $self->_create_column($_) for values %{$table->columns};
    $create_table .= join(",\n", map { '  ' . $_ } @column_defs ) . "\n)";

    print $create_table . "\n";
    return (@create, $create_table, @index_defs, @constraint_defs );
}

sub _create_column {
    my $self = shift;
    my $column = shift;

    my $size = $column->data_type =~ /^(timestamp)/i ? undef : $column->size;

    my $column_def;
    $column_def  = $column->name . ' ' . $column->data_type;
    $column_def .= '(' . $column->size . ')' if $size;
    $column_def .= ' NOT NULL' unless $column->is_nullable;
    $column_def .= ' DEFAULT ' . $column->default_value if $column->default_value;
    $column_def;
}

1;
