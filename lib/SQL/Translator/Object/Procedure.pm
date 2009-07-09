package SQL::Translator::Object::Procedure;
use namespace::autoclean;
use Moose;
use MooseX::Types::Moose qw(HashRef Int Maybe Str);
use MooseX::AttributeHelpers;
use SQL::Translator::Types qw();
use aliased 'SQL::Translator::Object::Schema';
extends 'SQL::Translator::Object';

has 'name' => (
    is => 'rw',
    isa => Str,
    required => 1
);

has 'contents' => (
    is => 'rw',
    isa => Str,
    required => 1
);

has 'parameters' => (
    metaclass => 'Collection::Hash',
    is => 'rw',
    isa => Maybe[HashRef[Int|Str]],
    provides => {
        exists => 'exists_parameter',
        keys   => 'parameter_ids',
        get    => 'get_parameter',
        set    => 'set_parameter',
    },
);

has 'owner' => (
    is => 'rw',
    isa => Str,
    required => 1
);

has 'comments' => (
    is => 'rw',
    isa => Str,
);

has 'schema' => (
    is => 'rw',
    isa => Schema,
    required => 1,
    default => sub { Schema->new }
);

__PACKAGE__->meta->make_immutable;

1;
