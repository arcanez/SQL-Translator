package SQL::Translator::Parser::DBI::PostgreSQL;
use namespace::autoclean;
use Moose::Role;
use MooseX::Types::Moose qw(Str);

has '+schema_name' => (
  isa => Str,
  lazy => 1,
  default => 'public'
);

sub _get_view_sql {
    my $self = shift;
    my $view = shift;

    my ($sql) = $self->dbh->selectrow_array("SELECT pg_get_viewdef('$view'::regclass)");
    return $sql;
}

sub _is_auto_increment {
    my $self = shift;
    my $column_info = shift;

    return $column_info->{COLUMN_DEF} && $column_info->{COLUMN_DEF} =~ /^nextval\(/ ? 1 : 0;
}

sub _column_default_value {
    my $self = shift;
    my $column_info = shift;
    my $default_value = $column_info->{COLUMN_DEF};

    if (defined $default_value) {
        $default_value =~ s/::.*$//
    }
    return $default_value;
}

1;
