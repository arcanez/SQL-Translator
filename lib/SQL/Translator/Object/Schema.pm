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
        traits => ['Hash'],
        is => 'rw',
        isa => HashRef[Table],
        handles => {
            exists_table => 'exists',
            table_ids    => 'keys',
            get_tables   => 'values',
            get_table    => 'get',
            add_table    => 'set',
            remove_table => 'delete',
        },
        default => sub { my %hash = (); tie %hash, 'Tie::IxHash'; return \%hash },
    );
    
    has 'views' => (
        traits => ['Hash'],
        is => 'rw',
        isa => HashRef[View],
        handles => {
            exists_view => 'exists',
            view_ids    => 'keys',
            get_views   => 'values',
            get_view    => 'get',
            add_view    => 'set',
            remove_view => 'delete',
        },
        default => sub { my %hash = (); tie %hash, 'Tie::IxHash'; return \%hash },
    );
    
    has 'procedures' => (
        traits => ['Hash'],
        is => 'rw',
        isa => HashRef[Procedure],
        handles => {
            exists_procedure => 'exists',
            procedure_ids    => 'keys',
            get_procedures   => 'values',
            get_procedure    => 'get',
            add_procedure    => 'set',
            remove_procedure => 'delete',
        },
        default => sub { my %hash = (); tie %hash, 'Tie::IxHash'; return \%hash },
    );

    has 'triggers' => (
        traits => ['Hash'],
        is => 'rw',
        isa => HashRef[Trigger],
        handles => {
            exists_trigger => 'exists',
            trigger_ids    => 'keys',
            get_triggers   => 'values',
            get_trigger    => 'get',
            add_trigger    => 'set',
            remove_trigger => 'delete',
        },
        default => sub { my %hash = (); tie %hash, 'Tie::IxHash'; return \%hash },
    );

    around add_table(Table $table does coerce) {
        die "Can't use table name " . $table->name if $self->exists_table($table->name) || $table->name eq '';
        $table->schema($self);
        $self->$orig($table->name, $table);
    }

    around add_view(View $view does coerce) {
        die "Can't use view name " . $view->name if $self->exists_view($view->name) || $view->name eq '';
        $view->schema($self);
        $self->$orig($view->name, $view)
    }

    around add_procedure(Procedure $procedure does coerce) {
        $procedure->schema($self);
        $self->$orig($procedure->name, $procedure) 
    }

    around add_trigger(Trigger $trigger does coerce) {
        $trigger->schema($self);
        $self->$orig($trigger->name, $trigger);;
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
