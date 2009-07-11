package SQL::Translator::Object::ForeignKey;
use Moose;
use SQL::Translator::Types qw(Index PrimaryKey);
extends 'SQL::Translator::Object::Constraint';

has '+type' => (
    default => 'FOREIGN_KEY',
);

has 'references' => (
    isa => PrimaryKey | Index,
    is => 'rw',
    required => 1,
);

1;
