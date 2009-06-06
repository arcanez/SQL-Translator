package SQL::Translator::Object::Column;
use Moose;
use MooseX::Types::Moose qw(Bool Int Str);
use SQL::Translator::Types qw(Trigger);
extends 'SQL::Translator::Object';

has 'name' => (is => 'ro', isa => Str, required => 1);
has 'type' => (is => 'ro', isa => Str, required => 1);
has 'size' => (is => 'ro', isa => Int, required => 1);
has 'is_nullable' => (is => 'ro', isa => Bool, required => 1, default => 1);
has 'is_auto_increment' => (is => 'ro', isa => Bool, required => 1, default => 0);
has 'default_value' => (is => 'ro', isa => Str, required => 0);
has 'trigger' => (is => 'ro', isa => Trigger, required => 0);

1;
