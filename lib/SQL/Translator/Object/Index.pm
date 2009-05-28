package SQL::Translator::Object::Index;
use Moose;
use SQL::Translator::Types;

has 'name' => (is => 'ro', isa => 'Str', required => 1);
has 'columns' => (is => 'ro', isa => 'ArrayRef[Column]', required => 1);
has 'type' => (is => 'ro', isa => 'Str', required => 1);

1;
