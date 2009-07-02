package SQL::Translator::Object::Index;
use Moose;
use MooseX::Types::Moose qw(HashRef Str);
use MooseX::AttributeHelpers;
use SQL::Translator::Types qw(Column);
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

has 'type' => (
  is => 'rw',
  isa => Str,
  required => 1
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
