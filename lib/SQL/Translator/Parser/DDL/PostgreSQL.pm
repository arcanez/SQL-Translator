use MooseX::Declare;
role SQL::Translator::Parser::DDL::PostgreSQL {
    use MooseX::Types::Moose qw(Str);
    use MooseX::MultiMethods;
    use Moose::Autobox;
    use SQL::Translator::Constants qw(:sqlt_types :sqlt_constants);
    use SQL::Translator::Types qw(Schema);
    use aliased 'SQL::Translator::Object::Column';
    use aliased 'SQL::Translator::Object::Constraint';
    use aliased 'SQL::Translator::Object::ForeignKey';
    use aliased 'SQL::Translator::Object::Index';
    use aliased 'SQL::Translator::Object::PrimaryKey';
    use aliased 'SQL::Translator::Object::Table';
    use aliased 'SQL::Translator::Object::View';

    multi method parse(Schema $data) { $data }

    multi method parse(Str $data) {
        my $translator = $self->translator;
        my $parser = Parse::RecDescent->new($self->grammar);
    
        unless (defined $parser) {
            return $translator->error("Error instantiating Parse::RecDescent ".
                "instance: Bad grammar");
        }
    
        my $result = $parser->startrule($data);
        die "Parse failed.\n" unless defined $result;

        my $schema = $translator->schema;
        my @tables = 
         sort { ( $result->{tables}{ $a }{'order'} || 0 ) <=> ( $result->{tables}{ $b }{'order'} || 0 ) }
         keys %{ $result->{tables} };
    
        for my $table_name ( @tables ) {
            my $tdata = $result->{tables}{ $table_name };
            my $table = Table->new({ name => $tdata->{table_name}, schema => $schema });
            $schema->add_table($table);
    
            $table->extra({ temporary => 1 }) if $tdata->{'temporary'};
            $table->comments( [ $tdata->{'comments'}->flatten ]) if $tdata->{comments};
    
            my @fields = sort { $tdata->{'fields'}{ $a }{'order'} <=> $tdata->{'fields'}{ $b }{'order'} } keys %{ $tdata->{'fields'} };
    
            for my $fname ( @fields ) {
                my $fdata = $tdata->{'fields'}{ $fname };
                next if $fdata->{'drop'};
                my $field = Column->new({
                    name              => $fdata->{'name'},
                    data_type         => $fdata->{'data_type'},
                    sql_data_type     => $self->data_type_mapping->{$fdata->{data_type}} || -999999,
                    size              => $fdata->{'size'},
                    default_value     => $fdata->{'default'},
                    is_auto_increment => $fdata->{'is_auto_increment'}, 
                    is_nullable       => $fdata->{'is_nullable'},
                    table             => $table,
                });
                $field->comments($fdata->{comments});

                $table->add_column($field);
                $field->is_primary_key(1) if $fdata->{is_primary_key};
    
                for my $cdata ( @{ $fdata->{constraints} } ) {
                    next unless lc $cdata->{type} eq 'foreign_key';
                    $cdata->{fields} ||= [ $field->name ];
                    push @{ $tdata->{constraints} }, $cdata;
                }
            }
    
            for my $idata ( @{ $tdata->{indices} || [] } ) {
                my $index = Index->new({
                    name    => $idata->{name},
                    type    => uc $idata->{type},
                    table   => $table,
                });
                $index->add_column($table->get_column($_)) for @{$idata->{fields}};
                $table->add_index($index);
            }
    
            for my $cdata ( @{ $tdata->{'constraints'} || [] } ) {
                my $constraint;
                $cdata->{type} =~ s/_/ /g;
                if (uc $cdata->{type} eq PRIMARY_KEY) {
                    $constraint = PrimaryKey->new({ name => $cdata->{name} || '', table => $table });
                    $table->get_column($_)->is_primary_key(1) for @{$cdata->{fields}};
                } elsif (uc $cdata->{type} eq FOREIGN_KEY) {
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
        }
    
        for my $vinfo (@{$result->{views}}) {
          my $sql = $vinfo->{sql};
          $sql =~ s/\A\s+|\s+\z//g;
          my $view = View->new({
            name    => $vinfo->{view_name},
            sql     => $sql,
          });

          $schema->add_view($view);
    
          $view->extra ( temporary => 1 ) if $vinfo->{is_temporary};
        }
    
        return 1;
    }
}
