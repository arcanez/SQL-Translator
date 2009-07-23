use MooseX::Declare;
class SQL::Translator::Producer {
    use MooseX::Types::Moose qw(Bool Str);
    use SQL::Translator::Types qw(Column Schema Table);
    
    has 'schema' => (
        isa => Schema,
        is => 'rw',
        required => 1
    );
    
    has 'no_comments' => (
        isa => Bool,
        is => 'rw',
        lazy => 1, 
        default => 0
    );
    
    has 'drop_table' => (
        isa => Bool,
        is => 'rw',
        lazy => 1,
        default => 1
    );
    
    method produce {
        my $schema = $self->schema;
    
        $self->_create_table($_) for values %{$schema->tables};
    }
    
    method _create_table(Table $table) {
        my $no_comments    = 0;
        my $add_drop_table = 1;
        my $sqlite_version = 0;
    
        my $create_table;
        my (@column_defs, @index_defs, @constraint_defs);
    
        $create_table .= 'DROP TABLE '   . $table->name . ";\n" if $add_drop_table;
        $create_table .= 'CREATE TABLE ' . $table->name . " (\n";
    
        push @column_defs, $self->_create_column($_) for values %{$table->columns};
        $create_table .= join(",\n", map { '  ' . $_ } @column_defs ) . "\n)";
        print $create_table . "\n";
    }
    
    method _create_column(Column $column) {
        my $column_def;
        $column_def  = $column->name . ' ' . $column->data_type;
        $column_def .= '(' . $column->size . ')' if $column->size;
        $column_def .= ' NOT NULL' unless $column->is_nullable;
        $column_def;
    }
}
