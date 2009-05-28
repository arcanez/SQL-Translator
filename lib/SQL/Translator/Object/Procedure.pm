package SQL::Translator::Object::Procedure;
use Moose;

has 'name' => (is => 'ro', isa => 'Str', required => 1);
has 'contents' => (is => 'ro', isa => 'Str', required => 1);

1;
