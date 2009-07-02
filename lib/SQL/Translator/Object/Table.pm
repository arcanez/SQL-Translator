package SQL::Translator::Object::Table;
use Moose;
use MooseX::Types::Moose qw(HashRef Str);
use MooseX::AttributeHelpers;
use SQL::Translator::Types qw(Column Constraint Index Schema);
use SQL::Translator::Object::Schema;
extends 'SQL::Translator::Object';

has 'name' => (
  is => 'rw',
  isa => Str,
  required => 1
);

has 'columns' => (
  metaclass => 'Collection::Hash',
  is => 'rw',
  isa => HashRef[Column],
  provides => {
    exists => 'exists_column',
    keys   => 'column_ids',
    get    => 'get_column',
#    set    => 'set_column',
  },
  curries => { set => { add_column => sub { my ($self, $body, $column) = @_; $self->$body($column->name, $column); } } },
  default => sub { {} },
  required => 0
);

has 'indexes' => (
  metaclass => 'Collection::Hash',
  is => 'rw',
  isa => HashRef[Index],
  provides => {
    exists => 'exists_index',
    keys   => 'index_ids',
    get    => 'get_index',
#    set    => 'set_index',
  },
  curries => { set => { add_index => sub { my ($self, $body, $index) = @_; $self->$body($index->name, $index); } } },
  default => sub { {} },
  required => 0
);

has 'constraints' => (
  metaclass => 'Collection::Hash',
  is => 'rw',
  isa => HashRef[Constraint],
  provides => {
    exists => 'exists_constraint',
    keys   => 'constraint_ids',
    get    => 'get_constraint',
    set    => 'set_constraint',
  },
  default => sub { {} },
  required => 0
);

=cut
has 'schema' => (
  is => 'rw',
  isa => Schema,
  required => 0,
  default => sub { SQL::Translator::Object::Schema->new }
);
=cut
no Moose;
__PACKAGE__->meta()->make_immutable;

1;
