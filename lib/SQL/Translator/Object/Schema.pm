package SQL::Translator::Object::Schema;
use Moose;
use MooseX::Types::Moose qw(HashRef Str);
use MooseX::AttributeHelpers;
use SQL::Translator::Types qw(Procedure Table View);
extends 'SQL::Translator::Object';

has 'name' => (
  is => 'rw',
  isa => Str,
  required => 1,
  default => '__DEFAULT__'
);

has 'tables' => (
  metaclass => 'Collection::Hash',
  is => 'rw',
  isa => HashRef[Table],
  provides => {
    exists => 'exists_table',
    keys   => 'table_ids',
    get    => 'get_table',
    set    => 'set_table',
  },
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
    set    => 'set_view',
  },
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
  required => 0
);

1;
