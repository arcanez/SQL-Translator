package SQL::Translator::Object::Table;
use Moose;
use MooseX::Types::Moose qw(ArrayRef Str);
use SQL::Translator::Types qw(Column Constraint Index Schema);
use SQL::Translator::Object::Schema;
extends 'SQL::Translator::Object';

has 'name' => (is => 'ro', isa => Str, required => 1);
has 'columns' => (is => 'ro', isa => ArrayRef[Column], required => 1);
has 'indexes' => (is => 'ro', isa => ArrayRef[Index], required => 0);
has 'constraints' => (is => 'ro', isa => ArrayRef[Constraint], required => 0);
has 'schema' => (is => 'ro', isa => Schema, required => 1, default => sub { SQL::Translator::Object::Schema->new } );

1;
