package SQL::Translator::Object::Procedure;
use Moose;
use MooseX::Types::Moose qw(Str);
use SQL::Translator::Types qw();
use SQL::Translator::Object::Schema;

has 'name' => (is => 'ro', isa => Str, required => 1);
has 'contents' => (is => 'ro', isa => Str, required => 1);
has 'parameters' => (is => 'ro', isa => Maybe[ArrayRef[Int|Str]], required => 0);	
has 'owner' => (is => 'ro', isa => Str, required => 1);
has 'comments' => (is => 'ro', isa => Str, required => 0);
has 'schema' => (is => 'ro', isa => Schema, required => 1, default => sub { SQL::Translator::Object::Schema->new });

1;
