package SQL::Translator::Object::Constraint;
use Moose;
use MooseX::Types::Moose qw(HashRef Str);
use SQL::Translator::Types qw(Column);
extends 'SQL::Translator::Object';

has 'name' => (
  is => 'rw',
  isa => Str,
  required => 1
);

has 'columns' => (
  is => 'rw',
  isa => HashRef[Column],
  required => 1
);

has 'type' => (
  is => 'rw',
  isa => Str,
  required => 1
);

1;
