use MooseX::Declare;
class SQL::Translator::Object::Constraint {
    use MooseX::Types::Moose qw(ArrayRef Bool HashRef Maybe Str Undef);
    use MooseX::AttributeHelpers;
    use SQL::Translator::Types qw(Column Table);
    extends 'SQL::Translator::Object';

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
        default => 0
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

    has 'options' => (
        is => 'rw',
        isa => ArrayRef,
        auto_deref => 1
    );

    has 'extra' => (
        is => 'rw',
        isa => HashRef,
        auto_deref => 1,
    );

    around add_column(Column $column) { $self->$orig($column->name, $column) }

    method get_fields { return $self->get_columns }
    method fields { return $self->column_ids }
    method field_names { return $self->column_ids }

    method match_type { }
}
