package SQL::Translator::Object::Constraint;
use Moose;
use MooseX::Types::Moose qw(ArrayRef Str);
use SQL::Translator::Types qw(Column);
extends 'SQL::Translator::Object';

has 'name' => (is => 'ro', isa => Str, required => 1);
has 'columns' => (is => 'ro', isa => ArrayRef[Column], required => 1);
has 'type' => (is => 'ro', isa => Str, required => 1);

1;
