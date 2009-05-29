package SQL::Translator::Object::Column;
use Moose;
use MooseX::Types::Moose qw(Bool Int Str);
use SQL::Translator::Types qw(Trigger);

has 'name' => (is => 'ro', isa => Str, required => 1);
has 'type' => (is => 'ro', isa => Str, required => 1);
has 'size' => (is => 'ro', isa => Int, required => 1);
has 'nullable' => (is => 'ro', isa => Bool, required => 1, default => 1);
has 'default' => (is => 'ro', isa => Str, required => 0);
has 'trigger' => (is => 'ro', isa => Trigger, required => 0);

1;
