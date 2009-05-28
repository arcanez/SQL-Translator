package SQL::Translator::Object::Trigger;
use Moose;

has 'name' => (is => 'ro', isa => 'Str', required => 1);

1;
