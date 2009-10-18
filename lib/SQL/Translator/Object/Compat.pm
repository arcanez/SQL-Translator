use MooseX::Declare;
role SQL::Translator::Object::Compat {
    use MooseX::Types qw(Any ArrayRef Int Str);
    use SQL::Translator::Types qw(Column Constraint Index Table View);

    use MooseX::MultiMethods;

    multi method fields(Str $columns) {
        $self->clear_columns;
        my @columns = split /\s*,\s*/, $columns;
        for my $column (@columns) {
            die "Column '$column' does not exist!" unless $self->table->exists_column($column);
            $self->add_column($self->table->get_column($column));
        }
        $self->column_ids;
    }

    multi method fields(ArrayRef $columns) {
        $self->clear_columns;
        for my $column (@$columns) {
            die "Column '$column' does not exist!" unless $self->table->exists_column($column);
            $self->add_column($self->table->get_column($column));
        }
        $self->column_ids;
    }

    multi method fields { $self->column_ids }

    method add_field(Column $column does coerce) { $self->add_column($column) }

    method drop_table(Table|Str $table, Int :$cascade = 0) { $self->remove_table($table, cascade => $cascade) }
    method drop_column(Column|Str $column, Int :$cascade = 0) { $self->remove_column($column, cascade => $cascade) }
    method drop_index(Index|Str $index) { $self->remove_index($index) }
    method drop_constraint(Constraint|Str $constraint) { $self->remove_constraint($constraint) }
    method drop_view(View|Str $view) { $self->remove_view($view) }

    method get_fields { $self->get_columns }
    method get_field { $self->get_column }
    method field_names { $self->column_ids }
    method reference_fields { $self->reference_columns }
}
