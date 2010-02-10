use MooseX::Declare;
class SQL::Translator::Object::Table extends SQL::Translator::Object is dirty {
    use MooseX::Types::Moose qw(Any Bool HashRef Str);
    use MooseX::MultiMethods;
    use SQL::Translator::Types qw(Column Constraint Index Schema Sequence);
    use SQL::Translator::Object::Column;
    use SQL::Translator::Object::Constraint;
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
            clear_columns => 'clear',
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
            remove_index => 'delete',
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
            remove_constraint => 'delete',
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
            remove_sequence => 'delete',
        },
        default => sub { my %hash = (); tie %hash, 'Tie::IxHash'; return \%hash },
    );

    has 'schema' => (
        is => 'rw',
        isa => Schema,
        weak_ref => 1,
    );

    has 'temporary' => (
        is => 'rw',
        isa => Bool,
        default => 0
    );

    around add_column(Column $column does coerce) {
        die "Can't use column name " . $column->name if $self->exists_column($column->name) || $column->name eq '';
        $column->table($self);
        return $self->$orig($column->name, $column);
    }

    around add_constraint(Constraint $constraint does coerce) {
        my $name = $constraint->name;
        if ($name eq '') {
            my $idx = 0;
            while ($self->exists_constraint('ANON' . $idx)) { $idx++ }
            $name = 'ANON' . $idx;
        }
        $constraint->table($self);
        if ($constraint->has_type && $constraint->type eq 'PRIMARY KEY') {
            $self->get_column($_)->is_primary_key(1) for $constraint->column_ids;
        }
        $self->$orig($name, $constraint)
    }

    around add_index(Index $index does coerce) {
        my $name = $index->name;
        if ($name eq '') {
            my $idx = 0;
            while ($self->exists_index('ANON' . $idx)) { $idx++ }
            $name = 'ANON' . $idx;
        }
        $index->table($self);
        $self->$orig($name, $index)
    }

    around add_sequence(Sequence $sequence does coerce) { $self->$orig($sequence->name, $sequence) }

    multi method primary_key {
        my $constraints = $self->constraints;
        for my $key (keys %$constraints) {
            return $constraints->{$key} if $constraints->{$key}{type} eq 'PRIMARY KEY';
        }
        return undef;
    }

    multi method primary_key(Str $column) {
        die "Column $column does not exist!" unless $self->exists_column($column);
        $self->get_column($column)->is_primary_key(1);

        my $primary_key = $self->primary_key;
        unless (defined $primary_key) {
            $primary_key = SQL::Translator::Object::Constraint->new({ type => 'PRIMARY KEY' });
            $self->add_constraint($primary_key);
        }
        $primary_key->add_field({ name => $column }) unless $primary_key->exists_column($column); ## FIX ME, change back to add_column once around add_column(coerce .. ) works
        return $primary_key;
    }

    method is_valid { return $self->get_columns ? 1 : undef }
    method order { }

    before name($name?) { die "Can't use table name $name, table already exists" if $name && $self->schema->exists_table($name) && $name ne $self->name }

    around remove_column(Column|Str $column, Int :$cascade = 0) {
        my $name = is_Column($column) ? $column->name : $column;
        die "Can't drop non-existant column " . $name unless $self->exists_column($name);
        $self->$orig($name);
    }

    around remove_index(Index|Str $index) {
        my $name = is_Index($index) ? $index->name : $index;
        die "Can't drop non-existant index " . $name unless $self->exists_index($name);
        $self->$orig($name);
    }

    around remove_constraint(Constraint|Str $constraint) {
        my $name = is_Constraint($constraint) ? $constraint->name : $constraint;
        die "Can't drop non-existant constraint " . $name unless $self->exists_constraint($name);
        $self->$orig($name);
    }

    around BUILDARGS(ClassName $self: @args) {
        my $args = $self->$orig(@args);

        my $fields = delete $args->{fields};

        tie %{$args->{columns}}, 'Tie::IxHash';
        $args->{columns}{$_} = SQL::Translator::Object::Column->new( name => $_ ) for @$fields;

        return $args;
    }
}
