package SQL::Translator::Constants;
use DBI qw(:sql_types);
use Sub::Exporter -setup => {
    exports => [ @{$DBI::EXPORT_TAGS{sql_types}} ],
    groups => {
        sqlt_types => [ @{$DBI::EXPORT_TAGS{sql_types}} ],
        sqlt_fk_actions => [ qw(SQLT_FK_CASCADE SQLT_FK_RESTRICT SQLT_FK_SET_NULL SQLT_FK_NO_ACTION SQLT_FK_SET_DEFAULT) ],
    }
};

use constant SQLT_FK_CASCADE     => 0;
use constant SQLT_FK_RESTRICT    => 1;
use constant SQLT_FK_SET_NULL    => 2;
use constant SQLT_FK_NO_ACTION   => 3;
use constant SQLT_FK_SET_DEFAULT => 4;

1;
