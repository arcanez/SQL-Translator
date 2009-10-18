use MooseX::Declare;
class SQL::Translator::Object::Index extends SQL::Translator::Object {
    use MooseX::Types::Moose qw(HashRef Str);
    use MooseX::MultiMethods;
    use SQL::Translator::Types qw(Column Table);

    has 'table' => (
        is => 'rw',
        isa => Table,
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
            clear_columns => 'clear',
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

    method is_valid { $self->table && scalar $self->get_columns ? 1 : undef }
}
