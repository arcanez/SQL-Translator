use MooseX::Declare;
class SQL::Translator::Object::Index extends SQL::Translator::Object {
    use MooseX::Types::Moose qw(HashRef Str);
    use MooseX::MultiMethods;
    use SQL::Translator::Types qw(Column Table ColumnHash IxHash);
    use Tie::IxHash;

    has 'table' => (
        is => 'rw',
        isa => Table,
        weak_ref => 1,
    );
    
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
            clear_columns => 'CLEAR',
        },
        coerce => 1,
        default => sub { Tie::IxHash->new() }
    );

    has 'type' => (
        is => 'rw',
        isa => Str,
        required => 1,
        default => 'NORMAL',
    );

    around add_column(Column $column) {
        $self->$orig($column->name, $column);
        return $self->get_column($column->name);
    }

    method is_valid { $self->table && scalar $self->get_columns ? 1 : undef }
}
