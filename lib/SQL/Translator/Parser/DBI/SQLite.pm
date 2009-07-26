use MooseX::Declare;
role SQL::Translator::Parser::DBI::SQLite {
    use MooseX::Types::Moose qw(HashRef);
    use SQL::Translator::Constants qw(:sqlt_types);

    my %data_type_mapping = (
        'text' => SQL_LONGVARCHAR(),
        'timestamp' => SQL_TIMESTAMP(),
        'timestamp without time zone' => SQL_TYPE_TIMESTAMP(),
        'timestamp' => SQL_TYPE_TIMESTAMP_WITH_TIMEZONE(),
        'integer' => SQL_INTEGER(),
        'character' => SQL_CHAR(),
        'varchar' => SQL_VARCHAR(),
        'bigint' => SQL_BIGINT(),
    );

    method _column_data_type(HashRef $column_info) {
        print $column_info->{TYPE_NAME} . "\n";
        my $data_type = defined $data_type_mapping{$column_info->{TYPE_NAME}} ?
                        $data_type_mapping{$column_info->{TYPE_NAME}} :
                        -1;
        return $data_type;
    }

}
