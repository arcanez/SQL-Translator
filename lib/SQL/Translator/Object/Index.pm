use MooseX::Declare;
class SQL::Translator::Object::Index extends SQL::Translator::Object {
    use MooseX::Types::Moose qw(ArrayRef HashRef Str);
    use MooseX::AttributeHelpers;
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
        metaclass => 'Collection::Hash',
        is => 'rw',
        isa => HashRef[Column],
        provides => {
            exists => 'exists_column',
            keys   => 'column_ids',
            values => 'get_columns',
            get    => 'get_column',
            set    => 'add_column',
        },
        default => sub { my %hash = (); tie %hash, 'Tie::IxHash'; return \%hash },
    );

    has 'type' => (
        is => 'rw',
        isa => Str,
        required => 1
    );

    around add_column(Column $column) { $self->$orig($column->name, $column) }

    method get_fields { $self->get_columns }
    method fields { $self->column_ids }
}
