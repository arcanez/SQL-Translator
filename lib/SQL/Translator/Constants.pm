package SQL::Translator::Constants;
use DBI qw(:sql_types);
use Sub::Exporter -setup => {
    exports => [ @{$DBI::EXPORT_TAGS{sql_types}} ],
    groups => {
        sqlt_types => [ @{$DBI::EXPORT_TAGS{sql_types}} ] 
    }
};

1;
