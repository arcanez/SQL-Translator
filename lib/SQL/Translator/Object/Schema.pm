package SQL::Translator::Object::Schema;
use Moose;
use MooseX::Types::Moose qw(HashRef Str);
use SQL::Translator::Types qw(Procedure Table View);
extends 'SQL::Translator::Object';

has 'name' => (
  is => 'rw',
  isa => Str,
  required => 1,
  default => '__DEFAULT__'
);

has 'tables' => (
  is => 'rw',
  isa => HashRef[Table],
  required => 0
);

has 'views' => (
  is => 'rw',
  isa => HashRef[View],
  required => 0
);

has 'procedures' => (
  is => 'rw',
  isa => HashRef[Procedure],
  required => 0
);

1;
