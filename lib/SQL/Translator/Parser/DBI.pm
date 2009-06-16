package SQL::Translator::Parser::DBI;
use Class::MOP;
use Moose;
use MooseX::Types::Moose qw(Str);
use SQL::Translator::Types qw(DBIHandle);
use DBI::Const::GetInfoType;
extends 'SQL::Translator::Parser';

has 'dbh' => (
  is => 'rw',
  isa => DBIHandle,
  required => 1
);

has 'translator' => (
  is => 'rw', 
  does => 'SQL::Translator::Parser::DBI::Dialect',
  handles => {
    make_create_string => 'make_create_string',
    make_update_string => 'make_update_string'
  }
);

has 'db_schema' => (
  is => 'rw',
  isa => Str,
  lazy => 1,
  required => 1,
  default => sub { shift->translator->db_schema }
);

has 'quoter' => (
  is => 'rw',
  isa => Str,
  requried => 1,
  default => q{"}
);

has 'namesep' => (
  is => 'rw',
  isa => Str,
  required => 1,
  default => '.'
);

sub BUILD {
    my $self = shift;

    local $self->dbh->{RaiseError} = 1;
    local $self->dbh->{PrintError} = 0;

    my $dbtypename = $self->dbh->get_info( $GetInfoType{SQL_DBMS_NAME} ) || $self->dbh->{Driver}{Name};

    my $class = 'SQL::Translator::Parser::DBI::' . $dbtypename;
    Class::MOP::load_class( $class );    
    my $translator = $class->new( dbh => $self->dbh );
    $self->translator($translator);

    $self->quoter( $self->dbh->get_info(29) || q{"} );
    $self->namesep( $self->dbh->get_info(41) || q{.} );
}

sub _tables_list {
    my $self = shift;

    my $dbh = $self->dbh;
    my @tables = $dbh->tables(undef, $self->db_schema, '%', '%');
    s/\Q$self->quoter\E//g for @tables;
    s/^.*\Q$self->namesep\E// for @tables;

    return @tables;
}

1;
