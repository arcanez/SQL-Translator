package SQL::Translator;
use namespace::autoclean;
use Moose;
use MooseX::Types::Moose qw(Str);
use SQL::Translator::Types qw(DBIHandle);

has 'parser' => (
    isa => Str,
    is => 'ro',
    init_arg => 'from',
    required => 1,
);

has 'producer' => (
    isa => Str,
    is => 'ro',
    init_arg => 'to',
    required => 1,
);

has 'dbh' => (
    isa => DBIHandle,
    is => 'ro',
    predicate => 'has_dbh',
);

has 'filename' => (
    isa => Str,
    is => 'ro',
    predicate => 'has_ddl',
);

sub BUILD {}

after BUILD => sub {
    my $self = shift;

    my $parser_class = 'SQL::Translator::Parser'; 
    my $producer_class = 'SQL::Translator::Producer';
    my $producer_role  = $producer_class . '::' . $self->producer;

    Class::MOP::load_class($parser_class);

    my $parser = $parser_class->new({ dbh => $self->dbh });

    Class::MOP::load_class($producer_class);
    Class::MOP::load_class($producer_role);

    my $producer = $producer_class->new({ schema => $parser->parse });
    $producer_role->meta->apply($producer);
    $producer->produce;
};

__PACKAGE__->meta->make_immutable;

1;
