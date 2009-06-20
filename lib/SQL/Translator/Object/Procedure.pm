package SQL::Translator::Object::Procedure;
use Moose;
use MooseX::Types::Moose qw(HashRef Int Maybe Str);
use MooseX::AttributeHelpers;
use SQL::Translator::Types qw();
use SQL::Translator::Object::Schema;
extends 'SQL::Translator::Object';

has 'name' => (
  is => 'rw',
  isa => Str,
  required => 1
);

has 'contents' => (
  is => 'rw',
  isa => Str,
  required => 1
);

has 'parameters' => (
  metaclass => 'Collection::Hash',
  is => 'rw',
  isa => Maybe[HashRef[Int|Str]],
  provides => {
    exists => 'exists_parameter',
    keys   => 'parameter_ids',
    get    => 'get_parameter',
    set    => 'set_parameter',
  },
  required => 0
);

has 'owner' => (
  is => 'rw',
  isa => Str,
  required => 1
);

has 'comments' => (
  is => 'rw',
  isa => Str,
  required => 0
);

has 'schema' => (
  is => 'rw',
  isa => Schema,
  required => 1,
  default => sub { SQL::Translator::Object::Schema->new }
);

1;
