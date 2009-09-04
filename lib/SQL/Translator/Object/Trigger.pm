use MooseX::Declare;
class SQL::Translator::Object::Trigger extends SQL::Translator::Object {
    use MooseX::Types::Moose qw(Any ArrayRef HashRef Str);
    use SQL::Translator::Types qw(Column);
    
    has 'name' => (
        is => 'ro',
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

            ## compat
            get_fields    => 'values',
            fields        => 'keys',
        },
        default => sub { my %hash = (); tie %hash, 'Tie::IxHash'; return \%hash },
    );

    has 'on_table' => (
        is => 'rw', 
        isa => Str,
        required => 1
    );

    has 'action' => (
        is => 'rw',
        isa => Any
    );

    has 'perform_action_when' => (
        is => 'rw',
        isa => Str,
        required => 1
    );

    has 'database_events' => (
        is => 'rw',
        isa => ArrayRef,
        required => 1
    );

    around add_column(Column $column) { $self->$orig($column->name, $column) }
}
