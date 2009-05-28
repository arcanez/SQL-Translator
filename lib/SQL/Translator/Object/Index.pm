package SQL::Translator::Object::Index;
use Moose;

has 'name' => (is => 'ro', isa => 'Str', required => 1);
has 'columns' => (is => 'ro', isa => 'ArrayRef[SQL::Translator::Object::Column]', required => 1);
has 'type' => (is => 'ro', isa => 'Str', required => 1);

1;
