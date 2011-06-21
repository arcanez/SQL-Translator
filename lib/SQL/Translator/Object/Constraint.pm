use MooseX::Declare;
class SQL::Translator::Object::Constraint extends SQL::Translator::Object {
    use MooseX::Types::Moose qw(ArrayRef Bool HashRef Int Maybe Str Undef);
    use MooseX::MultiMethods;
    use SQL::Translator::Types qw(Column MatchType Table ColumnHash IxHash);
    use Tie::IxHash;

    has 'table' => (
        is => 'rw',
        isa => Table,
        weak_ref => 1,
    );
    
    has 'name' => (
        is => 'rw',
        isa => Str,
        default => '',
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
            clear_columns => 'CLEAR',
        },
        coerce => 1,
        default => sub { Tie::IxHash->new() }
    );
    
    has 'type' => (
        is => 'rw',
        isa => Str,
        predicate => 'has_type',
        required => 1,
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
        isa => ArrayRef,
        traits => ['Array'],
        handles => {
            reference_columns => 'elements',
            add_reference_column => 'push',
        },
        default => sub { [] },
        required => 1,
    );

    has 'match_type' => (
        isa => MatchType,
        is => 'rw',
        coerce => 1,
        lazy => 1,
        default => ''
    );

    has '_order' => (
        isa => Int,
        is => 'rw',
    );

    has 'on_delete' => ( is => 'rw', required => 0);
    has 'on_update' => ( is => 'rw', required => 0);

    around add_column(Column $column does coerce) {
        if ($self->has_type && $self->type eq 'PRIMARY KEY') {
            $column->is_primary_key(1);
        }
        $self->$orig($column->name, $column);
        return $self->get_column($column->name);
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

    method is_valid { return $self->has_type && scalar $self->column_ids ? 1 : undef }

    around BUILDARGS(ClassName $self: @args) {
        my $args = $self->$orig(@args);

        my $fields = delete $args->{fields} || [];

        $fields = ref($fields) eq 'ARRAY' ? $fields : [ $fields ];
        my $ix_hash = Tie::IxHash->new();
        $ix_hash->STORE($_, SQL::Translator::Object::Column->new( name => $_ )) for @$fields;
        $args->{columns} = $ix_hash;

        return $args;
     }
}
