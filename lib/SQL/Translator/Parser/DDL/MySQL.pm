use MooseX::Declare;
role SQL::Translator::Parser::DDL::MySQL {
    use MooseX::Types::Moose qw(Str);
    use MooseX::MultiMethods;
    use SQL::Translator::Constants qw(:sqlt_types :sqlt_constants);
    use aliased 'SQL::Translator::Object::Column';
    use aliased 'SQL::Translator::Object::Constraint';
    use aliased 'SQL::Translator::Object::ForeignKey';
    use aliased 'SQL::Translator::Object::Index';
    use aliased 'SQL::Translator::Object::PrimaryKey';
    use aliased 'SQL::Translator::Object::Schema';
    use aliased 'SQL::Translator::Object::Table';

    around _build_data_type_mapping {
        my $data_type_mapping = $self->$orig;
        $data_type_mapping->{date} = SQL_DATE();

        return $data_type_mapping;
    }; 

    multi method parse(Schema $data) { $data }

    multi method parse(Str $data) {
        my $parser = Parse::RecDescent->new($self->grammar);

        unless (defined $parser) {
            return $self->error("Error instantiating Parse::RecDescent ".
                "instance: Bad grammar");
        }

#    my $parser_version = parse_mysql_version(
#        $translator->parser_args->{mysql_parser_version}, 'mysql'
#    ) || DEFAULT_PARSER_VERSION;
        my $parser_version = 30000;
    
        while ($data =~ s#/\*!(\d{5})?(.*?)\*/#($1 && $1 > $parser_version ? '' : $2)#es) { }

        my $result = $parser->startrule($data);
        die "Parse failed" unless defined $result;
    
        my $translator = $self->translator;
        my $schema = $translator->schema;
        $schema->name($result->{'database_name'}) if $result->{'database_name'};
    
        my @tables = sort { $result->{'tables'}{ $a }{'order'} <=> $result->{'tables'}{ $b }{'order'} } keys %{ $result->{'tables'} };
    
        for my $table_name ( @tables ) {
            my $tdata = $result->{tables}{ $table_name };
            my $table = Table->new({ name => $tdata->{table_name}, schema => $schema });
            $schema->add_table($table);
            $table->comments( join "\n", @{$tdata->{comments}} ) if $tdata->{comments};
    
            my @fields = sort { $tdata->{'fields'}->{$a}->{'order'} <=> $tdata->{'fields'}->{$b}->{'order'} } keys %{ $tdata->{'fields'} };
    
            for my $fname ( @fields ) {
                my $fdata = $tdata->{fields}{ $fname };
                my $field = Column->new({
                    name              => $fdata->{name},
                    data_type         => $fdata->{data_type},
                    sql_data_type     => $self->data_type_mapping->{$fdata->{data_type}} || -999999,
                    size              => $fdata->{size},
                    default_value     => $fdata->{default},
                    is_auto_increment => $fdata->{is_auto_inc},
                    is_nullable       => $fdata->{null},
                    is_primary_key    => $fdata->{is_primary_key} ? 1 : 0,
                    table             => $table,
                });
                $field->comments($fdata->{comments});
                $table->add_column($field);
    
                $table->primary_key( $field->name ) if $fdata->{'is_primary_key'};

                my %extra;
                for my $qual ( qw[ binary unsigned zerofill list collate ],
                        'character set', 'on update' ) {
                    if ( my $val = $fdata->{ $qual } || $fdata->{ uc $qual } ) {
                        next if ref $val eq 'ARRAY' && !@$val;
                        $extra{$qual} = $val;
                        #$field->extra( $qual, $val );
                    }
                }
                $field->extra(\%extra);

                if ( $fdata->{has_index} ) {
                    my $index = Index->new({ name => '', type => 'NORMAL', table => $table });
                    $index->add_column($table->get_column($fdata->{name}));
                    $table->add_index($index);
                }
    
                if ( $fdata->{is_unique} ) {
                    push @{ $tdata->{constraints} }, { name => '', type => 'UNIQUE', fields => [ $fdata->{name} ] };
                }
    
                for my $cdata ( @{ $fdata->{constraints} } ) {
                    next unless lc $cdata->{type} eq 'foreign_key';
                    $cdata->{fields} ||= [ $field->name ];
                    push @{ $tdata->{constraints} }, $cdata;
                }
            }
    
            for my $idata ( @{ $tdata->{indices} || [] } ) {
                my $index = Index->new({ name => $idata->{name} || '', type => uc($idata->{type}), table => $table });
                map { $index->add_column($table->get_column($_)) } @{$idata->{fields}};
                $table->add_index($index);
            }
            
    
#            if ( my @options = @{ $tdata->{'table_options'} || [] } ) {
#                my @cleaned_options;
#                my @ignore_opts = $self->parser_args->{'ignore_opts'}
#                    ? split( /,/, $self->parser_args->{'ignore_opts'} )
#                    : ();
#                if (@ignore_opts) {
#                    my $ignores = { map { $_ => 1 } @ignore_opts };
#                    foreach my $option (@options) {
#                        # make sure the option isn't in ignore list
#                        my ($option_key) = keys %$option;
#                        if ( !exists $ignores->{$option_key} ) {
#                            push @cleaned_options, $option;
#                        }
#                    }
#                } else {
#                    @cleaned_options = @options;
#                }
#                $table->options( \@cleaned_options ) or die $table->error;
#            }
    
            for my $cdata ( @{ $tdata->{constraints} || [] } ) {
                my $constraint;
                if (uc $cdata->{type} eq 'PRIMARY_KEY') {
                    $constraint = PrimaryKey->new({ name => $cdata->{name} || '', table => $table });
                    $table->get_column($_)->is_primary_key(1) for @{$cdata->{fields}};
                } elsif (uc $cdata->{type} eq 'FOREIGN_KEY') {
                    $constraint = ForeignKey->new({ name => $cdata->{name} || '',
                                                    table => $table,
                                                    reference_table => $cdata->{reference_table},
                                                    reference_columns => $cdata->{reference_fields},
                                                    on_delete => $cdata->{on_delete} || $cdata->{on_delete_do},
                                                    on_update => $cdata->{on_update} || $cdata->{on_update_do} });
                    $table->get_column($_)->is_foreign_key(1) for @{$cdata->{fields}};
                    $table->get_column($_)->foreign_key_reference($constraint) for @{$cdata->{fields}};
                } else {
                    $constraint = Constraint->new({ name => $cdata->{name} || '', type => uc $cdata->{type}, table => $table });
                }
                $constraint->add_column($table->get_column($_)) for @{$cdata->{fields}};
                $table->add_constraint($constraint);
            }
    
            # After the constrains and PK/idxs have been created, 
            # we normalize fields
            normalize_field($_) for $table->get_fields;
        }
        
        for my $proc_name ( keys %{ $result->{procedures} } ) {
            my $procedure = Procedure->new({ name  => $proc_name,
                                             owner => $result->{procedures}->{$proc_name}->{owner},
                                             sql   => $result->{procedures}->{$proc_name}->{sql}
            });
            $schema->add_procedure($procedure);
        }
    
        for my $view_name ( keys %{ $result->{'views'} } ) {
            my $view = View->new({ 
                name => $view_name,
                sql  => $result->{'views'}->{$view_name}->{sql},
            });
            $schema->add_view($view);
        }
        return 1;
    }
    
    # Takes a field, and returns 
    method normalize_field {
        my ($size, $type, $list, $changed); # = @_;
      
        $size = $self->size || 0;
        $type = $self->data_type;
        $list = $self->extra->{list} || [];

        if ( !ref $size && $size == 0 ) {
            if ( lc $type eq 'tinyint' ) {
                $changed = $size != 4;
                $size = 4;
            }
            elsif ( lc $type eq 'smallint' ) {
                $changed = $size != 6;
                $size = 6;
            }
            elsif ( lc $type eq 'mediumint' ) {
                $changed = $size != 9;
                $size = 9;
            }
            elsif ( $type =~ /^int(eger)?$/i ) {
                $changed = $size != 11 || $type ne 'int';
                $type = 'int';
                $size = 11;
            }
            elsif ( lc $type eq 'bigint' ) {
                $changed = $size != 20;
                $size = 20;
            }
            elsif ( lc $type =~ /(float|double|decimal|numeric|real|fixed|dec)/ ) {
                my $old_size = (ref $size || '') eq 'ARRAY' ? $size : [];
                $changed     = @$old_size != 2 
                            || $old_size->[0] != 8 
                            || $old_size->[1] != 2;
                $size        = [8,2];
            }
        }
    
        if ( $type =~ /^tiny(text|blob)$/i ) {
            $changed = $size != 255;
            $size = 255;
        }
        elsif ( $type =~ /^(blob|text)$/i ) {
            $changed = $size != 65_535;
            $size = 65_535;
        }
        elsif ( $type =~ /^medium(blob|text)$/i ) {
            $changed = $size != 16_777_215;
            $size = 16_777_215;
        }
        elsif ( $type =~ /^long(blob|text)$/i ) {
            $changed = $size != 4_294_967_295;
            $size = 4_294_967_295;
        }
    
        if ( $type =~ /(set|enum)/i && !$size ) {
            my %extra = $self->extra;
            my $longest = 0;
            for my $len ( map { length } @{ $extra{'list'} || [] } ) {
                $longest = $len if $len > $longest;
            }
            $changed = 1;
            $size = $longest if $longest;
        }
    
#        if ( $changed ) {
            # We only want to clone the field, not *everything*
#            {
#                local $field->{table} = undef;
#                $field->parsed_field( dclone( $field ) );
#                $field->parsed_field->{table} = $field->table;
#            }
            $self->size( $size );
            $self->data_type( $type );
#            $column->sql_data_type( $self->data_type_mapping->{$type} || -99999 );
            $self->extra->{list} = $list if @$list;
#        }
        return 1;
    }
}
