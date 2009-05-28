package SQL::Translator::Object::Table;
use Moose;

has 'name' => (is => 'ro', isa => 'Str', required => 1);
has 'columns' => (is => 'ro', isa => 'ArrayRef[SQL::Translator::Object::Column]', required => 1);
has 'indexes' => (is => 'ro', isa => 'ArrayRef[SQL::Translator::Object::Index]', required => 0);
has 'constraints' => (is => 'ro', isa => 'ArrayRef[SQL::Translator::Object::Constraint]', required => 0);

1;
