use MooseX::Declare;
class SQL::Translator::Object::View extends SQL::Translator::Object {
    use MooseX::Types::Moose qw(HashRef Str);
    use SQL::Translator::Types qw(Column);
    
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
        },
        default => sub { my %hash = (); tie %hash, 'Tie::IxHash'; return \%hash },
    );
    
    has 'sql' => (
        is => 'rw',
        isa => Str,
        required => 1
    );

    around add_column(Column $column) { $self->$orig($column->name, $column) }

    method get_fields { $self->get_columns }
    method fields { $self->column_ids }
}
