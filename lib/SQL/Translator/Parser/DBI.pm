package SQL::Translator::Parser::DBI;
use Class::MOP;
use Moose;
use MooseX::Types::Moose qw(Str);
use DBI::Const::GetInfoType;
use DBI::Const::GetInfo::ANSI;
use DBI::Const::GetInfoReturn;
use SQL::Translator::Types qw(DBIHandle Schema);
use Data::Dumper; 
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
    make_update_string => 'make_update_string',
    _tables_list => '_tables_list',
    _table_columns => '_table_columns',
    _table_pk_info => '_table_pk_info',
    _table_uniq_info => '_table_uniq_info',
    _table_fk_info => '_table_fk_info',
    _columns_info_for => '_columns_info_for',
    _extra_column_info => '_extra_column_info',
  }
);

has 'schema' => (
  is => 'rw',
  isa => Schema,
  lazy => 1,
  required => 1,
  default => sub { shift->translator->schema }
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

    my $tables = $self->_tables_list;

    $self->schema->tables($self->_tables_list);
    $self->schema->get_table($_)->columns($self->_columns_info_for($_)) for keys %$tables;

#    foreach my $table (keys %$tables) {
#        my $columns = $self->_columns_info_for($table);
#        my $table = $self->schema->get_table($key);
#        $table->columns($columns);
#         $self->schema->get_table($key)->columns($columns);
#    }

    print Dumper($self->schema);
}

1;
