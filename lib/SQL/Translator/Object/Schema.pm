package SQL::Translator::Object::Schema;
use Moose;
use MooseX::Types::Moose qw(ArrayRef Str);
use SQL::Translator::Types qw(Procedure Table View);
extends 'SQL::Translator::Object';

has 'name' => (is => 'ro', isa => Str, required => 1, default => '__DEFAULT__');
has 'tables' => (is => 'ro', isa => ArrayRef[Table], required => 0);
has 'views' => (is => 'ro', isa => ArrayRef[View], required => 0);
has 'procedures' => (is => 'ro', isa => ArrayRef[Procedure], required => 0);

1;
