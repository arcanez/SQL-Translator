use MooseX::Declare;
class SQL::Translator::Object::Index extends SQL::Translator::Object {
    use MooseX::Types::Moose qw(HashRef Str);
    use MooseX::MultiMethods;
    use SQL::Translator::Types qw(Column Table);

    has 'table' => (
        is => 'rw',
        isa => Table,
        required => 1,
        weak_ref => 1,
    );
    
    has 'name' => (
        is => 'rw',
        isa => Str,
        required => 1
    );

    has 'columns' => (
        traits => ['Hash'],
        is => 'rw',
        isa => HashRef[Column],
        handles => {
            exists_column => 'exists',
            column_ids    => 'keys',
            get_columns   => 'values',
            get_column    => 'get',
            add_column    => 'set',

            ## compat
            get_fields    => 'values',
        },
        default => sub { my %hash = (); tie %hash, 'Tie::IxHash'; return \%hash },
    );

    has 'type' => (
        is => 'rw',
        isa => Str,
        required => 1,
        default => 'NORMAL',
    );

    around add_column(Column $column) { $self->$orig($column->name, $column) }

    multi method fields(Str $columns) {
        for (split /,/, $columns) { die "Column $_ does not exist!" unless $self->table->exists_column($_) }
        $self->add_column($self->table->get_column($_)) for split /,/, $columns;
        $self->column_ids;
    }

    multi method fields(@columns) {
        for (@columns) { die "Column $_ does not exist!" unless $self->table->exists_column($_) }
        $self->add_column($self->table->get_column($_)) for @columns;
        $self->column_ids;
    }

    multi method fields(Any $) { $self->column_ids }

    method is_valid { $self->table && scalar $self->get_columns ? 1 : undef }
}
