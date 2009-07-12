package SQL::Translator::Parser::DBI;
use namespace::autoclean;
use Moose::Role;
use MooseX::Types::Moose qw(Maybe Str);
use DBI::Const::GetInfoType;
use DBI::Const::GetInfo::ANSI;
use DBI::Const::GetInfoReturn;
use aliased 'SQL::Translator::Object::Column';
use aliased 'SQL::Translator::Object::ForeignKey';
use aliased 'SQL::Translator::Object::PrimaryKey';
use aliased 'SQL::Translator::Object::Table';
use aliased 'SQL::Translator::Object::View';

has 'quoter' => (
    is => 'rw',
    isa => Str,
    lazy => 1,
    default => sub { shift->dbh->get_info(29) || q{"} }
);

has 'namesep' => (
    is => 'rw',
    isa => Str,
    lazy => 1,
    default => sub { shift->dbh->get_info(41) || '.' }
);

has 'schema_name' => (
    is => 'rw',
    isa => Maybe[Str],
    lazy => 1,
    default => undef
);

has 'catalog_name' => (
    is => 'rw',
    isa => Maybe[Str],
    lazy => 1,
    default => undef
);

sub _subclass {
    my $self = shift;

    my $dbtype = $self->dbh->get_info($GetInfoType{SQL_DBMS_NAME}) || $self->dbh->{Driver}{Name};

    my $class = __PACKAGE__ . '::'. $dbtype;
    Class::MOP::load_class($class);
    $class->meta->apply($self);
}

sub _is_auto_increment { 0 }

sub _column_default_value {
    my $self = shift;
    my $column_info = shift;

    return $column_info->{COLUMN_DEF};
}

sub _add_tables {
    my $self = shift;
    my $schema = shift;

    my $sth = $self->dbh->table_info($self->catalog_name, $self->schema_name, '%', 'TABLE,VIEW');
    while (my $table_info = $sth->fetchrow_hashref) {
        if ($table_info->{TABLE_TYPE} eq 'TABLE') {
            my $table = Table->new({ name => $table_info->{TABLE_NAME} });
            $schema->add_table($table);
            $self->_add_columns($table);
            $self->_add_primary_key($table);
        }
        elsif ($table_info->{TABLE_TYPE} eq 'VIEW') {
            my $sql = $self->_get_view_sql($table_info->{TABLE_NAME});
            my $view = View->new({ name => $table_info->{TABLE_NAME}, sql => $sql });
            $schema->add_view($view);
            $self->_add_columns($view);
        }
    }
    $self->_add_foreign_key($schema->get_table($_), $schema) for $schema->table_ids;
}

sub _add_columns {
    my $self  = shift;
    my $table = shift;

    my $sth = $self->dbh->column_info($self->catalog_name, $self->schema_name, $table->name, '%');
    while (my $column_info = $sth->fetchrow_hashref) {
        my $column = Column->new({ name => $column_info->{COLUMN_NAME},
                                   data_type => $column_info->{DATA_TYPE},
                                   size => $column_info->{COLUMN_SIZE},
                                   default_value => $self->_column_default_value($column_info),
                                   is_auto_increment => $self->_is_auto_increment($column_info),
                                   is_nullable => $column_info->{NULLABLE},
                                 });
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
    my $pk = PrimaryKey->new({ name => $pk_name });
    $pk->add_column($table->get_column($_)) for @pk_cols;
    $table->add_index($pk);
}

sub _add_foreign_key {
    my $self = shift;
    my $table = shift;
    my $schema = shift;

    my $fk_info = $self->dbh->foreign_key_info($self->catalog_name, $self->schema_name, $table->name, $self->catalog_name, $self->schema_name, undef);
    return unless $fk_info;

    my $fk_data;
    while (my $fk_col = $fk_info->fetchrow_hashref) {
        my $fk_name = $fk_col->{FK_NAME}; 

        push @{$fk_data->{$fk_name}{columns}}, $fk_col->{FK_COLUMN_NAME};
        $fk_data->{$fk_name}{table} = $fk_col->{FK_TABLE_NAME};
        $fk_data->{$fk_name}{uk} = $schema->get_table($fk_col->{UK_TABLE_NAME})->get_index($fk_col->{UK_NAME});
    }

    foreach my $fk_name (keys %$fk_data) {
        my $fk = ForeignKey->new({ name => $fk_name, references => $fk_data->{$fk_name}{uk} });
        $fk->add_column($schema->get_table($fk_data->{$fk_name}{table})->get_column($_)) for @{$fk_data->{$fk_name}{columns}};
        $table->add_constraint($fk);
    }
}

1;
