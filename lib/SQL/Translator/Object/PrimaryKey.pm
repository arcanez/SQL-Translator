package SQL::Translator::Object::PrimaryKey;
use Moose;
extends 'SQL::Translator::Object::Index';

has '+type' => (
    default => 'PRIMARY_KEY',
);

1;
