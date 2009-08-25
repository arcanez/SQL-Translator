use MooseX::Declare;
class SQL::Translator::Object::Trigger extends SQL::Translator::Object {
    use MooseX::Types::Moose qw(Any ArrayRef HashRef Str);
    use MooseX::AttributeHelpers;
    use SQL::Translator::Types qw(Column);
    
    has 'name' => (
        is => 'ro',
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

    has 'on_table' => (
        is => 'rw', 
        isa => Str,
        required => 1
    );

    has 'action' => (
        is => 'rw',
        isa => Any
    );

    has 'perform_action_when' => (
        is => 'rw',
        isa => Str,
        required => 1
    );

    has 'database_events' => (
        is => 'rw',
        isa => ArrayRef,
        required => 1
    );

    around add_column(Column $column) { $self->$orig($column->name, $column) }

    method get_fields { $self->get_columns }
    method fields { $self->column_ids }
}
