package SQL::Translator::Object::View;
use Moose;

extends 'SQL::Translator::Object::Table';
has 'sql' => (is => 'ro', isa => 'Str', required => 1);

1;
