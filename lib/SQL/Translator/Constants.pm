package SQL::Translator::Constants;
use DBI qw(:sql_types);
use Sub::Exporter -setup => {
    exports => [ @{$DBI::EXPORT_TAGS{sql_types}}, CHECK_C, FOREIGN_KEY, FULL_TEXT, SPATIAL, NOT_NULL, NORMAL, NULL, PRIMARY_KEY, UNIQUE ],
    groups => {
        sqlt_types => [ @{$DBI::EXPORT_TAGS{sql_types}} ],
        sqlt_fk_actions => [ qw(SQLT_FK_CASCADE SQLT_FK_RESTRICT SQLT_FK_SET_NULL SQLT_FK_NO_ACTION SQLT_FK_SET_DEFAULT) ],
        sqlt_constants => [ qw(CHECK_C FOREIGN_KEY FULL_TEXT SPATIAL NOT_NULL NORMAL NULL PRIMARY_KEY UNIQUE) ],
    }
};

use constant SQLT_FK_CASCADE     => 0;
use constant SQLT_FK_RESTRICT    => 1;
use constant SQLT_FK_SET_NULL    => 2;
use constant SQLT_FK_NO_ACTION   => 3;
use constant SQLT_FK_SET_DEFAULT => 4;

use constant CHECK_C => 'CHECK';
use constant FOREIGN_KEY => 'FOREIGN KEY';
use constant FULL_TEXT => 'FULLTEXT';
use constant SPATIAL => 'SPATIAL';
use constant NOT_NULL => 'NOT NULL';
use constant NORMAL => 'NORMAL';
use constant NULL => 'NULL';
use constant PRIMARY_KEY => 'PRIMARY KEY';
use constant UNIQUE => 'UNIQUE';

1;
