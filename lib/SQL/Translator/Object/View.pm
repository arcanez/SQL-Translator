package SQL::Translator::Object::View;
use Moose;
use MooseX::Types::Moose qw();
use SQL::Translator::Types qw();
extends 'SQL::Translator::Object::Table';

has 'sql' => (
  is => 'rw',
  isa => Str,
  required => 1
);

1;
