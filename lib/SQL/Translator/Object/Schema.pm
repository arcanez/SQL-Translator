use MooseX::Declare;
class SQL::Translator::Object::Schema extends SQL::Translator::Object {
    use MooseX::Types::Moose qw(HashRef Maybe Str);
    use SQL::Translator::Types qw(Procedure Table Trigger View);
    use MooseX::MultiMethods;
 
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
        },
        default => sub { my %hash = (); tie %hash, 'Tie::IxHash'; return \%hash },
    );

    around add_table(Table $table) {
        die "Can't use table name " . $table->name if $self->exists_table($table->name) || $table->name eq '';
        $self->$orig($table->name, $table);
    }
    around add_view(View $view) { $self->$orig($view->name, $view) }
    around add_procedure(Procedure $procedure) { $self->$orig($procedure->name, $procedure) }
    around add_trigger(Trigger $trigger) { $self->$orig($trigger->name, $trigger) }

    method is_valid { return $self->get_tables ? 1 : undef }

    multi method drop_table(Table $table, Int :$cascade = 0) {
        die "Can't drop non-existant table " . $table->name unless $self->exists_table($table->name);
        $self->remove_table($table->name);
        
    }

    multi method drop_table(Str $table, Int :$cascade = 0) {
        die "Can't drop non-existant table " . $table unless $self->exists_table($table);
        $self->remove_table($table);
    }

    method order { }
    method perform_action_when { }
    method database_events { }
    method fields { }
    method on_table { }
    method action { }
}
