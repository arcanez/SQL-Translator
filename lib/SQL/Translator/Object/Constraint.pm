use MooseX::Declare;
class SQL::Translator::Object::Constraint extends SQL::Translator::Object {
    use MooseX::Types::Moose qw(ArrayRef Bool HashRef Maybe Str Undef);
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
        isa => Maybe[Str],
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

    has 'deferrable' => (
        is => 'rw',
        isa => Bool,
        default => 1
    );

    has 'expression' => (
        is => 'rw',
        isa => Str,
    );

    has 'reference_table' => (
        isa => Maybe[Str],
        is => 'rw',
    );

    has 'reference_columns' => (
        isa => ArrayRef | Undef,
        is => 'rw',
        auto_deref => 1
    );

    has 'match_type' => (
        isa => Str,
        is => 'rw'
    );

    around add_column(Column $column) { $self->$orig($column->name, $column) }

    method get_fields { $self->get_columns }
    method fields { $self->column_ids }
    method field_names { $self->column_ids }

    method reference_fields { $self->reference_columns }
}
