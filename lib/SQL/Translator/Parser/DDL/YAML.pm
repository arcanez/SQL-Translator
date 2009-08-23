use MooseX::Declare;
role SQL::Translator::Parser::DDL::YAML { 
    use MooseX::Types::Moose qw(Str);
    use SQL::Translator::Types qw(Schema);
    use aliased 'SQL::Translator::Object::Column';
    use aliased 'SQL::Translator::Object::Constraint';
    use aliased 'SQL::Translator::Object::Index';
    use aliased 'SQL::Translator::Object::Procedure';
    use aliased 'SQL::Translator::Object::Table';
    use aliased 'SQL::Translator::Object::Trigger';
    use aliased 'SQL::Translator::Object::View';
    use YAML qw(Load);
    use MooseX::MultiMethods;

    multi method parse(Schema $data) { $data }

    multi method parse(Str $data) {
        $data = Load($data);
        $data = $data->{schema};
    
        my $schema = $self->schema;
        my $translator = $self->translator;
    
        #
        # Tables
        #
        my @tables = 
            map   { $data->{'tables'}{ $_->[1] } }
            map   { [ $data->{'tables'}{ $_ }{'order'} || 0, $_ ] }
            keys %{ $data->{'tables'} };
    
        for my $tdata ( @tables ) {
            my $table = Table->new({ map { $tdata->{$_} ? ($_ => $tdata->{$_}) : () } qw/name extra options/ });    
            $schema->add_table($table);
    
            my @fields = 
                map   { $tdata->{'fields'}{ $_->[1] } }
                map   { [ $tdata->{'fields'}{ $_ }{'order'}, $_ ] }
                keys %{ $tdata->{'fields'} };
    
            for my $fdata ( @fields ) {
                $fdata->{sql_data_type} = $self->data_type_mapping->{$fdata->{data_type}} || -99999;
                $fdata->{table} = $table;

                my $column = Column->new($fdata);
                $table->add_column($column);
                $table->primary_key($column->name) if $fdata->{is_primary_key};
            }
    
            for my $idata ( @{ $tdata->{'indices'} || [] } ) { 
                 $idata->{table} = $table;
                 my $columns = delete $idata->{fields};

                 my $index = Index->new($idata);
                 $index->add_column($table->get_column($_)) for @$columns;
                 $table->add_index($index);
            }
    
            for my $cdata ( @{ $tdata->{'constraints'} || [] } ) {
                 $cdata->{table} = $table;
                 $cdata->{reference_columns} = delete $cdata->{reference_fields};
                 my $columns = delete $cdata->{fields} || [];
                 my $constraint = Constraint->new($cdata);
                 $constraint->add_column($table->get_column($_)) for @$columns;
                 $table->add_constraint($constraint);
            }
        }
    
        #
        # Views
        #
        my @views = 
            map   { $data->{'views'}{ $_->[1] } }
            map   { [ $data->{'views'}{ $_ }{'order'}, $_ ] }
            keys %{ $data->{'views'} };
    
        for my $vdata ( @views ) {
            my $view = View->new($vdata);
            $schema->add_view($view);
        }
    
        #
        # Triggers
        #
        my @triggers = 
            map   { $data->{'triggers'}{ $_->[1] } }
            map   { [ $data->{'triggers'}{ $_ }{'order'}, $_ ] }
            keys %{ $data->{'triggers'} };
    
        for my $tdata ( @triggers ) {
            my $columns = delete $tdata->{fields} || ();
            my $trigger = Trigger->new($tdata);
            $trigger->add_column($schema->get_table($tdata->{on_table})->get_column($_)) for @$columns; 
            $schema->add_trigger($trigger);
        }
    
        #
        # Procedures
        #
        my @procedures = 
            map   { $data->{'procedures'}{ $_->[1] } }
            map   { [ $data->{'procedures'}{ $_ }{'order'}, $_ ] }
            keys %{ $data->{'procedures'} };
    
        for my $tdata ( @procedures ) {
             my $procedure = Procedure->new($tdata);
             $schema->add_procedure($procedure);
        }
    
        if ( my $tr_data = $data->{'translator'} ) {
            $translator->add_drop_table( $tr_data->{'add_drop_table'} );
            $translator->filename( $tr_data->{'filename'} );
            $translator->no_comments( $tr_data->{'no_comments'} );
            $translator->parser_args( $tr_data->{'parser_args'} );
            $translator->producer_args( $tr_data->{'producer_args'} );
            $translator->parser_type( $tr_data->{'parser_type'} );
            $translator->producer_type( $tr_data->{'producer_type'} );
            $translator->show_warnings( $tr_data->{'show_warnings'} );
            $translator->trace( $tr_data->{'trace'} );
        }
    
        return $schema;
    }
}
