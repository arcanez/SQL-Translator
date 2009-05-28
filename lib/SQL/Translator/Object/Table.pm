package SQL::Translator::Object::Table;
use Moose;
use SQL::Translator::Types;

has 'name' => (is => 'ro', isa => 'Str', required => 1);
has 'columns' => (is => 'ro', isa => 'ArrayRef[Column]', required => 1);
has 'indexes' => (is => 'ro', isa => 'ArrayRef[Index]', required => 0);
has 'constraints' => (is => 'ro', isa => 'ArrayRef[Constraint]', required => 0);

1;
