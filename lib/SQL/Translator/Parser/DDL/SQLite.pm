use MooseX::Declare;
role SQL::Translator::Parser::DDL::SQLite {
    use MooseX::Types::Moose qw(Str);
    use MooseX::MultiMethods;
    use SQL::Translator::Constants qw(:sqlt_types :sqlt_constants);
    use SQL::Translator::Types qw(Schema);
    use aliased 'SQL::Translator::Object::Column';
    use aliased 'SQL::Translator::Object::Constraint';
    use aliased 'SQL::Translator::Object::ForeignKey';
    use aliased 'SQL::Translator::Object::Index';
    use aliased 'SQL::Translator::Object::PrimaryKey';
    use aliased 'SQL::Translator::Object::Table';
    use aliased 'SQL::Translator::Object::Trigger';
    use aliased 'SQL::Translator::Object::View';

    around _build_data_type_mapping {
        my $data_type_mapping = $self->$orig;
        $data_type_mapping->{date} = SQL_DATE();

        return $data_type_mapping;
    };

    multi method parse(Schema $data) { $data }

    multi method parse(Str $data) {
        my $translator = $self->translator;
        my $parser = Parse::RecDescent->new($self->grammar);
    
        unless (defined $parser) {
            return $translator->error("Error instantiating Parse::RecDescent ".
                "instance: Bad grammar");
        }
    
        my $result = $parser->startrule($data);
        die "Parse failed" unless defined $result;
    
        my $schema = $translator->schema;
        my @tables = 
            map   { $_->[1] }
            sort  { $a->[0] <=> $b->[0] }
            map   { [ $result->{'tables'}{ $_ }->{'order'}, $_ ] }
            keys %{ $result->{'tables'} };
    
        for my $table_name ( @tables ) {
            my $tdata =  $result->{'tables'}{ $table_name };
            my $table = Table->new({ name  => $tdata->{'name'}, schema => $schema });
            $table->comments( $tdata->{'comments'} );
            $schema->add_table($table);
    
            for my $fdata ( @{ $tdata->{'fields'} } ) {
                my $field = Column->new({
                    name              => $fdata->{'name'},
                    data_type         => $fdata->{'data_type'},
                    sql_data_type     => $self->data_type_mapping->{$fdata->{data_type}} || -999999,
                    size              => $fdata->{'size'},
                    default_value     => $fdata->{'default'},
                    is_auto_increment => $fdata->{'is_auto_inc'},
                    is_nullable       => $fdata->{'is_nullable'},
                    comments          => $fdata->{'comments'},
                    table             => $table,
                });
                $table->add_column($field);
    
                $table->primary_key( $field->name ) if $fdata->{'is_primary_key'};
    
                for my $cdata ( @{ $fdata->{'constraints'} } ) {
                    next unless $cdata->{'type'} eq 'foreign_key';
                    $cdata->{'fields'} ||= [ $field->name ];
                    push @{ $tdata->{'constraints'} }, $cdata;
                }
            }
    
            for my $idata ( @{ $tdata->{'indices'} || [] } ) {
                my @columns = delete $idata->{fields};
                my $index = Index->new({
                    name    => $idata->{'name'},
                    type    => uc $idata->{'type'},
                    table   => $table,
                });
                $index->add_column($table->get_column(@$_[0])) for @columns;
                $table->add_index($index);
            }
    
            for my $cdata ( @{ $tdata->{'constraints'} || [] } ) {
                my $constraint;
                if (uc $cdata->{type} eq 'PRIMARY_KEY') {
                    $constraint = PrimaryKey->new({ name => $cdata->{name} || 'primary_key', table => $table });
                    $constraint->add_column($table->get_column($_)) for @{$cdata->{fields}};
                $table->get_column($_)->is_primary_key(1) for @{$cdata->{fields}};
                } elsif (uc $cdata->{type} eq 'FOREIGN_KEY') {
                    $constraint = ForeignKey->new({ name => $cdata->{name} || 'foreign_key',
                                                    table => $table,
                                                    reference_table => $cdata->{reference_table},
                                                    reference_columns => ref $cdata->{reference_fields} ? $cdata->{reference_fields} : [ $cdata->{reference_fields} ],
                                                    on_delete => $cdata->{on_delete} || $cdata->{on_delete_do},
                                                    on_update => $cdata->{on_update} || $cdata->{on_update_do} });
                    $table->get_column($_)->is_foreign_key(1) for @{$cdata->{fields}};
                    $table->get_column($_)->foreign_key_reference($constraint) for @{$cdata->{fields}};
                } else {
                    $constraint = Constraint->new({ name => $cdata->{name} || 'constraint', type => uc $cdata->{type}, table => $table });
                    $constraint->add_column($table->get_column($_)) for @{$cdata->{fields}};
                }
                $table->add_constraint($constraint);
            }
        }
    
        for my $def ( @{ $result->{'views'} || [] } ) {
            my $view = View->new({
                name  => $def->{'name'},
                sql   => $def->{'sql'},
            });
            $schema->add_view($view);
        }
    
        for my $def ( @{ $result->{'triggers'} || [] } ) {
            my $trigger = Trigger->new({
                name                => $def->{'name'},
                perform_action_when => $def->{'when'},
                database_events     => $def->{'db_events'},
                action              => $def->{'action'},
                on_table            => $def->{'on_table'},
            });
            $schema->add_trigger($trigger);
        }
        return 1;
    }
}
