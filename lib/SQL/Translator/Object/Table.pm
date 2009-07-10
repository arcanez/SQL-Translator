package SQL::Translator::Object::Table;
use namespace::autoclean;
use Moose;
use MooseX::Types::Moose qw(HashRef Str);
use MooseX::AttributeHelpers;
use SQL::Translator::Types qw(Column Constraint Index Schema Sequence);
use SQL::Translator::Object::Schema;
extends 'SQL::Translator::Object';

has 'name' => (
    is => 'rw',
    isa => Str,
    required => 1
);

has 'columns' => (
    metaclass => 'Collection::Hash',
    is => 'rw',
    isa => HashRef[Column],
    provides => {
        exists => 'exists_column',
        keys   => 'column_ids',
        get    => 'get_column',
    },
    curries => {
        set => {
            add_column => sub {
                my ($self, $body, $column) = @_;
                $self->$body($column->name, $column);
            }
        }
    },
    default => sub { my %hash = (); tie %hash, 'Tie::IxHash'; return \%hash },
);

has 'indexes' => (
    metaclass => 'Collection::Hash',
    is => 'rw',
    isa => HashRef[Index],
    provides => {
        exists => 'exists_index',
        keys   => 'index_ids',
        get    => 'get_index',
    },
    curries => {
        set => {
            add_index => sub {
                my ($self, $body, $index) = @_;
                $self->$body($index->name, $index);
            }
        }
    },
    default => sub { {} },
);

has 'constraints' => (
    metaclass => 'Collection::Hash',
    is => 'rw',
    isa => HashRef[Constraint],
    provides => {
        exists => 'exists_constraint',
        keys   => 'constraint_ids',
        get    => 'get_constraint',
    },
    curries => {
        set => {
            add_constraint => sub {
                my ($self, $body, $constraint) = @_;
                $self->$body($constraint->name, $constraint);
            }
        }
    },
    default => sub { {} },
);

has 'sequences' => (
    metaclass => 'Collection::Hash',
    is => 'rw',
    isa => HashRef[Sequence],
    provides => {
        exists => 'exists_sequence',
        keys   => 'sequence_ids',
        get    => 'get_sequence',
    },
    curries => {
        set => {
            add_sequence => sub {
                my ($self, $body, $sequence) = @_;
                $self->$body($sequence->name, $sequence);
            }
        }
    },
    default => sub { {} },
);

__PACKAGE__->meta->make_immutable;

1;
