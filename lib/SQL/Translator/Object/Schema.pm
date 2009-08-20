use MooseX::Declare;
class SQL::Translator::Object::Schema {
    use MooseX::Types::Moose qw(HashRef Maybe Str);
    use MooseX::AttributeHelpers;
    use SQL::Translator::Types qw(Procedure Table Trigger View);
    extends 'SQL::Translator::Object';
 
    has 'name' => (
        is => 'rw',
        isa => Maybe[Str],
        required => 1,
        default => ''
    );
    
    has 'tables' => (
        metaclass => 'Collection::Hash',
        is => 'rw',
        isa => HashRef[Table],
        provides => {
            exists => 'exists_table',
            keys   => 'table_ids',
            values => 'get_tables',
            get    => 'get_table',
            set    => 'add_table',
        },
        default => sub { my %hash = (); tie %hash, 'Tie::IxHash'; return \%hash },
    );
    
    has 'views' => (
        metaclass => 'Collection::Hash',
        is => 'rw',
        isa => HashRef[View],
        provides => {
            exists => 'exists_view',
            keys   => 'view_ids',
            values => 'get_views',
            get    => 'get_view',
            set    => 'add_view',
        },
        default => sub { my %hash = (); tie %hash, 'Tie::IxHash'; return \%hash },
    );
    
    has 'procedures' => (
        metaclass => 'Collection::Hash',
        is => 'rw',
        isa => HashRef[Procedure],
        provides => {
            exists => 'exists_procedure',
            keys   => 'procedure_ids',
            values => 'get_procedures',
            get    => 'get_procedure',
            set    => 'add_procedure',
        },
        default => sub { my %hash = (); tie %hash, 'Tie::IxHash'; return \%hash },
    );

    has 'triggers' => (
        metaclass => 'Collection::Hash',
        is => 'rw',
        isa => HashRef[Trigger],
        provides => {
            exists => 'exists_trigger',
            keys   => 'trigger_ids',
            values => 'get_triggers',
            get    => 'get_trigger',
            set    => 'add_trigger',
        },
        default => sub { my %hash = (); tie %hash, 'Tie::IxHash'; return \%hash },
    );

    around add_table(Table $table) { $self->$orig($table->name, $table) }
    around add_view(View $view) { $self->$orig($view->name, $view) }
    around add_procedure(Procedure $procedure) { $self->$orig($procedure->name, $procedure) }
    around add_trigger(Trigger $trigger) { $self->$orig($trigger->name, $trigger) }

    method is_valid { 1 }

    method order { }
    method perform_action_when { }
    method database_events { }
    method fields { }
    method on_table { }
    method action { }
    method extra { }
}
