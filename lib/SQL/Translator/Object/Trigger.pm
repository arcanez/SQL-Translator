use MooseX::Declare;
class SQL::Translator::Object::Trigger extends SQL::Translator::Object {
    use MooseX::Types::Moose qw(Any ArrayRef HashRef Int Str);
    use MooseX::MultiMethods;
    use SQL::Translator::Types qw(Column Schema Table);

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

    around add_column(Column $column) { $self->$orig($column->name, $column) }

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

        $args->{_database_events} = delete $args->{database_events} || [];

        return $args;
     }
}
