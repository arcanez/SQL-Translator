package SQL::Translator::Object::Schema;
use namespace::autoclean;
use Moose;
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
    default => sub { {} },
);

has 'views' => (
    metaclass => 'Collection::Hash',
    is => 'rw',
    isa => HashRef[View],
    provides => {
        exists => 'exists_view',
        keys   => 'view_ids',
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

__PACKAGE__->meta->make_immutable;

1;
