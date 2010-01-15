use MooseX::Declare;
class SQL::Translator::Object::Constraint extends SQL::Translator::Object {
    use MooseX::Types::Moose qw(ArrayRef Bool HashRef Maybe Str Undef);
    use MooseX::MultiMethods;
    use SQL::Translator::Types qw(Column MatchType Table);

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
        traits => ['Hash'],
        is => 'rw',
        isa => HashRef[Column],
        handles => {
            exists_column => 'exists',
            column_ids    => 'keys',
            get_columns   => 'values',
            get_column    => 'get',
            add_column    => 'set',
            clear_columns => 'clear',
        },
        default => sub { my %hash = (); tie %hash, 'Tie::IxHash'; return \%hash },
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

    around add_column(Column $column) {
        if ($self->has_type && $self->type eq 'PRIMARY KEY') {
            $column->is_primary_key(1);
        }
        $self->$orig($column->name, $column)
    }

    method is_valid { return $self->has_type && scalar $self->column_ids ? 1 : undef }
}
