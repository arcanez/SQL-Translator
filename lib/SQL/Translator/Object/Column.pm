package SQL::Translator::Object::Column;
use namespace::autoclean;
use Moose;
use MooseX::Types::Moose qw(Bool Int Maybe Str);
use SQL::Translator::Types qw(Trigger);
extends 'SQL::Translator::Object';

has 'name' => (
  is => 'rw',
  isa => Str,
  required => 1
);

has 'data_type' => (
  is => 'rw',
  isa => Str,
  required => 1
);

has 'size' => (
  is => 'rw',
  isa => Maybe[Int],
  required => 1
);

has 'is_nullable' => (
  is => 'rw',
  isa => Bool,
  required => 1,
  default => 1
);

has 'is_auto_increment' => (
  is => 'rw',
  isa => Bool,
  required => 1,
  default => 0
);

has 'default_value' => (
  is => 'rw',
  isa => Maybe[Str],
  required => 0
);

has 'remarks' => (
  is => 'rw',
  isa => Maybe[Str],
  required => 0
);

has 'trigger' => (
  is => 'rw',
  isa => Trigger,
  required => 0
);

__PACKAGE__->meta->make_immutable;

1;
