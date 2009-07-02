package SQL::Translator::Parser::DBI;
use Moose::Role;
use MooseX::Types::Moose qw(Maybe Str);
use DBI::Const::GetInfoType;
use DBI::Const::GetInfo::ANSI;
use DBI::Const::GetInfoReturn;
use SQL::Translator::Object::Column;
use SQL::Translator::Object::Index;
use SQL::Translator::Object::Table;
use SQL::Translator::Object::View;

has 'quoter' => (
  is => 'rw',
  isa => Str,
  requried => 1,
  lazy => 1,
  default => sub { shift->dbh->get_info(29) || q{"} }
);

has 'namesep' => (
  is => 'rw',
  isa => Str,
  required => 1,
  lazy => 1,
  default => sub { shift->dbh->get_info(41) || '.' }
);

has 'schema_name' => (
  is => 'rw',
  isa => Maybe[Str],
  required => 0,
  lazy => 1,
  default => undef
);

has 'catalog_name' => (
  is => 'rw',
  isa => Maybe[Str],
  required => 0,
  lazy => 1,
  default => undef
);

no Moose::Role;

sub _subclass {
    my $self = shift;

    my $dbtype = $self->dbh->get_info($GetInfoType{SQL_DBMS_NAME}) || $self->dbh->{Driver}{Name};

    my $class = __PACKAGE__ . '::'. $dbtype;
    Class::MOP::load_class($class);
    $class->meta->apply($self);
}

sub _add_tables {
    my $self = shift;
    my $schema = shift;

    my $sth = $self->dbh->table_info($self->catalog_name, $self->schema_name, '%', 'TABLE,VIEW');
    while (my $table_info = $sth->fetchrow_hashref) {
        if ($table_info->{TABLE_TYPE} eq 'TABLE') {
            my $table = SQL::Translator::Object::Table->new({ name => $table_info->{TABLE_NAME} });
            $schema->add_table($table);
            $self->_add_columns($table);
            $self->_add_primary_key($table);
        }
        elsif ($table_info->{TABLE_TYPE} eq 'VIEW') {
            my $sql = $self->_get_view_sql($table_info->{TABLE_NAME});
            $schema->add_view(SQL::Translator::Object::View->new({ name => $table_info->{TABLE_NAME}, sql => $sql }));
        }
    }
}

sub _add_columns {
    my $self  = shift;
    my $table = shift;

    my $sth = $self->dbh->column_info($self->catalog_name, $self->schema_name, $table->name, '%');
    while (my $col_info = $sth->fetchrow_hashref) {
        my $column = SQL::Translator::Object::Column->new({ name => $col_info->{COLUMN_NAME},
                                                            data_type => $col_info->{TYPE_NAME},
                                                            size => $col_info->{COLUMN_SIZE},
                                                            default_value => $col_info->{COLUMN_DEF},
                                                            is_nullable => $col_info->{NULLABLE}, });
        $table->add_column($column);
    }
}

sub _add_primary_key {
    my $self = shift;
    my $table = shift;

    my $pk_info = $self->dbh->primary_key_info($self->catalog_name, $self->schema_name, $table->name);
    my ($pk_name, @pk_cols);
    while (my $pk_col = $pk_info->fetchrow_hashref) {
        $pk_name = $pk_col->{PK_NAME};
        push @pk_cols, $pk_col->{COLUMN_NAME};
    }
    my $index = SQL::Translator::Object::Index->new({ name => $pk_name, type => 'PRIMARY_KEY' });
    $index->add_column($table->get_column($_)) for @pk_cols;
    $table->add_index($index);
}

1;
