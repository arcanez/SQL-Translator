use MooseX::Declare;
role SQL::Translator::Producer::SQL::PostgreSQL {
    use SQL::Translator::Constants qw(:sqlt_types);
    use SQL::Translator::Types qw(Column Index Table);
    
    my %data_type_mapping = (
        SQL_LONGVARCHAR() => 'text',
        SQL_TIMESTAMP()   => 'timestamp',
        SQL_TYPE_TIMESTAMP() => 'timestamp without time zone',
        SQL_TYPE_TIMESTAMP_WITH_TIMEZONE() => 'timestamp',
        SQL_INTEGER()     => 'integer',
        SQL_CHAR()        => 'character',
        SQL_VARCHAR()     => 'varchar',
        SQL_BIGINT()      => 'bigint',
        SQL_FLOAT()       => 'numeric',
    );
    
    method _create_table(Table $table) {
        my $pg_version = 0;
    
        my $create_table;
        my (@create, @column_defs, @index_defs, @constraint_defs);
    
        $create_table .= 'DROP TABLE '   . $table->name . ";\n" if $self->drop_table;
        $create_table .= 'CREATE TABLE ' . $table->name . " (\n";
    
        push @column_defs, $self->_create_column($_) for values %{$table->columns};
        $create_table .= join(",\n", map { '  ' . $_ } @column_defs ) . "\n)";
    
        foreach my $index (values %{$table->indexes}) {
            if ($index->type eq 'NORMAL') {
                push @index_defs, $self->_create_index($index, $table);
            } else {
                push @constraint_defs, $self->_create_index($index);
            }
        }
    
        print $create_table . ";\n";
        return (@create, $create_table, @index_defs, @constraint_defs);
    }
    
    method _create_column(Column $column) {
        my $size = $column->size;
        my $default_value = $column->default_value;
        $default_value =~ s/^CURRENT_TIMESTAMP/now()/i if $default_value;
    
        my $column_def;
        $column_def  = $column->name . ' ';
        $column_def .= defined $data_type_mapping{$column->data_type}
                       ? $data_type_mapping{$column->data_type}
                       : $column->data_type;
        $column_def .= '(' . $column->size . ')' if $size;
        $column_def .= ' NOT NULL' unless $column->is_nullable;
        $column_def .= ' PRIMARY KEY' if $column->is_auto_increment;
        $column_def .= ' DEFAULT ' . $default_value if $column->default_value && !$column->is_auto_increment;
        $column_def;
    }
    
    method _create_index(Index $index, Table $table?) {
        my $index_def;
        if ($index->type eq 'PRIMARY_KEY') {
            $index_def = 'CONSTRAINT ' . $index->name .  ' PRIMARY KEY ' .  '(' . (join ', ', map { $_->name } values %{$index->columns}) . ')';
        }
        elsif ($index->type eq 'UNIQUE') {
            $index_def = 'CONSTRAINT ' . $index->name .  ' UNIQUE ' .  '(' . (join ', ', map { $_->name } values %{$index->columns}) . ')';
        }
        elsif ($index->type eq 'NORMAL') {
            $index_def = 'CREATE INDEX ' . $index->name . ' ON ' . $table->name . '('.  (join ', ', map { $_->name } values %{$index->columns}) . ')';
        }
    
        $index_def;
    }
}
