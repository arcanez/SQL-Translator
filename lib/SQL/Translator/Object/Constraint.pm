package SQL::Translator::Object::Constraint;
use namespace::autoclean;
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
    set    => 'set_column',
  },
  required => 1
);

has 'type' => (
  is => 'rw',
  isa => Str,
  required => 1
);

__PACKAGE__->meta->make_immutable;

1;
