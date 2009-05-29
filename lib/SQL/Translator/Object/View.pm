package SQL::Translator::Object::View;
use Moose;
use MooseX::Types::Moose qw(ArrayRef);
use SQL::Translator::Types qw();

extends 'SQL::Translator::Object::Table';

has 'sql' => (is => 'ro', isa => Str, required => 1);

1;
