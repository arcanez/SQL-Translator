use MooseX::Declare;
class SQL::Translator::Object::Table {
    use MooseX::Types::Moose qw(ArrayRef Bool HashRef Maybe Str);
    use MooseX::AttributeHelpers;
    use SQL::Translator::Types qw(Column Constraint Index Schema Sequence);
    use SQL::Translator::Object::Schema;
    extends 'SQL::Translator::Object';
    
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
    
    has 'indexes' => (
        metaclass => 'Collection::Hash',
        is => 'rw',
        isa => HashRef[Index],
        provides => {
            exists => 'exists_index',
            keys   => 'index_ids',
            values => 'get_indices',
            get    => 'get_index',
            set    => 'add_index',
        },
        default => sub { my %hash = (); tie %hash, 'Tie::IxHash'; return \%hash },
    );
    
    has 'constraints' => (
        metaclass => 'Collection::Hash',
        is => 'rw',
        isa => HashRef[Constraint],
        provides => {
            exists => 'exists_constraint',
            keys   => 'constraint_ids',
            values => 'get_constraints',
            get    => 'get_constraint',
            set    => 'add_constraint',
        },
        default => sub { my %hash = (); tie %hash, 'Tie::IxHash'; return \%hash },
    );
    
    has 'sequences' => (
        metaclass => 'Collection::Hash',
        is => 'rw',
        isa => HashRef[Sequence],
        provides => {
            exists => 'exists_sequence',
            keys   => 'sequence_ids',
            values => 'get_sequences',
            get    => 'get_sequence',
            set    => 'add_sequence',
        },
        default => sub { my %hash = (); tie %hash, 'Tie::IxHash'; return \%hash },
    );

    has 'comments' => (
        is => 'rw',
        isa => Maybe[Str],
    );
    
    has 'temporary' => (
        is => 'rw',
        isa => Bool,
        default => 0
    );

    has 'options' => (
        is => 'rw',
        isa => ArrayRef,
        auto_deref => 1
    );

    around add_column(Column $column) { $self->$orig($column->name, $column) }
    around add_index(Index $index) { $self->$orig($index->name, $index) }
    around add_constraint(Constraint $constraint) { $self->$orig($constraint->name, $constraint) }
    around add_sequence(Sequence $sequence) { $self->$orig($sequence->name, $sequence) }

    method get_fields { return $self->get_columns }
    method fields { return $self->column_ids }
    method primary_key(Str $column) {
        $self->get_column($column)->is_primary_key(1);
    }

    method order { }
}
