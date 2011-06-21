use MooseX::Declare;
class SQL::Translator::Object::Table extends SQL::Translator::Object is dirty {
    use MooseX::Types::Moose qw(Any Bool HashRef Int Str);
    use MooseX::MultiMethods;
    use SQL::Translator::Types qw(Column Constraint Index Schema Sequence ColumnHash ConstraintHash IndexHash SequenceHash IxHash);
    use SQL::Translator::Object::Column;
    use SQL::Translator::Object::Constraint;
    use Tie::IxHash;
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
        is => 'rw',
        isa => IxHash, #ColumnHash,
        handles => {
            exists_column => 'EXISTS',
            column_ids    => 'Keys',
            get_columns   => 'Values',
            get_column    => 'FETCH',
            add_column    => 'STORE',
            remove_column => 'DELETE',
            has_columns   => 'Length',
            clear_columns => 'CLEAR',
        },
        coerce => 1,
        default => sub { Tie::IxHash->new() }
    );
    
    has 'indexes' => (
        is => 'rw',
        isa => IxHash, #IndexHash,
        handles => {
            exists_index => 'EXISTS',
            index_ids    => 'Keys',
            get_indices  => 'Values',
            get_index    => 'FETCH',
            add_index    => 'STORE',
            remove_index => 'DELETE',
        },
        coerce => 1,
        default => sub { Tie::IxHash->new() }
    );
    
    has 'constraints' => (
        is => 'rw',
        isa => IxHash, #ConstraintHash,
        handles => {
            exists_constraint => 'EXISTS',
            constraint_ids    => 'Keys',
            get_constraints   => 'Values',
            get_constraint    => 'FETCH',
            add_constraint    => 'STORE',
            remove_constraint => 'DELETE',
        },
        coerce => 1,
        default => sub { Tie::IxHash->new() }
    );
    
    has 'sequences' => (
        is => 'rw',
        isa => IxHash, #SequenceHash,
        handles => {
            exists_sequence => 'EXISTS',
            sequence_ids    => 'Keys',
            get_sequences   => 'Values',
            get_sequence    => 'FETCH',
            add_sequence    => 'STORE',
            remove_sequence => 'DELETE',
        },
        coerce => 1,
        default => sub { Tie::IxHash->new() },
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

    has '_order' => (
        is => 'rw',
        isa => Int,
    );

    around get_column(Column $column does coerce) {
        $self->$orig($column->name);
    }

    around add_column(Column $column does coerce) {
        die "Can't use column name " . $column->name if $self->exists_column($column->name) || $column->name eq '';
        $column->table($self);
        $self->$orig($column->name, $column);
        return $self->get_column($column->name);
    }

    around add_constraint(Constraint $constraint does coerce) {
        if ($constraint->type eq 'FOREIGN KEY') {
            my @columns = $constraint->get_columns;
            die "There are no columns associated with this foreign key constraint." unless scalar @columns;
            for my $column (@columns) {
                die "Can't use column " . $column->name . ". It doesn't exist!" unless $self->exists_column($column);
            }
            die "Reference table " . $constraint->reference_table . " does not exist!" unless $self->schema->exists_table($constraint->reference_table);
        }
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
        $self->$orig($name, $constraint);
        return $self->get_constraint($name);
    }

    around add_index(Index $index does coerce) {
        my $name = $index->name;
        if ($name eq '') {
            my $idx = 0;
            while ($self->exists_index('ANON' . $idx)) { $idx++ }
            $name = 'ANON' . $idx;
        }
        $index->table($self);
        $self->$orig($name, $index);
        return $self->get_index($name);
    }

    around add_sequence(Sequence $sequence does coerce) {
        $self->$orig($sequence->name, $sequence);
        return $self->get_sequence($sequence->name);
    }

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

    multi method order(Int $order) { $self->_order($order); }
    multi method order {
        my $order = $self->_order;
        unless (defined $order && $order) {
            my $tables = Tie::IxHash->new( map { $_->name => $_ } $self->schema->get_tables );
            $order = $tables->Indices($self->name) || 0; $order++;
            $self->_order($order);
        }
        return $order;
    }

    method is_valid { return $self->has_columns ? 1 : undef }

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

        $args->{columns}{$_} = SQL::Translator::Object::Column->new( name => $_ ) for @$fields;

        return $args;
    }
}
