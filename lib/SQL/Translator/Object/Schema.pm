package SQL::Translator::Object::Schema;
use Moose;
use MooseX::Types::Moose qw(ArrayRef);
use SQL::Translator::Types qw(Procedure Table View);

has 'tables' => (is => 'ro', isa => ArrayRef[Table], required => 1);
has 'views' => (is => 'ro', isa => ArrayRef[View], required => 0);
has 'procedures' => (is => 'ro', isa => ArrayRef[Procedure], required => 0);

1;
