use MooseX::Declare;
class SQL::Translator::Object::Table {
    use MooseX::Types::Moose qw(Bool HashRef Maybe Str);
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
        },
        curries => {
            set => {
                add_column => sub {
                    my ($self, $body, $column) = @_;
                    $self->$body($column->name, $column);
                }
            }
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
        },
        curries => {
            set => {
                add_index => sub {
                    my ($self, $body, $index) = @_;
                    $self->$body($index->name, $index);
                }
            }
        },
        default => sub { {} },
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
        },
        curries => {
            set => {
                add_constraint => sub {
                    my ($self, $body, $constraint) = @_;
                    $self->$body($constraint->name, $constraint);
                }
            }
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
        },
        curries => {
            set => {
                add_sequence => sub {
                    my ($self, $body, $sequence) = @_;
                    $self->$body($sequence->name, $sequence);
                }
            }
        },
        default => sub { {} },
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

    method get_fields { return $self->get_columns }
}
