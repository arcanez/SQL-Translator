use MooseX::Declare;
role SQL::Translator::Parser::DBI {
    use DBI::Const::GetInfoType;
    use DBI::Const::GetInfo::ANSI;
    use DBI::Const::GetInfoReturn;

    use MooseX::Types::Moose qw(HashRef Maybe Str);
    use MooseX::MultiMethods;

    use SQL::Translator::Object::Column;
    use SQL::Translator::Object::ForeignKey;
    use SQL::Translator::Object::Index;
    use SQL::Translator::Object::PrimaryKey;
    use SQL::Translator::Object::Table;
    use SQL::Translator::Object::View;

    use SQL::Translator::Types qw(Schema Table Column);

    has 'quoter' => (
        is => 'rw',
        isa => Str,
        lazy => 1,
        default => sub { shift->dbh->get_info(29) || q{"} }
    );

    has 'namesep' => (
        is => 'rw',
        isa => Str,
        lazy => 1,
        default => sub { shift->dbh->get_info(41) || '.' }
    );

    has 'schema_name' => (
        is => 'rw',
        isa => Maybe[Str],
        lazy => 1,
        default => undef
    );

    has 'catalog_name' => (
        is => 'rw',
        isa => Maybe[Str],
        lazy => 1,
        default => undef
    );

    method _subclass {
        my $dbtype = $self->dbh->get_info($GetInfoType{SQL_DBMS_NAME}) || $self->dbh->{Driver}{Name};

        my $class = __PACKAGE__ . '::'. $dbtype;
        Class::MOP::load_class($class);
        $class->meta->apply($self);
    }

    method _is_auto_increment(HashRef $column_info) { 0 }

    method _column_default_value(HashRef $column_info) { $column_info->{COLUMN_DEF} }

    method _column_data_type(HashRef $column_info) { $column_info->{DATA_TYPE} }

    method _add_column_extra(Column $column, HashRef $column_info) { return }

    method _add_tables(Schema $schema) {
        my $sth = $self->dbh->table_info($self->catalog_name, $self->schema_name, '%', "TABLE,VIEW,'LOCAL TEMPORARY','GLOBAL TEMPORARY'");
        while (my $table_info = $sth->fetchrow_hashref) {
            if ($table_info->{TABLE_TYPE} =~ /^(TABLE|LOCAL TEMPORARY|GLOBAL TEMPORARY)$/) {
                my $temp = $table_info->{TABLE_TYPE} =~ /TEMPORARY$/ ? 1 : 0;
                my $table = SQL::Translator::Object::Table->new({ name => $table_info->{TABLE_NAME}, temporary => $temp, schema => $schema });
                $schema->add_table($table);

                $self->_add_columns($table);
                $self->_add_primary_key($table);
                $self->_add_indexes($table);
            }
            elsif ($table_info->{TABLE_TYPE} eq 'VIEW') {
                my $sql = $self->_get_view_sql($table_info->{TABLE_NAME});
                my $view = SQL::Translator::Object::View->new({ name => $table_info->{TABLE_NAME}, sql => $sql });
                $schema->add_view($view);
                $self->_add_columns($view);
            }
        }
        $self->_add_foreign_keys($schema->get_table($_), $schema) for $schema->table_ids;
    }

    method _add_columns(Table $table) {
        my $sth = $self->dbh->column_info($self->catalog_name, $self->schema_name, $table->name, '%');
        my @columns;
        while (my $column_info = $sth->fetchrow_hashref) {
            my $column = SQL::Translator::Object::Column->new({ name => $column_info->{COLUMN_NAME},
                                                                data_type => $self->_column_data_type($column_info),
                                                                size => $column_info->{COLUMN_SIZE},
                                                                default_value => $self->_column_default_value($column_info),
                                                                is_auto_increment => $self->_is_auto_increment($column_info),
                                                                is_nullable => $column_info->{NULLABLE},
                                                              });
            $self->_add_column_extra($column, $column_info);
            push @columns, { column => $column, pos =>  $column_info->{ORDINAL_POSITION} || $#columns };
        }
        $table->add_column($_->{column}) for sort { $a->{pos} <=> $b->{pos} } @columns;
    }

    method _add_primary_key(Table $table) {
        my $pk_info = $self->dbh->primary_key_info($self->catalog_name, $self->schema_name, $table->name);

        my ($pk_name, @pk_cols);
        while (my $pk_col = $pk_info->fetchrow_hashref) {
            $pk_name = $pk_col->{PK_NAME};
            push @pk_cols, $pk_col->{COLUMN_NAME};
        }
        return unless $pk_name;

        my $pk = SQL::Translator::Object::PrimaryKey->new({ name => $pk_name });
        $pk->add_column($table->get_column($_)) for @pk_cols;
        $table->add_index($pk);
    }

    method _add_foreign_keys(Table $table, Schema $schema) {
        my $fk_info = $self->dbh->foreign_key_info($self->catalog_name, $self->schema_name, $table->name, $self->catalog_name, $self->schema_name, undef);
        return unless $fk_info;

        my $fk_data;
        while (my $fk_col = $fk_info->fetchrow_hashref) {
            my $fk_name = $fk_col->{FK_NAME}; 

            push @{$fk_data->{$fk_name}{columns}}, $fk_col->{FK_COLUMN_NAME};
            $fk_data->{$fk_name}{table} = $fk_col->{FK_TABLE_NAME};
            $fk_data->{$fk_name}{uk} = $schema->get_table($fk_col->{UK_TABLE_NAME})->get_index($fk_col->{UK_NAME});
        }

        foreach my $fk_name (keys %$fk_data) {
            my $fk = SQL::Translator::Object::ForeignKey->new({ name => $fk_name, references => $fk_data->{$fk_name}{uk} });
            $fk->add_column($schema->get_table($fk_data->{$fk_name}{table})->get_column($_)) for @{$fk_data->{$fk_name}{columns}};
            $table->add_constraint($fk);
        }
    }

    method _add_indexes(Table $table) {
        my $index_info = $self->dbh->statistics_info($self->catalog_name, $self->schema_name, $table->name, 1, 0);

        return unless defined $index_info;

        my ($index_name, $index_type, @index_cols);
        while (my $index_col = $index_info->fetchrow_hashref) {
            $index_name = $index_col->{INDEX_NAME};
            $index_type = $index_col->{NON_UNIQUE} ? 'NORMAL' : 'UNIQUE';
            push @index_cols, $index_col->{COLUMN_NAME};
        }
        return if $table->exists_index($index_name);
        my $index = SQL::Translator::Object::Index->new({ name => $index_name, type => $index_type });
        $index->add_column($table->get_column($_)) for @index_cols;
        $table->add_index($index);
    }

    multi method parse(Schema $data) { $data }

    multi method parse(Any $) {
        $self->_add_tables($self->schema);
    }
}
