package SQL::Translator::Parser::DBI::SQLite;
use Moose;
use MooseX::Types::Moose qw(Str);
use SQL::Translator::Types qw(DBIHandle);
with 'SQL::Translator::Parser::DBI::Dialect';

has 'schema' => (is => 'ro', isa => Str, default => { sub { SQL::Translator::Object::Schema->new( { name => '' }));

sub _tables_list {
    my $self = shift;

    my $dbh = $self->dbh;
    my $sth = $dbh->prepare("SELECT * FROM sqlite_master");
    $sth->execute;
    my @tables;
    while ( my $row = $sth->fetchrow_hashref ) {
        next unless lc( $row->{type} ) eq 'table';
        next if $row->{tbl_name} =~ /^sqlite_/;
        push @tables, $row->{tbl_name};
    }
    $sth->finish;
    return @tables;
}

1;
