use MooseX::Declare;
role SQL::Translator::Producer::SQL::SQLite {
    use SQL::Translator::Constants qw(:sqlt_types);
    use SQL::Translator::Types qw(Column Table);
    
    my %data_type_mapping = (
        SQL_LONGVARCHAR() => 'text',
        SQL_TIMESTAMP()   => 'timestamp',
        SQL_INTEGER()     => 'integer',
        SQL_CHAR()        => 'character',
        SQL_VARCHAR()     => 'varchar',
        SQL_BIGINT()      => 'integer',
    );
    
    method _create_table(Table $table) {
        my $sqlite_version = 0;
    
        my $create_table;
        my (@create, @column_defs, @index_defs, @constraint_defs);
    
        $create_table .= 'DROP TABLE '   . $table->name . ";\n" if $self->drop_table;
        $create_table .= 'CREATE TABLE ' . $table->name . " (\n";
    
        push @column_defs, $self->_create_column($_) for values %{$table->columns};
        $create_table .= join(",\n", map { '  ' . $_ } @column_defs ) . "\n)";
    
        print $create_table . ";\n";
        return (@create, $create_table, @index_defs, @constraint_defs );
    }
    
    method _create_column(Column $column) {
        my $size = $column->data_type == SQL_TIMESTAMP() ? undef : $column->size;
        my $default_value = $column->default_value;
        $default_value =~ s/^now[()]*/CURRENT_TIMESTAMP/i if $default_value;
    
        my $column_def;
        $column_def  = $column->name . ' ';
        $column_def .= defined $data_type_mapping{$column->data_type}
                       ? $data_type_mapping{$column->data_type}
                       : $column->data_type;
        #$column_def .= '(' . $column->size . ')' if $size;
        $column_def .= ' NOT NULL' unless $column->is_nullable;
        $column_def .= ' PRIMARY KEY' if $column->is_auto_increment;
        $column_def .= ' DEFAULT ' . $default_value if $column->default_value && !$column->is_auto_increment;
        $column_def;
    }
}
