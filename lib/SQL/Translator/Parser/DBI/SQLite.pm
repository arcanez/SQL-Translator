package SQL::Translator::Parser::DBI::SQLite;
use Moose;
use SQL::Translator::Types qw(Schema);
use SQL::Translator::Object::Table;
with 'SQL::Translator::Parser::DBI::Dialect';

has 'schema' => (is => 'ro', isa => Schema, default => sub { SQL::Translator::Object::Schema->new( { name => '' }) });

sub _tables_list {
    my $self = shift;

    my $dbh = $self->dbh;
    my $sth = $dbh->prepare("SELECT * FROM sqlite_master WHERE type = 'table'");
    $sth->execute;

    my %tables;
    while ( my $row = $sth->fetchrow_hashref ) {
        next if $row->{tbl_name} =~ /^sqlite_/;
        $tables{$row->{tbl_name}} = SQL::Translator::Object::Table->new( { name => $row->{tbl_name}, schema => $self->schema } );
    }
    $sth->finish;
    return \%tables;
}

1;
