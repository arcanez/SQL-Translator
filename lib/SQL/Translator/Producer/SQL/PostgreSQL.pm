use MooseX::Declare;
role  SQL::Translator::Producer::SQL::PostgreSQL {
    use SQL::Translator::Constants qw(:sqlt_types :sqlt_constants);
    use SQL::Translator::Types qw(Column Constraint Index Table View);
my ( %index_name );
my $max_id_length;

#BEGIN {

my %translate  = (
    #
    # MySQL types
    #
    bigint     => 'bigint',
    double     => 'numeric',
    decimal    => 'numeric',
    float      => 'numeric',
    int        => 'integer',
    mediumint  => 'integer',
    smallint   => 'smallint',
    tinyint    => 'smallint',
    char       => 'character',
    varchar    => 'character varying',
    longtext   => 'text',
    mediumtext => 'text',
    text       => 'text',
    tinytext   => 'text',
    tinyblob   => 'bytea',
    blob       => 'bytea',
    mediumblob => 'bytea',
    longblob   => 'bytea',
    enum       => 'character varying',
    set        => 'character varying',
    date       => 'date',
    datetime   => 'timestamp',
    time       => 'time',
    timestamp  => 'timestamp',
    year       => 'date',

    #
    # Oracle types
    #
    number     => 'integer',
    char       => 'character',
    varchar2   => 'character varying',
    long       => 'text',
    CLOB       => 'bytea',
    date       => 'date',

    #
    # Sybase types
    #
    int        => 'integer',
    money      => 'money',
    varchar    => 'character varying',
    datetime   => 'timestamp',
    text       => 'text',
    real       => 'numeric',
    comment    => 'text',
    bit        => 'bit',
    tinyint    => 'smallint',
    float      => 'numeric',
);

 $max_id_length = 62;
#}
my %reserved = map { $_, 1 } qw[
    ALL ANALYSE ANALYZE AND ANY AS ASC 
    BETWEEN BINARY BOTH
    CASE CAST CHECK COLLATE COLUMN CONSTRAINT CROSS
    CURRENT_DATE CURRENT_TIME CURRENT_TIMESTAMP CURRENT_USER 
    DEFAULT DEFERRABLE DESC DISTINCT DO
    ELSE END EXCEPT
    FALSE FOR FOREIGN FREEZE FROM FULL 
    GROUP HAVING 
    ILIKE IN INITIALLY INNER INTERSECT INTO IS ISNULL 
    JOIN LEADING LEFT LIKE LIMIT 
    NATURAL NEW NOT NOTNULL NULL
    OFF OFFSET OLD ON ONLY OR ORDER OUTER OVERLAPS
    PRIMARY PUBLIC REFERENCES RIGHT 
    SELECT SESSION_USER SOME TABLE THEN TO TRAILING TRUE 
    UNION UNIQUE USER USING VERBOSE WHEN WHERE
];

# my $max_id_length    = 62;
my %used_names;
my %used_identifiers = ();
my %global_names;
my %unreserve;
my %truncated;

# -------------------------------------------------------------------
method produce {
    my $translator = $self->translator;
#    local $DEBUG         = $translator->debug;
#    local $WARN          = $translator->show_warnings;
    my $no_comments      = $translator->no_comments;
    my $add_drop_table   = $translator->add_drop_table;
    my $schema           = $translator->schema;
    my $pargs            = $translator->producer_args;
    my $postgres_version = $pargs->{postgres_version} || 0;

    my $qt = $translator->quote_table_names ? q{"} : q{};
    my $qf = $translator->quote_field_names ? q{"} : q{};
    
    my @output;
    push @output, $self->header_comment unless ($no_comments);

    my (@table_defs, @fks);
    for my $table ( $schema->get_tables ) {

        my ($table_def, $fks) = $self->create_table($table, { 
            quote_table_names => $qt,
            quote_field_names => $qf,
            no_comments       => $no_comments,
            postgres_version  => $postgres_version,
            add_drop_table    => $add_drop_table,
        });

        push @table_defs, $table_def;
        push @fks, @$fks;
    }

    for my $view ( $schema->get_views ) {
      push @table_defs, $self->create_view($view, {
        add_drop_view     => $add_drop_table,
        quote_table_names => $qt,
        quote_field_names => $qf,
        no_comments       => $no_comments,
      });
    }

    push @output, map { "$_;\n\n" } @table_defs;
    if ( @fks ) {
        push @output, "--\n-- Foreign Key Definitions\n--\n\n" unless $no_comments;
        push @output, map { "$_;\n\n" } @fks;
    }

#    if ( $WARN ) {
#        if ( %truncated ) {
#            warn "Truncated " . keys( %truncated ) . " names:\n";
#            warn "\t" . join( "\n\t", sort keys %truncated ) . "\n";
#        }

#        if ( %unreserve ) {
#            warn "Encounted " . keys( %unreserve ) .
#                " unsafe names in schema (reserved or invalid):\n";
#            warn "\t" . join( "\n\t", sort keys %unreserve ) . "\n";
#        }
#    }

    return wantarray
        ? @output
        : join ('', @output);
}

# -------------------------------------------------------------------
method mk_name($basename = '', $type = '', $scope = '', $critical = '') {
    my $basename_orig = $basename;
#    my $max_id_length = 62;
    my $max_name      = $type 
                        ? $max_id_length - (length($type) + 1) 
                        : $max_id_length;
    $basename         = substr( $basename, 0, $max_name ) 
                        if length( $basename ) > $max_name;
    my $name          = $type ? "${type}_$basename" : $basename;

    if ( $basename ne $basename_orig and $critical ) {
        my $show_type = $type ? "+'$type'" : "";
#        warn "Truncating '$basename_orig'$show_type to $max_id_length ",
#            "character limit to make '$name'\n" if $WARN;
        $truncated{ $basename_orig } = $name;
    }

    $scope ||= \%global_names;
    if ( my $prev = $scope->{ $name } ) {
        my $name_orig = $name;
        $name        .= sprintf( "%02d", ++$prev );
        substr($name, $max_id_length - 3) = "00" 
            if length( $name ) > $max_id_length;

#        warn "The name '$name_orig' has been changed to ",
#             "'$name' to make it unique.\n" if $WARN;

        $scope->{ $name_orig }++;
    }

    $scope->{ $name }++;
    return $name;
}

# -------------------------------------------------------------------
method unreserve($name = '', $schema_obj_name = '') {
    my ( $suffix ) = ( $name =~ s/(\W.*)$// ) ? $1 : '';

    # also trap fields that don't begin with a letter
    return $name if (!$reserved{ uc $name }) && $name =~ /^[a-z]/i; 

    if ( $schema_obj_name ) {
        ++$unreserve{"$schema_obj_name.$name"};
    }
    else {
        ++$unreserve{"$name (table name)"};
    }

    my $unreserve = sprintf '%s_', $name;
    return $unreserve.$suffix;
}

# -------------------------------------------------------------------
method next_unused_name($orig_name?) {
    return unless $orig_name;
    my $name      = $orig_name;

    my $suffix_gen = sub {
        my $suffix = 0;
        return ++$suffix ? '' : $suffix;
    };

    for (;;) {
        $name = $orig_name . $suffix_gen->();
        last if $used_names{ $name }++;
    }

    return $name;
}

method create_table(Table $table, $options?) {
    my $qt = $options->{quote_table_names} || '';
    my $qf = $options->{quote_field_names} || '';
    my $no_comments = $options->{no_comments} || 0;
    my $add_drop_table = $options->{add_drop_table} || 0;
    my $postgres_version = $options->{postgres_version} || 0;

    my $table_name = $table->name or next;
    my ( $fql_tbl_name ) = ( $table_name =~ s/\W(.*)$// ) ? $1 : q{};
    my $table_name_ur = $qt ? $table_name
        : $fql_tbl_name ? join('.', $table_name, $self->unreserve($fql_tbl_name))
        : $self->unreserve($table_name);
    $table->name($table_name_ur);

# print STDERR "$table_name table_name\n";
    my ( @comments, @field_defs, @sequence_defs, @constraint_defs, @type_defs, @type_drops, @fks );

    push @comments, "--\n-- Table: $table_name_ur\n--\n" unless $no_comments;

    if ( $table->comments and !$no_comments ){
        my $c = "-- Comments: \n-- ";
        $c .= join "\n-- ", $table->comments;
        $c .= "\n--\n";
        push @comments, $c;
    }

    #
    # Fields
    #
    my %field_name_scope;
    for my $field ( $table->get_fields ) {
        push @field_defs, $self->create_field($field, { quote_table_names => $qt,
                                                 quote_field_names => $qf,
                                                 table_name => $table_name_ur,
                                                 postgres_version => $postgres_version,
                                                 type_defs => \@type_defs,
                                                 type_drops => \@type_drops,
                                                 constraint_defs => \@constraint_defs,});
    }

    #
    # Index Declarations
    #
    my @index_defs = ();
 #   my $idx_name_default;
    for my $index ( $table->get_indices ) {
        my ($idef, $constraints) = $self->create_index($index,
                                              { 
                                                  quote_field_names => $qf,
                                                  quote_table_names => $qt,
                                                  table_name => $table_name,
                                              });
        $idef and push @index_defs, $idef;
        push @constraint_defs, @$constraints;
    }

    #
    # Table constraints
    #
    my $c_name_default;
    for my $c ( $table->get_constraints ) {
        my ($cdefs, $fks) = $self->create_constraint($c, 
                                              { 
                                                  quote_field_names => $qf,
                                                  quote_table_names => $qt,
                                                  table_name => $table_name,
                                              });
        push @constraint_defs, @$cdefs;
        push @fks, @$fks;
    }

    my $temporary = "";

    if(exists $table->{extra}{temporary}) {
        $temporary = $table->{extra}{temporary} ? "TEMPORARY " : "";
    } 

    my $create_statement;
    $create_statement = join("\n", @comments);
    if ($add_drop_table) {
        if ($postgres_version >= 8.2) {
            $create_statement .= qq[DROP TABLE IF EXISTS $qt$table_name_ur$qt CASCADE;\n];
            $create_statement .= join (";\n", @type_drops) . ";\n"
                if $postgres_version >= 8.3 && scalar @type_drops;
        } else {
            $create_statement .= qq[DROP TABLE $qt$table_name_ur$qt CASCADE;\n];
        }
    }
    $create_statement .= join(";\n", @type_defs) . ";\n"
        if $postgres_version >= 8.3 && scalar @type_defs;
    $create_statement .= qq[CREATE ${temporary}TABLE $qt$table_name_ur$qt (\n].
                            join( ",\n", map { "  $_" } @field_defs, @constraint_defs ) .
                            "\n)" ;

    $create_statement .= @index_defs ? ';' : q{};
    $create_statement .= ( $create_statement =~ /;$/ ? "\n" : q{} )
        . join(";\n", @index_defs);

    return $create_statement, \@fks;
}

method create_view(View $view, $options?) {
    my $qt = $options->{quote_table_names} || '';
    my $qf = $options->{quote_field_names} || '';
    my $add_drop_view = $options->{add_drop_view};

    my $view_name = $view->name;
#    debug("PKG: Looking at view '${view_name}'\n");

    my $create = '';
    $create .= "--\n-- View: ${qt}${view_name}${qt}\n--\n"
        unless $options->{no_comments};
    $create .= "DROP VIEW ${qt}${view_name}${qt};\n" if $add_drop_view;
    $create .= 'CREATE';

    my $extra = $view->extra;
    $create .= " TEMPORARY" if exists($extra->{temporary}) && $extra->{temporary};
    $create .= " VIEW ${qt}${view_name}${qt}";

    if ( my @fields = $view->fields ) {
        my $field_list = join ', ', map { "${qf}${_}${qf}" } @fields;
        $create .= " ( ${field_list} )";
    }

    if ( my $sql = $view->sql ) {
        $create .= " AS\n    ${sql}\n";
    }

    if ( $extra->{check_option} ) {
        $create .= ' WITH ' . uc $extra->{check_option} . ' CHECK OPTION';
    }

    return $create;
}

{ 

    my %field_name_scope;

    method create_field(Column $field, $options?) {
        my $qt = $options->{quote_table_names} || '';
        my $qf = $options->{quote_field_names} || '';
        my $table_name = $field->table->name;
        my $constraint_defs = $options->{constraint_defs} || [];
        my $postgres_version = $options->{postgres_version} || 0;
        my $type_defs = $options->{type_defs} || [];
        my $type_drops = $options->{type_drops} || [];

        $field_name_scope{$table_name} ||= {};
        my $field_name    = $field->name;
        my $field_name_ur = $qf ? $field_name : $self->unreserve($field_name, $table_name );
        $field->name($field_name_ur);
        my $field_comments = $field->comments 
            ? "-- " . $field->comments . "\n  " 
            : '';

        my $field_def     = $field_comments.qq[$qf$field_name_ur$qf];

        #
        # Datatype
        #
        my @size      = $field->size;
        my $data_type = lc $field->data_type;
        my %extra     = $field->extra;
        my $list      = $extra{'list'} || [];
        # todo deal with embedded quotes
        my $commalist = join( ', ', map { qq['$_'] } @$list );

        if ($postgres_version >= 8.3 && $field->data_type eq 'enum') {
            my $type_name = $field->table->name . '_' . $field->name . '_type';
            $field_def .= ' '. $type_name;
            push @$type_defs, "CREATE TYPE $type_name AS ENUM ($commalist)";
            push @$type_drops, "DROP TYPE IF EXISTS $type_name";
        } else {
            $field_def .= ' '. $self->convert_datatype($field);
        }

        #
        # Default value 
        #
        my $default = $field->default_value;
=cut
        if ( defined $default ) {
            SQL::Translator::Producer->_apply_default_value(
              \$field_def,
              $default,
              [
                'NULL'              => \'NULL',
                'now()'             => 'now()',
                'CURRENT_TIMESTAMP' => 'CURRENT_TIMESTAMP',
              ],
            );
        }
=cut

        #
        # Not null constraint
        #
        $field_def .= ' NOT NULL' unless $field->is_nullable;

        return $field_def;
    }
}

method create_index(Index $index, $options?) {
    my $qt = $options->{quote_table_names} ||'';
    my $qf = $options->{quote_field_names} ||'';
    my $table_name = $index->table->name;
#        my $table_name_ur = $qt ? $self->unreserve($table_name) : $table_name;

    my ($index_def, @constraint_defs);

    my $name = $self->next_unused_name(
        $index->name 
        || join('_', $table_name, 'idx', ++$index_name{ $table_name })
    );

    my $type = $index->type || NORMAL;
    my @fields     = 
        map { $_ =~ s/\(.+\)//; $_ }
    map { $qt ? $_ : $self->unreserve($_, $table_name ) }
    $index->fields;
    return ('', []) unless @fields;

    my $def_start = qq[CONSTRAINT "$name" ];
    if ( $type eq PRIMARY_KEY ) {
        push @constraint_defs, "${def_start}PRIMARY KEY ".
            '(' .$qf . join( $qf. ', '.$qf, @fields ) . $qf . ')';
    }
    elsif ( $type eq UNIQUE ) {
        push @constraint_defs, "${def_start}UNIQUE " .
            '(' . $qf . join( $qf. ', '.$qf, @fields ) . $qf.')';
    }
    elsif ( $type eq NORMAL ) {
        $index_def = 
            "CREATE INDEX ${qf}${name}${qf} on ${qt}${table_name}${qt} (".
            join( ', ', map { qq[$qf$_$qf] } @fields ).  
            ')'
            ; 
    }
    else {
#        warn "Unknown index type ($type) on table $table_name.\n"
#            if $WARN;
    }

    return $index_def, \@constraint_defs;
}

method create_constraint(Constraint $c, $options?) {
    my $qf = $options->{quote_field_names} ||'';
    my $qt = $options->{quote_table_names} ||'';
    my $table_name = $c->table->name;
    my (@constraint_defs, @fks);

    my $name = $c->name || '';
    if ( $name ) {
        $name = $self->next_unused_name($name);
    }

    my @fields     = 
        map { $_ =~ s/\(.+\)//; $_ }
    map { $qt ? $_ : $self->unreserve( $_, $table_name )}
    $c->fields;
    my @rfields     = 
        map { $_ =~ s/\(.+\)//; $_ }
    map { $qt ? $_ : $self->unreserve( $_, $table_name )}
    $c->reference_fields;
    return ([], []) if !@fields && $c->type ne CHECK_C;

    my $def_start = $name ? qq[CONSTRAINT "$name" ] : '';
    if ( $c->type eq PRIMARY_KEY ) {
        push @constraint_defs, "${def_start}PRIMARY KEY ".
            '('.$qf . join( $qf.', '.$qf, @fields ) . $qf.')';
    }
    elsif ( $c->type eq UNIQUE ) {
        $name = $self->next_unused_name($name);
        push @constraint_defs, "${def_start}UNIQUE " .
            '('.$qf . join( $qf.', '.$qf, @fields ) . $qf.')';
    }
    elsif ( $c->type eq CHECK_C ) {
        my $expression = $c->expression;
        push @constraint_defs, "${def_start}CHECK ($expression)";
    }
    elsif ( $c->type eq FOREIGN_KEY ) {
        my $def .= "ALTER TABLE ${qt}${table_name}${qt} ADD FOREIGN KEY (" . 
            join( ', ', map { qq[$qf$_$qf] } @fields ) . ')' .
            "\n  REFERENCES " . $qt . $c->reference_table . $qt;

        if ( @rfields ) {
            $def .= ' ('.$qf . join( $qf.', '.$qf, @rfields ) . $qf.')';
        }

        if ( $c->match_type ) {
            $def .= ' MATCH ' . ( $c->match_type =~ /full/i ) ? 'FULL' : 'PARTIAL';
        }

=cut
        if ( $c->on_delete ) {
            $def .= ' ON DELETE '.join( ' ', $c->on_delete );
        }

        if ( $c->on_update ) {
            $def .= ' ON UPDATE '.join( ' ', $c->on_update );
        }
=cut
        if ( $c->deferrable ) {
            $def .= ' DEFERRABLE';
        }

        push @fks, "$def";
    }

    return \@constraint_defs, \@fks;
}

method convert_datatype(Column $field) {
    my @size      = $field->size;
    my $data_type = lc $field->data_type;

    if ( $data_type eq 'enum' ) {
#        my $len = 0;
#        $len = ($len < length($_)) ? length($_) : $len for (@$list);
#        my $chk_name = mk_name( $table_name.'_'.$field_name, 'chk' );
#        push @$constraint_defs, 
#        qq[CONSTRAINT "$chk_name" CHECK ($qf$field_name$qf ].
#           qq[IN ($commalist))];
        $data_type = 'character varying';
    }
    elsif ( $data_type eq 'set' ) {
        $data_type = 'character varying';
    }
    elsif ( $field->is_auto_increment ) {
        if ( defined $size[0] && $size[0] > 11 ) {
            $data_type = 'bigserial';
        }
        else {
            $data_type = 'serial';
        }
        undef @size;
    }
    else {
        $data_type  = defined $translate{ $data_type } ?
            $translate{ $data_type } :
            $data_type;
    }

    if ( $data_type =~ /^time/i || $data_type =~ /^interval/i ) {
        if ( defined $size[0] && $size[0] > 6 ) {
            $size[0] = 6;
        }
    }

    if ( $data_type eq 'integer' ) {
        if ( defined $size[0] && $size[0] > 0) {
            if ( $size[0] > 10 ) {
                $data_type = 'bigint';
            }
            elsif ( $size[0] < 5 ) {
                $data_type = 'smallint';
            }
            else {
                $data_type = 'integer';
            }
        }
        else {
            $data_type = 'integer';
        }
    }

    my $type_with_size = join('|',
        'bit', 'varbit', 'character', 'bit varying', 'character varying',
        'time', 'timestamp', 'interval'
    );

    if ( $data_type !~ /$type_with_size/ ) {
        @size = (); 
    }

    if (defined $size[0] && $size[0] > 0 && $data_type =~ /^time/i ) {
        $data_type =~ s/^(time.*?)( with.*)?$/$1($size[0])/;
        $data_type .= $2 if(defined $2);
    } elsif ( defined $size[0] && $size[0] > 0 ) {
        $data_type .= '(' . join( ',', @size ) . ')';
    }

    return $data_type;
}


method alter_field(Column $from_field, Column $to_field) {
    die "Can't alter field in another table" 
        if($from_field->table->name ne $to_field->table->name);

    my @out;
    push @out, sprintf('ALTER TABLE %s ALTER COLUMN %s SET NOT NULL',
                       $to_field->table->name,
                       $to_field->name) if(!$to_field->is_nullable and
                                           $from_field->is_nullable);

    push @out, sprintf('ALTER TABLE %s ALTER COLUMN %s DROP NOT NULL',
                      $to_field->table->name,
                      $to_field->name)
       if ( !$from_field->is_nullable and $to_field->is_nullable );


    my $from_dt = $self->convert_datatype($from_field);
    my $to_dt   = $self->convert_datatype($to_field);
    push @out, sprintf('ALTER TABLE %s ALTER COLUMN %s TYPE %s',
                       $to_field->table->name,
                       $to_field->name,
                       $to_dt) if($to_dt ne $from_dt);

    push @out, sprintf('ALTER TABLE %s RENAME COLUMN %s TO %s',
                       $to_field->table->name,
                       $from_field->name,
                       $to_field->name) if($from_field->name ne $to_field->name);

    my $old_default = $from_field->default_value;
    my $new_default = $to_field->default_value;
    my $default_value = $to_field->default_value;
    
    # fixes bug where output like this was created:
    # ALTER TABLE users ALTER COLUMN column SET DEFAULT ThisIsUnescaped;
    if(ref $default_value eq "SCALAR" ) {
        $default_value = $$default_value;
    } elsif( defined $default_value && $to_dt =~ /^(character|text)/xsmi ) {
        $default_value =~ s/'/''/xsmg;
        $default_value = q(') . $default_value . q(');
    }
    
    push @out, sprintf('ALTER TABLE %s ALTER COLUMN %s SET DEFAULT %s',
                       $to_field->table->name,
                       $to_field->name,
                       $default_value)
        if ( defined $new_default &&
             (!defined $old_default || $old_default ne $new_default) );

     # fixes bug where removing the DEFAULT statement of a column
     # would result in no change
    
     push @out, sprintf('ALTER TABLE %s ALTER COLUMN %s DROP DEFAULT',
                       $to_field->table->name,
                       $to_field->name)
        if ( !defined $new_default && defined $old_default );
    

    return wantarray ? @out : join("\n", @out);
}

method rename_field(@args) { $self->alter_field(@args) }

method add_field(Column $new_field) {
    my $out = sprintf('ALTER TABLE %s ADD COLUMN %s',
                      $new_field->table->name,
                      $self->create_field($new_field));
    return $out;

}

method drop_field(Column $old_field) {
    my $out = sprintf('ALTER TABLE %s DROP COLUMN %s',
                      $old_field->table->name,
                      $old_field->name);

    return $out;    
}

method alter_table(Column $to_table, $options?) {
    my $qt = $options->{quote_table_names} || '';
    my $out = sprintf('ALTER TABLE %s %s',
                      $qt . $to_table->name . $qt,
                      $options->{alter_table_action});
    return $out;
}

method rename_table(Table $old_table, Table $new_table, $options?) {
    my $qt = $options->{quote_table_names} || '';
    $options->{alter_table_action} = "RENAME TO $qt$new_table$qt";
    return alter_table($old_table, $options);
}

method alter_create_index(Index $index, $options?) {
    my $qt = $options->{quote_table_names} || '';
    my $qf = $options->{quote_field_names} || '';
    my ($idef, $constraints) = create_index($index, {
        quote_field_names => $qf,
        quote_table_names => $qt,
        table_name => $index->table->name,
    });
    return $index->type eq NORMAL ? $idef
        : sprintf('ALTER TABLE %s ADD %s',
              $qt . $index->table->name . $qt,
              join(q{}, @$constraints)
          );
}

method alter_drop_index(Index $index, $options?) {
    my $index_name = $index->name;
    return "DROP INDEX $index_name";
}

method alter_drop_constraint(Constraint $c, $options?) {
    my $qt = $options->{quote_table_names} || '';
    my $qc = $options->{quote_field_names} || '';
    my $out = sprintf('ALTER TABLE %s DROP CONSTRAINT %s',
                      $qt . $c->table->name . $qt,
                      $qc . $c->name . $qc );
    return $out;
}

method alter_create_constraint(Index $index, $options?) {
    my $qt = $options->{quote_table_names} || '';
    my ($defs, $fks) = create_constraint(@_);
    
    # return if there are no constraint definitions so we don't run
    # into output like this:
    # ALTER TABLE users ADD ;
        
    return unless(@{$defs} || @{$fks});
    return $index->type eq FOREIGN_KEY ? join(q{}, @{$fks})
        : join( ' ', 'ALTER TABLE', $qt.$index->table->name.$qt,
              'ADD', join(q{}, @{$defs}, @{$fks})
          );
}

method drop_table(Str $table, $options?) {
    my $qt = $options->{quote_table_names} || '';
    return "DROP TABLE $qt$table$qt CASCADE";
}

    method header_comment($producer?, $comment_char?) {
        $producer ||= caller;
        my $now = scalar localtime;
        my $DEFAULT_COMMENT = '-- ';

        $comment_char = $DEFAULT_COMMENT
            unless defined $comment_char;

        my $header_comment =<<"HEADER_COMMENT";
            ${comment_char}
            ${comment_char}Created by $producer
            ${comment_char}Created on $now
            ${comment_char}
HEADER_COMMENT

        # Any additional stuff passed in
        for my $additional_comment (@_) {
            $header_comment .= "${comment_char}${additional_comment}\n";
        }

        return $header_comment;
    }
}
