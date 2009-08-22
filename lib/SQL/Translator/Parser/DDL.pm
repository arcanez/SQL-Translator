use MooseX::Declare;
role SQL::Translator::Parser::DDL {
    use MooseX::Types::Moose qw(HashRef Maybe Str);
    use SQL::Translator::Types qw(Schema);
    use SQL::Translator::Constants qw(:sqlt_types);
    use MooseX::MultiMethods;
    use Parse::RecDescent;

    has 'data_type_mapping' => (
        isa => HashRef,
        is => 'ro',
        lazy_build => 1
    );

    has 'schema_name' => (
        is => 'rw',
        isa => Maybe[Str],
        lazy => 1,
        default => undef
    );

    has 'grammar' => (
        is => 'ro',
        isa => Str,
        lazy_build => 1
    );

    method _subclass {
        return unless $self->type;

        my $grammar = 'SQL::Translator::Grammar::' . $self->type;
        Class::MOP::load_class($grammar);
        $grammar->meta->apply($self);

        my $role = __PACKAGE__ . '::' . $self->type;
        Class::MOP::load_class($role);
        $role->meta->apply($self);
    }

    method _build_data_type_mapping {
        return {
            'text' => SQL_LONGVARCHAR(),
            'timestamp' => SQL_TIMESTAMP(),
            'timestamp without time zone' => SQL_TYPE_TIMESTAMP(),
            'timestamp' => SQL_TYPE_TIMESTAMP_WITH_TIMEZONE(),
            'int' => SQL_INTEGER(),
            'integer' => SQL_INTEGER(),
            'character' => SQL_CHAR(),
            'varchar' => SQL_VARCHAR(),
            'char' => SQL_CHAR(),
            'bigint' => SQL_BIGINT()
        }
    }
}
