package SQL::Translator::Parser::DBI::Dialect;
use Moose::Role;
use MooseX::Types::Moose qw(Str);
use SQL::Translator::Types qw(DBIHandle);
use SQL::Translator::Object::Column;
use SQL::Translator::Object::Table;
use SQL::Translator::Object::Schema;

has 'dbh' => (
  is => 'rw',
  isa => DBIHandle,
  required => 1
);

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

sub BUILD {
}

sub _tables_list {
    my $self = shift;

    my $dbh = $self->dbh;
    my $quoter = $self->quoter;
    my $namesep = $self->namesep;

    my @tables = $dbh->tables(undef, $self->schema->name, '%', '%');

    s/\Q$quoter\E//g for @tables;
    s/^.*\Q$namesep\E// for @tables;

    my %retval;
    map { $retval{$_} = SQL::Translator::Object::Table->new({ name => $_, schema => $self->schema }) } @tables;

    return \%retval;
}

sub _table_columns {
    my ($self, $table) = @_;

    my $dbh = $self->dbh;

    if($self->schema->name) {
        $table = $self->schema->name . $self->namesep . $table;
    }

    my $sth = $dbh->prepare("SELECT * FROM $table WHERE 1 = 0");
    $sth->execute;

    my $retval = \@{$sth->{NAME_lc}};
    $sth->finish;

    $retval;
}

sub _table_pk_info {
    my ($self, $table) = @_;

    my $dbh = $self->dbh;
    my $quoter = $self->quoter;

    my @primary = map { lc } $dbh->primary_key('', $self->schema->name, $table);
    s/\Q$quoter\E//g for @primary;

    my $sth = $dbh->primary_key_info('', $self->schema->name, $table);
    while ( my $info = $sth->fetchrow_hashref() ) {
#        my $column = SQL::Translator::Object::Column->new( { name => $info->{COLUMN_NAME}, size => undef, data_type => $info->{
    }

    return \@primary;
}

sub _table_fk_info {
    my ($self, $table) = @_;

    my $dbh = $self->dbh;
    my $quoter = $self->quoter;
    my $sth = $dbh->foreign_key_info( '', $self->schema, '',
                                      '', $self->schema, $table );
    return [] if !$sth;

    my %rels;

    my $i = 1; # for unnamed rels, which hopefully have only 1 column ...
    while(my $raw_rel = $sth->fetchrow_arrayref) {
        my $uk_tbl  = $raw_rel->[2];
        my $uk_col  = lc $raw_rel->[3];
        my $fk_col  = lc $raw_rel->[7];
        my $relid   = ($raw_rel->[11] || ( "__dcsld__" . $i++ ));
        $uk_tbl =~ s/\Q$quoter\E//g;
        $uk_col =~ s/\Q$quoter\E//g;
        $fk_col =~ s/\Q$quoter\E//g;
        $relid  =~ s/\Q$quoter\E//g;
        $rels{$relid}->{tbl} = $uk_tbl;
        $rels{$relid}->{cols}->{$uk_col} = $fk_col;
    }
    $sth->finish;

    my @rels;
    foreach my $relid (keys %rels) {
        push(@rels, {
            remote_columns => [ keys   %{$rels{$relid}->{cols}} ],
            local_columns  => [ values %{$rels{$relid}->{cols}} ],
            remote_table   => $rels{$relid}->{tbl},
        });
    }

    return \@rels;
}

sub _table_uniq_info {
    my ($self, $table) = @_;

    my $dbh = $self->dbh;
    if(!$dbh->can('statistics_info')) {
        warn "No UNIQUE constraint information can be gathered for this vendor";
        return [];
    }

    my %indices;
    my $sth = $dbh->statistics_info(undef, $self->schema->name, $table, 1, 1);
    while(my $row = $sth->fetchrow_hashref) {
        # skip table-level stats, conditional indexes, and any index missing
        #  critical fields
        next if $row->{TYPE} eq 'table'
            || defined $row->{FILTER_CONDITION}
            || !$row->{INDEX_NAME}
            || !defined $row->{ORDINAL_POSITION}
            || !$row->{COLUMN_NAME};

        $indices{$row->{INDEX_NAME}}->{$row->{ORDINAL_POSITION}} = $row->{COLUMN_NAME};
    }
    $sth->finish;

    my @retval;
    foreach my $index_name (keys %indices) {
        my $index = $indices{$index_name};
        push(@retval, [ $index_name => [
            map { $index->{$_} }
                sort keys %$index
        ]]);
    }

    return \@retval;
}

sub _columns_info_for {
    my ($self, $table) = @_;

    my $dbh = $self->dbh;

    if ($dbh->can('column_info')) {
        my %result;
        eval {
            my $sth = $dbh->column_info( undef, $self->schema->name, $table, '%' );
            while ( my $info = $sth->fetchrow_hashref() ) {
                my (%column_info, $col_name);
                $column_info{data_type}     = $info->{TYPE_NAME};
                $column_info{size}          = $info->{COLUMN_SIZE};
                $column_info{is_nullable}   = $info->{NULLABLE} ? 1 : 0;
                $column_info{default_value} = $info->{COLUMN_DEF};
                $column_info{index}         = $info->{ORDINAL_POSITION};
                $column_info{remarks}       = $info->{REMARKS};
                $col_name                   = $info->{COLUMN_NAME};
                $col_name =~ s/^\"(.*)\"$/$1/;
                $column_info{name} = $col_name;

                my $extra_info = $self->_extra_column_info($info) || {};
                my $column = SQL::Translator::Object::Column->new(%column_info);

#                $result{$col_name} = { %column_info, %$extra_info };
                $result{$col_name} = $column;
            }
            $sth->finish;
        };
      return \%result if !$@ && scalar keys %result;
      print "OH NOES, $@\n";
    }

    if($self->schema->name) {
        $table = $self->schema->name . $self->namesep . $table;
    }
    my %result;
    my $sth = $dbh->prepare("SELECT * FROM $table WHERE 1 = 0");
    $sth->execute;
    my @columns = @{$sth->{NAME_lc}};
    for my $i ( 0 .. $#columns ) {
        my %column_info;
        $column_info{data_type}   = $sth->{TYPE}->[$i];
        $column_info{size}        = $sth->{PRECISION}->[$i];
        $column_info{is_nullable} = $sth->{NULLABLE}->[$i] ? 1 : 0;
        $column_info{index} = $i;

        if ($column_info{data_type} =~ m/^(.*?)\((.*?)\)$/) {
            $column_info{data_type} = $1;
            $column_info{size}      = $2;
        }

        my $extra_info = $self->_extra_column_info($table, $columns[$i], $sth, $i) || {};

#        $result{$columns[$i]} = { %column_info, %$extra_info };
        $column_info{name} = $columns[$i];
        my $column = SQL::Translator::Object::Column->new(%column_info);
        $result{$columns[$i]} = $column;

    }
    $sth->finish;

    foreach my $col (keys %result) {
        my $colinfo = $result{$col};
        my $type_num = $colinfo->{data_type};
        my $type_name;
        if (defined $type_num && $dbh->can('type_info')) {
            my $type_info = $dbh->type_info($type_num);
            $type_name = $type_info->{TYPE_NAME} if $type_info;
            $colinfo->{data_type} = $type_name if $type_name;
        }
    }

    return \%result;
}

sub _extra_column_info { }

1;
