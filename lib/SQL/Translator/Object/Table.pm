package SQL::Translator::Object::Table;
use Moose;
use MooseX::Types::Moose qw(HashRef Str);
use MooseX::AttributeHelpers;
#use MooseX::Types::Set::Object;
use SQL::Translator::Types qw(Column Constraint Index Schema);
use SQL::Translator::Object::Schema;
extends 'SQL::Translator::Object';

has 'name' => (
  is => 'ro',
  isa => Str,
  required => 1
);

has 'columns' => (
  metaclass => 'Collection::Hash',
  is => 'rw',
  isa => HashRef[Column],
  required => 1
);

has 'indexes' => (
  metaclass => 'Collection::Hash',
  is => 'rw',
  isa => HashRef[Index],
  required => 0
);

has 'constraints' => (
  metaclass => 'Collection::Hash',
  is => 'rw',
  isa => HashRef[Constraint],
  required => 0
);

has 'schema' => (
  is => 'ro',
  isa => Schema,
  required => 1,
  default => sub { SQL::Translator::Object::Schema->new }
);

1;
