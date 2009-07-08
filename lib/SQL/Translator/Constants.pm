package SQL::Translator::Constants;
use DBI qw(:sql_types);
use Exporter ();

BEGIN {
    @ISA = qw(Exporter);

    @EXPORT    = ();
    @EXPORT_OK = ();
    %EXPORT_TAGS = (
        sqlt_types => [
            qw(),
            @{$DBI::EXPORT_TAGS{sql_types}}
        ]
    );

    Exporter::export_ok_tags(keys %EXPORT_TAGS);
}

1;
