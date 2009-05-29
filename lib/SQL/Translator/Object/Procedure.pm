package SQL::Translator::Object::Procedure;
use Moose;
use MooseX::Types::Moose qw(Str);
use SQL::Translator::Types qw();

has 'name' => (is => 'ro', isa => Str, required => 1);
has 'contents' => (is => 'ro', isa => Str, required => 1);

1;
