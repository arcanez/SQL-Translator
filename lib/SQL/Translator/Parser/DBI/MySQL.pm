use MooseX::Declare;
role SQL::Translator::Parser::DBI::MySQL {
    use MooseX::Types::Moose qw(HashRef Maybe Str);
    use SQL::Translator::Types qw(View Table Schema);

    has 'schema_name' => (
      is      => 'rw',
      isa     => Maybe [Str],
      lazy    => 1,
      default => sub {
        my ($name) = shift->dbh->selectrow_array("select database()");
        return $name;
      },
    );

    method _get_view_sql(View $view) {
        #my ($sql) = $self->dbh->selectrow_array('');
        #return $sql;
        return '';
    }

    method _is_auto_increment(HashRef $column_info) {
        return $column_info->{mysql_is_auto_increment};
    }

    method _column_default_value(HashRef $column_info) {
        my $default_value = $column_info->{COLUMN_DEF};
        $default_value =~ s/::.*$// if defined $default_value;

        return $default_value;
    }

    method _add_foreign_keys(Table $table, Schema $schema) {
        my $fk_info = $self->dbh->foreign_key_info($self->catalog_name, $self->schema_name, $table->name, $self->catalog_name, $self->schema_name, undef);
        return unless $fk_info;
        my $fk_data;
        while (my $fk_col = $fk_info->fetchrow_hashref) {
            my $fk_name = $fk_col->{FK_NAME};
            push @{$fk_data->{$fk_name}{columns}}, $fk_col->{FKCOLUMN_NAME};
            push @{$fk_data->{$fk_name}{reference_columns}}, $fk_col->{PKCOLUMN_NAME};
            $fk_data->{$fk_name}{table} = $fk_col->{FKTABLE_NAME};
            $fk_data->{$fk_name}{reference_table} = $fk_col->{PKTABLE_NAME};
            my $pk_name = $fk_col->{PK_NAME};
            $pk_name = 'PRIMARY' unless defined $pk_name;
            $fk_data->{$fk_name}{uk} = $schema->get_table($fk_col->{PKTABLE_NAME})->get_index($pk_name);
        }

        foreach my $fk_name (keys %$fk_data) {
          my $fk = SQL::Translator::Object::ForeignKey->new(
            {name => $fk_name, references => $fk_data->{$fk_name}{uk}, reference_table => $fk_data->{$fk_name}{reference_table}, reference_columns => $fk_data->{$fk_name}{reference_columns}});
          $fk->add_column($schema->get_table($fk_data->{$fk_name}{table})->get_column($_))
            for @{$fk_data->{$fk_name}{columns}};
          $schema->get_table($fk_data->{$fk_name}{table})->add_constraint($fk);
        }
    }

    method _add_indexes(Table $table) {
        my $index_info = $self->dbh->prepare(qq{SHOW INDEX FROM } . $table->name);

        $index_info->execute;

        my %indexes;
        while (my $index_col = $index_info->fetchrow_hashref('NAME_uc')) {
          my $index_name = $index_col->{KEY_NAME};

          next if $index_name eq 'PRIMARY';
          $indexes{$index_name}{index_type} = $index_col->{NON_UNIQUE} ? 'NORMAL' : 'UNIQUE';
          my $column = $table->get_column($index_col->{COLUMN_NAME});
          push @{$indexes{$index_name}{index_cols}},
            {column => $column, pos => $index_col->{SEQ_IN_INDEX}};
        }
        foreach my $index_name (keys %indexes) {
          next if $table->exists_index($index_name);
          my $index = SQL::Translator::Object::Index->new(
            {name => $index_name, type => $indexes{$index_name}{index_type}});
          $index->add_column($_->{column})
            for sort { $a->{pos} <=> $b->{pos} } @{$indexes{$index_name}{index_cols}};
          $table->add_index($index);
        }
    }
}
