use MooseX::Declare;
role SQL::Translator::Object::Compat {
    use MooseX::MultiMethods;

    multi method fields(Str $columns) {
        my @columns = split /\s*,\s*/, $columns;
        for my $column (@columns) {
            die "Column '$column' does not exist!" unless $self->table->exists_column($column);
            $self->add_column($self->table->get_column($column));
        }
        $self->column_ids;
    }

    multi method fields(ArrayRef $columns) {
        for my $column (@$columns) {
            die "Column '$column' does not exist!" unless $self->table->exists_column($column);
            $self->add_column($self->table->get_column($column));
        }
        $self->column_ids;
    }

    multi method fields(Any $) { $self->column_ids }

    method get_fields { $self->get_columns }
    method get_field { $self->get_column }
    method field_names { $self->column_ids }
    method reference_fields { $self->reference_columns }
}
