package SQL::Translator::Object::Schema;
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
#    set    => 'add_table',
  },
  curries => { set => { add_table => sub { my ($self, $body, $table) = @_; $self->$body($table->name, $table); } } },
  default => sub { {} },
  required => 0
);

has 'views' => (
  metaclass => 'Collection::Hash',
  is => 'rw',
  isa => HashRef[View],
  provides => {
    exists => 'exists_view',
    keys   => 'view_ids',
    get    => 'get_view',
#    set    => 'set_view',
  },
  curries => { set => { add_view => sub { my ($self, $body, $view) = @_; $self->$body($view->name, $view); } } },
  default => sub { {} },
  required => 0
);

has 'procedures' => (
  metaclass => 'Collection::Hash',
  is => 'rw',
  isa => HashRef[Procedure],
  provides => {
    exists => 'exists_procedure',
    keys   => 'procedure_ids',
    get    => 'get_procedure',
    set    => 'set_procedure',
  },
  default => sub { {} },
  required => 0
);

no Moose;
__PACKAGE__->meta()->make_immutable;

1;
