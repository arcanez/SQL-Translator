use MooseX::Declare;
class SQL::Translator::Object::Trigger extends SQL::Translator::Object {
    use MooseX::Types::Moose qw(Any ArrayRef HashRef Int Str);
    use MooseX::MultiMethods;
    use SQL::Translator::Types qw(Column Schema Table ColumnHash IxHash);
    use Tie::IxHash;

    has 'schema' => (
        is => 'rw',
        isa => Schema,
        weak_ref => 1,
    );

    has 'table' => (
        is => 'rw',
        isa => Table,
        weak_ref => 1,
    );

    has 'name' => (
        is => 'ro',
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

    has 'on_table' => (
        is => 'rw', 
        isa => Str,
        required => 1,
#        trigger => sub { my ($self, $new, $old) = @_; $self->table($self->schema->get_table($new)) },
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

    has '_database_events' => (
        traits => ['Array'],
        isa => ArrayRef,
        handles => {
            _database_events            => 'elements',
            add_database_event          => 'push',
            remove_last_database_option => 'pop',
        },
        default => sub { [] },
        required => 1,
    );

    has '_order' => (
        isa => Int,
        is => 'rw',
    );

    around add_column(Column $column) {
        $self->$orig($column->name, $column);
        return $self->get_column($column->name);
    }

    multi method database_events(Str $database_event) { $self->add_database_event($database_event); $self->database_events }
    multi method database_events(ArrayRef $database_events) { $self->add_database_event($_) for @$database_events; $self->database_events }
    multi method database_events { $self->_database_events }

    multi method order(Int $order) { $self->_order($order); }
    multi method order {
        my $order = $self->_order;
        unless (defined $order && $order) {
            my $triggers = Tie::IxHash->new( map { $_->name => $_ } $self->schema->get_triggers );
            $order = $triggers->Indices($self->name) || 0; $order++;
            $self->_order($order);
        }
        return $order;
    }

    method is_valid { 1 }

    around BUILDARGS(ClassName $self: @args) {
        my $args = $self->$orig(@args);

        my $database_events = delete $args->{database_events};
        $args->{_database_events} = ref $database_events ? $database_events : [ $database_events ];

        return $args;
     }
}
