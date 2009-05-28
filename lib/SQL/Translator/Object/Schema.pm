package SQL::Translator::Object::Schema;
use Moose;

has 'tables' => (is => 'ro', isa => 'ArrayRef[SQL::Translator::Object::Table]', required => 1);
has 'views' => (is => 'ro', isa => 'ArrayRef[SQL::Translator::Object::View]', required => 0);
has 'procedures' => (is => 'ro', isa => 'ArrayRef[SQL::Translator::Object::Procedure]', required => 0);

1;
