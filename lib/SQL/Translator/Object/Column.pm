package SQL::Translator::Object::Column;
use Moose;
use MooseX::Types::Moose qw(Bool Int Str);
use SQL::Translator::Types qw(Trigger);
extends 'SQL::Translator::Object';

has 'name' => (
  is => 'rw',
  isa => Str,
  required => 1
);

has 'type' => (
  is => 'rw',
  isa => Str,
  required => 1
);

has 'size' => (
  is => 'rw',
  isa => Int,
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

has 'is_primary_key' => (
  is => 'rw',
  isa => Bool,
  required => 1,
  default => 0
);

has 'is_foriegn_key' => (
  is => 'rw',
  isa => Bool,
  required => 1,
  default => 0
);

has 'is_unique' => (
  is => 'rw',
  isa => Bool,
  required => 1,
  default => 0
);

has 'default_value' => (
  is => 'rw',
  isa => Str,
  required => 0
);

has 'trigger' => (
  is => 'rw',
  isa => Trigger,
  required => 0
);

has 'index' => (
  is => 'rw',
  isa => Int,
  required => 1
);

1;
