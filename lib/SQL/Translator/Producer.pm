use MooseX::Declare;
class SQL::Translator::Producer {
    use SQL::Translator::Constants qw(:sqlt_types);
    use MooseX::Types::Moose qw(Bool HashRef Str);
    use SQL::Translator::Types qw(Column Table Translator);
    
    has 'data_type_mapping' => (
        isa => HashRef,
        is => 'ro',
        lazy_build => 1
    );

    has 'translator' => (
        isa => Translator,
        is => 'ro',
        weak_ref => 1,
        required => 1,
        handles => [ qw(schema) ],
    );

    method _build_data_type_mapping {
        return { 
            SQL_LONGVARCHAR() => 'text',
            SQL_TIMESTAMP()   => 'timestamp',
            SQL_TYPE_TIMESTAMP() => 'timestamp without time zone',
            SQL_TYPE_TIMESTAMP_WITH_TIMEZONE() => 'timestamp',
            SQL_INTEGER()     => 'integer',
            SQL_CHAR()        => 'char',
            SQL_VARCHAR()     => 'varchar',
            SQL_BIGINT()      => 'bigint',
            SQL_FLOAT()       => 'numeric',
        };
    }

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
