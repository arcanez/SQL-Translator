use MooseX::Declare;
role SQL::Translator::Parser::DDL::YAML { 
    use MooseX::Types::Moose qw(Any Str);
    use SQL::Translator::Types qw(Schema);
    use aliased 'SQL::Translator::Object::Column';
    use aliased 'SQL::Translator::Object::Constraint';
    use aliased 'SQL::Translator::Object::Index';
    use aliased 'SQL::Translator::Object::Table';
    use aliased 'SQL::Translator::Object::Schema' => 'SchemaObj';
    use YAML qw(Load);
    use MooseX::MultiMethods;

#    multi method parse(Any $data) { use Data::Dumper; die Dumper($data); }
    multi method parse(Schema $data) { return $data }

    multi method parse(Str $data) {
        return $data if blessed $data && $data->isa('SQL::Translator::Object::Schema');
        $data = Load($data);
        $data = $data->{schema};
    
#        warn "YAML data:",Dumper( $data ) if $self->debug;

        my $schema = SchemaObj->new; #$self->schema;
    
        #
        # Tables
        #
        my @tables = 
            map   { $data->{'tables'}{ $_->[1] } }
#            sort  { $a->[0] <=> $b->[0] }
            map   { [ $data->{'tables'}{ $_ }{'order'} || 0, $_ ] }
            keys %{ $data->{'tables'} } ;
    
        for my $tdata ( @tables ) {
            my $table = Table->new({ map { $tdata->{$_} ? ($_ => $tdata->{$_}) : () } qw/name extra options/ });    
            $schema->add_table($table);
#            my $table = $schema->add_table(
#                map {
#                  $tdata->{$_} ? ($_ => $tdata->{$_}) : ()
#                } (qw/name extra options/)
#            ) or die $schema->error;
    
            my @fields = 
                map   { $tdata->{'fields'}{ $_->[1] } }
#                sort  { $a->[0] <=> $b->[0] }
                map   { [ $tdata->{'fields'}{ $_ }{'order'}, $_ ] }
                keys %{ $tdata->{'fields'} } ;
    
            for my $fdata ( @fields ) {
#                $table->add_field( %$fdata ) or die $table->error;
                $fdata->{sql_data_type} = $self->data_type_mapping->{$fdata->{data_type}} || -99999;
                my $column = Column->new($fdata);
                $table->add_column($column);
                $table->primary_key($column->name) if $fdata->{is_primary_key};
            }
    
            for my $idata ( @{ $tdata->{'indices'} || [] } ) {
#                $table->add_index( %$idata ) or die $table->error;
                 my $index = Index->new($idata);
                 $table->add_index($index);
            }
    
            for my $cdata ( @{ $tdata->{'constraints'} || [] } ) {
#                $table->add_constraint( %$cdata ) or die $table->error;
                 my $constraint = Constraint->new($cdata);
                 $table->add_constraint($constraint);
            }
        }
    
        #
        # Views
        #
        my @views = 
            map   { $data->{'views'}{ $_->[1] } }
            sort  { $a->[0] <=> $b->[0] }
            map   { [ $data->{'views'}{ $_ }{'order'}, $_ ] }
            keys %{ $data->{'views'} } ;
    
        for my $vdata ( @views ) {
#            $schema->add_view( %$vdata ) or die $schema->error;
        }
    
        #
        # Triggers
        #
        my @triggers = 
            map   { $data->{'triggers'}{ $_->[1] } }
            sort  { $a->[0] <=> $b->[0] }
            map   { [ $data->{'triggers'}{ $_ }{'order'}, $_ ] }
            keys %{ $data->{'triggers'} }
        ;
    
        for my $tdata ( @triggers ) {
#            $schema->add_trigger( %$tdata ) or die $schema->error;
        }
    
        #
        # Procedures
        #
        my @procedures = 
            map   { $data->{'procedures'}{ $_->[1] } }
            sort  { $a->[0] <=> $b->[0] }
            map   { [ $data->{'procedures'}{ $_ }{'order'}, $_ ] }
            keys %{ $data->{'procedures'} }
        ;
    
        for my $tdata ( @procedures ) {
#            $schema->add_procedure( %$tdata ) or die $schema->error;
        }
    
        if ( my $tr_data = $data->{'translator'} ) {
            $self->add_drop_table( $tr_data->{'add_drop_table'} );
            $self->filename( $tr_data->{'filename'} );
            $self->no_comments( $tr_data->{'no_comments'} );
            $self->parser_args( $tr_data->{'parser_args'} );
            $self->producer_args( $tr_data->{'producer_args'} );
            $self->parser_type( $tr_data->{'parser_type'} );
            $self->producer_type( $tr_data->{'producer_type'} );
            $self->show_warnings( $tr_data->{'show_warnings'} );
            $self->trace( $tr_data->{'trace'} );
        }
    
        return $schema;
    }
}
