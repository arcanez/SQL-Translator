package SQL::Translator::Parser::DBI::PostgreSQL;
use Moose::Role;
use MooseX::Types::Moose qw(Str);

has 'schema_name' => (
  is => 'rw',
  isa => Str,
  required => 1,
  lazy => 1,
  default => 'public'
);

no Moose::Role;

sub _get_view_sql {
    my $self = shift;
    my $view = shift;

    my ($sql) = $self->dbh->selectrow_array("SELECT pg_get_viewdef('$view'::regclass)");
    return $sql;
}

1;
