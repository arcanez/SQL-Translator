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
#    use aliased 'SQL::Translator::Object::Schema';
    use aliased 'SQL::Translator::Object::Table';

    around _build_data_type_mapping {
        my $data_type_mapping = $self->$orig;
        $data_type_mapping->{date} = SQL_DATE();

        return $data_type_mapping;
    };

    multi method parse(Schema $data) { $data }

    multi method parse(Str $data) {
#        my ( $translator, $data ) = @_;
        my $translator = $self->translator;
#        my $parser = Parse::RecDescent->new($GRAMMAR);
        my $parser = Parse::RecDescent->new($self->grammar);
    
#        local $::RD_TRACE  = $translator->trace ? 1 : undef;
#        local $DEBUG       = $translator->debug;
        local $::RD_TRACE  = undef; #$self->trace ? 1 : undef;
    
        unless (defined $parser) {
            return $translator->error("Error instantiating Parse::RecDescent ".
                "instance: Bad grammer");
        }
    
        my $result = $parser->startrule($data);
        die "Parse failed" unless defined $result;
#        return $translator->error( "Parse failed." ) unless defined $result;
#        warn Dumper( $result ) if $DEBUG;
    
        my $schema = $translator->schema;
        my @tables = 
            map   { $_->[1] }
            sort  { $a->[0] <=> $b->[0] } 
            map   { [ $result->{'tables'}{ $_ }->{'order'}, $_ ] }
            keys %{ $result->{'tables'} };
    
        for my $table_name ( @tables ) {
            my $tdata =  $result->{'tables'}{ $table_name };
            my $table =  $schema->add_table( 
                name  => $tdata->{'name'},
            ) or die $schema->error;
    
            $table->comments( $tdata->{'comments'} );
    
            for my $fdata ( @{ $tdata->{'fields'} } ) {
                my $field = $table->add_field(
                    name              => $fdata->{'name'},
                    data_type         => $fdata->{'data_type'},
                    size              => $fdata->{'size'},
                    default_value     => $fdata->{'default'},
                    is_auto_increment => $fdata->{'is_auto_inc'},
                    is_nullable       => $fdata->{'is_nullable'},
                    comments          => $fdata->{'comments'},
                ) or die $table->error;
    
                $table->primary_key( $field->name ) if $fdata->{'is_primary_key'};
    
                for my $cdata ( @{ $fdata->{'constraints'} } ) {
                    next unless $cdata->{'type'} eq 'foreign_key';
                    $cdata->{'fields'} ||= [ $field->name ];
                    push @{ $tdata->{'constraints'} }, $cdata;
                }
            }
    
            for my $idata ( @{ $tdata->{'indices'} || [] } ) {
                my $index  =  $table->add_index(
                    name   => $idata->{'name'},
                    type   => uc $idata->{'type'},
                    fields => $idata->{'fields'},
                ) or die $table->error;
            }
    
            for my $cdata ( @{ $tdata->{'constraints'} || [] } ) {
                my $constraint       =  $table->add_constraint(
                    name             => $cdata->{'name'},
                    type             => $cdata->{'type'},
                    fields           => $cdata->{'fields'},
                    reference_table  => $cdata->{'reference_table'},
                    reference_fields => $cdata->{'reference_fields'},
                    match_type       => $cdata->{'match_type'} || '',
                    on_delete        => $cdata->{'on_delete'} 
                                     || $cdata->{'on_delete_do'},
                    on_update        => $cdata->{'on_update'} 
                                     || $cdata->{'on_update_do'},
                ) or die $table->error;
            }
        }
    
        for my $def ( @{ $result->{'views'} || [] } ) {
            my $view = $schema->add_view(
                name => $def->{'name'},
                sql  => $def->{'sql'},
            );
        }
    
        for my $def ( @{ $result->{'triggers'} || [] } ) {
            my $view                = $schema->add_trigger(
                name                => $def->{'name'},
                perform_action_when => $def->{'when'},
                database_events     => $def->{'db_events'},
                action              => $def->{'action'},
                on_table            => $def->{'on_table'},
            );
        }
    
        return 1;
    }
}
