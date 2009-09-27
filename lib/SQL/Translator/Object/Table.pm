use MooseX::Declare;
class SQL::Translator::Object::Table extends SQL::Translator::Object is dirty {
    use MooseX::Types::Moose qw(Any Bool HashRef Str);
    use MooseX::MultiMethods;
    use SQL::Translator::Types qw(Column Constraint Index Schema Sequence);
    clean;

    use overload
        '""'     => sub { shift->name },
        'bool'   => sub { $_[0]->name || $_[0] },
        fallback => 1,
    ;

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
            remove_column => 'delete',

            ## compat
            get_fields    => 'values',
            get_field     => 'get',
            fields        => 'keys',
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

    method add_field(Column $column does coerce) { $self->add_column($column) }

    around add_column(Column $column does coerce) {
        die "Can't use column name " . $column->name if $self->exists_column($column->name) || $column->name eq '';
        return $self->$orig($column->name, $column);
    }
    around add_constraint(Constraint $constraint) {
        my $name = $constraint->name;
        if ($name eq '') {
            my $idx = 0;
            while ($self->exists_constraint('ANON' . $idx)) { $idx++ }
            $name = 'ANON' . $idx;
        }
        $self->$orig($name, $constraint)
    }
    around add_index(Index $index) {
        my $name = $index->name;
        if ($name eq '') {
            my $idx = 0;
            while ($self->exists_index('ANON' . $idx)) { $idx++ }
            $name = 'ANON' . $idx;
        }
        $self->$orig($name, $index)
    }
    around add_sequence(Sequence $sequence) { $self->$orig($sequence->name, $sequence) }

    multi method primary_key(Any $) { grep /^PRIMARY KEY$/, $_->type for $self->get_constraints }
    multi method primary_key(Str $column) { $self->get_column($column)->is_primary_key(1) }

    method is_valid { return $self->get_columns ? 1 : undef }
    method order { }

    before name($name?) { die "Can't use table name $name, table already exists" if $name && $self->schema->exists_table($name) && $name ne $self->name }

    multi method drop_column(Column $column, Int :$cascade = 0) {
        die "Can't drop non-existant table " . $column->name unless $self->exists_column($column->name);
        $self->remove_column($column->name);

    }

    multi method drop_column(Str $column, Int :$cascade = 0) {
        die "Can't drop non-existant table " . $column unless $self->exists_column($column);
        $self->remove_column($column);
    }
}
