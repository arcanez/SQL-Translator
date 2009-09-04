use MooseX::Declare;
class SQL::Translator::Object::Table extends SQL::Translator::Object {
    use MooseX::Types::Moose qw(Any Bool HashRef Str);
    use MooseX::MultiMethods;
    use SQL::Translator::Types qw(Column Constraint Index Schema Sequence);
    
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
    
    has 'indexes' => (
        traits => ['Hash'],
        is => 'rw',
        isa => HashRef[Index],
        handles => {
            exists_index => 'exists',
            index_ids    => 'keys',
            get_indices  => 'values',
            get_index    => 'get',
            add_index    => 'set',
        },
        default => sub { my %hash = (); tie %hash, 'Tie::IxHash'; return \%hash },
    );
    
    has 'constraints' => (
        traits => ['Hash'],
        is => 'rw',
        isa => HashRef[Constraint],
        handles => {
            exists_constraint => 'exists',
            constraint_ids    => 'keys',
            get_constraints   => 'values',
            get_constraint    => 'get',
            add_constraint    => 'set',
        },
        default => sub { my %hash = (); tie %hash, 'Tie::IxHash'; return \%hash },
    );
    
    has 'sequences' => (
        traits => ['Hash'],
        is => 'rw',
        isa => HashRef[Sequence],
        handles => {
            exists_sequence => 'exists',
            sequence_ids    => 'keys',
            get_sequences   => 'values',
            get_sequence    => 'get',
            add_sequence    => 'set',
        },
        default => sub { my %hash = (); tie %hash, 'Tie::IxHash'; return \%hash },
    );

    has 'schema' => (
        is => 'rw',
        isa => Schema,
        weak_ref => 1,
        required => 1,
    );

    has 'temporary' => (
        is => 'rw',
        isa => Bool,
        default => 0
    );

    around add_column(Column $column) { $self->$orig($column->name, $column) }
    around add_index(Index $index) { $self->$orig($index->name, $index) }
    around add_constraint(Constraint $constraint) { $self->$orig($constraint->name, $constraint) }
    around add_sequence(Sequence $sequence) { $self->$orig($sequence->name, $sequence) }

    method get_fields { $self->get_columns }
    method fields { $self->column_ids }

    multi method primary_key(Any $) { grep /^PRIMARY KEY$/, $_->type for $self->get_constraints }
    multi method primary_key(Str $column) { $self->get_column($column)->is_primary_key(1) }

    method order { }
}
