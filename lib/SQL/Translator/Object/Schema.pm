use MooseX::Declare;
class SQL::Translator::Object::Schema {
    use MooseX::Types::Moose qw(HashRef Maybe Str);
    use MooseX::AttributeHelpers;
    use SQL::Translator::Types qw(Procedure Table View);
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
        },
        curries => {
            set => {
                add_table => sub {
                    my ($self, $body, $table) = @_;
                    $self->$body($table->name, $table);
                }
            }
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
        },
        curries => {
            set => { 
                add_view => sub {
                    my ($self, $body, $view) = @_;
                    $self->$body($view->name, $view);
                }
            }
        },
        default => sub { {} },
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
        },
        curries => {
            set => {
                add_procedure => sub {
                    my ($self, $body, $procedure) = @_;
                    $self->$body($procedure->name, $procedure);
                }
            }
        },
        default => sub { {} },
    );

    method is_valid { 1 }
}
