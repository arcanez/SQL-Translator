use MooseX::Declare;
class SQL::Translator::Object::Schema extends SQL::Translator::Object {
    use MooseX::Types::Moose qw(HashRef Maybe Str);
    use MooseX::MultiMethods;
    use Tie::IxHash;
    use SQL::Translator::Types qw(Procedure Table Trigger View ProcedureHash TableHash TriggerHash ViewHash IxHash);
 
    has 'name' => (
        is => 'rw',
        isa => Maybe[Str],
        required => 1,
        default => ''
    );

    has 'database' => (
        is => 'rw',
        isa => Maybe[Str],
    );
    
    has 'tables' => (
        is => 'rw',
        isa => IxHash, #TableHash,
        handles => {
            exists_table => 'EXISTS',
            table_ids    => 'Keys',
            get_tables   => 'Values',
            get_table    => 'FETCH',
            add_table    => 'STORE',
            remove_table => 'DELETE',
        },
        coerce => 1,
        default => sub { Tie::IxHash->new() }
    );
    
    has 'views' => (
        is => 'rw',
        isa => IxHash, #ViewHash,
        handles => {
            exists_view => 'EXISTS',
            view_ids    => 'Keys',
            get_views   => 'Values',
            get_view    => 'FETCH',
            add_view    => 'STORE',
            remove_view => 'DELETE',
        },
        coerce => 1,
        default => sub { Tie::IxHash->new() }
    );
    
    has 'procedures' => (
        is => 'rw',
        isa => IxHash, #ProcedureHash,
        handles => {
            exists_procedure => 'EXISTS',
            procedure_ids    => 'Keys',
            get_procedures   => 'Values',
            get_procedure    => 'FETCH',
            add_procedure    => 'STORE',
            remove_procedure => 'DELETE',
        },
        coerce => 1,
        default => sub { Tie::IxHash->new() }
    );

    has 'triggers' => (
        is => 'rw',
        isa => IxHash, #TriggerHash,
        handles => {
            exists_trigger => 'EXISTS',
            trigger_ids    => 'Keys',
            get_triggers   => 'Values',
            get_trigger    => 'FETCH',
            add_trigger    => 'STORE',
            remove_trigger => 'DELETE',
        },
        coerce => 1,
        default => sub { Tie::IxHash->new() }
    );

    around add_table(Table $table does coerce) {
        die "Can't use table name " . $table->name if $self->exists_table($table->name) || $table->name eq '';
        $table->schema($self);
        $self->$orig($table->name, $table);
        return $self->get_table($table->name);
    }

    around add_view(View $view does coerce) {
        die "Can't use view name " . $view->name if $self->exists_view($view->name) || $view->name eq '';
        $view->schema($self);
        $self->$orig($view->name, $view);
        return $self->get_view($view->name);
    }

    around add_procedure(Procedure $procedure does coerce) {
        $procedure->schema($self);
        $self->$orig($procedure->name, $procedure);
        return $self->get_procedure($procedure->name);
    }

    around add_trigger(Trigger $trigger does coerce) {
        $trigger->schema($self);
        $self->$orig($trigger->name, $trigger);
        return $self->get_trigger($trigger->name);
    }

    method is_valid { return $self->get_tables ? 1 : undef }

    around remove_table(Table|Str $table, Int :$cascade = 0) {
        my $name = is_Table($table) ? $table->name : $table;
        die "Can't drop non-existant table " . $name unless $self->exists_table($name);
        $self->$orig($name);
    }

    around remove_view(View|Str $view) {
        my $name = is_View($view) ? $view->name : $view;
        die "Can't drop non-existant view " . $name unless $self->exists_view($name);
        $self->$orig($name);
    }

    around remove_trigger(Trigger|Str $trigger) {
        my $name = is_Trigger($trigger) ? $trigger->name : $trigger;
####        die "Can't drop non-existant trigger " . $name unless $self->exists_trigger($name);
        $self->$orig($name);
    }

    around remove_procedure(Procedure|Str $procedure) {
        my $name = is_Procedure($procedure) ? $procedure->name : $procedure;
        $self->$orig($name);
    }

    method order { }
    method perform_action_when { }
    method database_events { }
    method fields { }
    method on_table { }
    method action { }
}
