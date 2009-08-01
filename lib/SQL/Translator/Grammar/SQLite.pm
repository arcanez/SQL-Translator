use MooseX::Declare;
role SQL::Translator::Grammar::SQLite {
# -------------------------------------------------------------------
# Copyright (C) 2002-2009 SQLFairy Authors
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; version 2.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
# 02111-1307  USA
# -------------------------------------------------------------------

#my $GRAMMAR = q!
method _build_grammar {
return q!
{ 
    my ( %tables, $table_order, @table_comments, @views, @triggers );
}

#
# The "eofile" rule makes the parser fail if any "statement" rule
# fails.  Otherwise, the first successful match by a "statement" 
# won't cause the failure needed to know that the parse, as a whole,
# failed. -ky
#
startrule : statement(s) eofile { 
    $return      = {
        tables   => \%tables, 
        views    => \@views,
        triggers => \@triggers,
    }
}

eofile : /^\Z/

statement : begin_transaction
    | commit
    | drop
    | comment
    | create
    | <error>

begin_transaction : /begin/i TRANSACTION(?) SEMICOLON

commit : /commit/i SEMICOLON

drop : /drop/i (tbl_drop | view_drop | trg_drop) SEMICOLON

tbl_drop: TABLE <commit> table_name

view_drop: VIEW if_exists(?) view_name

trg_drop: TRIGGER if_exists(?) trigger_name

comment : /^\s*(?:#|-{2}).*\n/
    {
        my $comment =  $item[1];
        $comment    =~ s/^\s*(#|-{2})\s*//;
        $comment    =~ s/\s*$//;
        $return     = $comment;
    }

comment : /\/\*/ /[^\*]+/ /\*\// 
    {
        my $comment = $item[2];
        $comment    =~ s/^\s*|\s*$//g;
        $return = $comment;
    }

#
# Create Index
#
create : CREATE TEMPORARY(?) UNIQUE(?) INDEX WORD ON table_name parens_field_list conflict_clause(?) SEMICOLON
    {
        my $db_name    = $item[7]->{'db_name'} || '';
        my $table_name = $item[7]->{'name'};

        my $index        =  { 
            name         => $item[5],
            columns       => $item[8],
            on_conflict  => $item[9][0],
            is_temporary => $item[2][0] ? 1 : 0,
        };

        my $is_unique = $item[3][0];

        if ( $is_unique ) {
            $index->{'type'} = 'unique';
            push @{ $tables{ $table_name }{'constraints'} }, $index;
        }
        else {
            push @{ $tables{ $table_name }{'indices'} }, $index;
        }
    }

#
# Create Table
#
create : CREATE TEMPORARY(?) TABLE table_name '(' definition(s /,/) ')' SEMICOLON
    {
        my $db_name    = $item[4]->{'db_name'} || '';
        my $table_name = $item[4]->{'name'};

        $tables{ $table_name }{'name'}         = $table_name;
        $tables{ $table_name }{'is_temporary'} = $item[2][0] ? 1 : 0;
        $tables{ $table_name }{'order'}        = ++$table_order;

        for my $def ( @{ $item[6] } ) {
            if ( $def->{'supertype'} eq 'column' ) {
                push @{ $tables{ $table_name }{'columns'} }, $def;
            }
            elsif ( $def->{'supertype'} eq 'constraint' ) {
                push @{ $tables{ $table_name }{'constraints'} }, $def;
            }
        }
    }

definition : constraint_def | column_def 

column_def: comment(s?) NAME type(?) column_constraint(s?)
    {
        my $column = {
            supertype      => 'column',
            name           => $item[2],
            data_type      => $item[3][0]->{'type'},
            size           => $item[3][0]->{'size'},
            is_nullable    => 1,
            is_primary_key => 0,
            is_unique      => 0,
            check          => '',
            default        => undef,
            constraints    => $item[4],
            comments       => $item[1],
        };


        for my $c ( @{ $item[4] } ) {
            if ( $c->{'type'} eq 'not_null' ) {
                $column->{'is_nullable'} = 0;
            }
            elsif ( $c->{'type'} eq 'primary_key' ) {
                $column->{'is_primary_key'} = 1;
            }
            elsif ( $c->{'type'} eq 'unique' ) {
                $column->{'is_unique'} = 1;
            }
            elsif ( $c->{'type'} eq 'check' ) {
                $column->{'check'} = $c->{'expression'};
            }
            elsif ( $c->{'type'} eq 'default' ) {
                $column->{'default'} = $c->{'value'};
            }
        }

        $column;
    }

type : WORD parens_value_list(?)
    {
        $return = {
            type => $item[1],
            size => $item[2][0],
        }
    }

column_constraint : NOT_NULL conflict_clause(?)
    {
        $return = {
            type => 'not_null',
        }
    }
    |
    PRIMARY_KEY sort_order(?) conflict_clause(?)
    {
        $return = {
            type        => 'primary_key',
            sort_order  => $item[2][0],
            on_conflict => $item[2][0], 
        }
    }
    |
    UNIQUE conflict_clause(?)
    {
        $return = {
            type        => 'unique',
            on_conflict => $item[2][0], 
        }
    }
    |
    CHECK_C '(' expr ')' conflict_clause(?)
    {
        $return = {
            type        => 'check',
            expression  => $item[3],
            on_conflict => $item[5][0], 
        }
    }
    |
    DEFAULT VALUE
    {
        $return   = {
            type  => 'default',
            value => $item[2],
        }
    }

constraint_def : PRIMARY_KEY parens_field_list conflict_clause(?)
    {
        $return         = {
            supertype   => 'constraint',
            type        => 'primary_key',
            columns      => $item[2],
            on_conflict => $item[3][0],
        }
    }
    |
    UNIQUE parens_field_list conflict_clause(?)
    {
        $return         = {
            supertype   => 'constraint',
            type        => 'unique',
            columns      => $item[2],
            on_conflict => $item[3][0],
        }
    }
    |
    CHECK_C '(' expr ')' conflict_clause(?)
    {
        $return         = {
            supertype   => 'constraint',
            type        => 'check',
            expression  => $item[3],
            on_conflict => $item[5][0],
        }
    }

table_name : qualified_name
    
qualified_name : NAME 
    { $return = { name => $item[1] } }

qualified_name : /(\w+)\.(\w+)/ 
    { $return = { db_name => $1, name => $2 } }

field_name : NAME

conflict_clause : /on conflict/i conflict_algorigthm

conflict_algorigthm : /(rollback|abort|fail|ignore|replace)/i

parens_field_list : '(' column_list ')'
    { $item[2] }

column_list : field_name(s /,/)

parens_value_list : '(' VALUE(s /,/) ')'
    { $item[2] }

expr : /[^)]+/

sort_order : /(ASC|DESC)/i

#
# Create Trigger

create : CREATE TEMPORARY(?) TRIGGER NAME before_or_after(?) database_event ON table_name trigger_action SEMICOLON
    {
        my $table_name = $item[8]->{'name'};
        push @triggers, {
            name         => $item[4],
            is_temporary => $item[2][0] ? 1 : 0,
            when         => $item[5][0],
            instead_of   => 0,
            db_events    => [ $item[6] ],
            action       => $item[9],
            on_table     => $table_name,
        }
    }

create : CREATE TEMPORARY(?) TRIGGER NAME instead_of database_event ON view_name trigger_action
    {
        my $table_name = $item[8]->{'name'};
        push @triggers, {
            name         => $item[4],
            is_temporary => $item[2][0] ? 1 : 0,
            when         => undef,
            instead_of   => 1,
            db_events    => [ $item[6] ],
            action       => $item[9],
            on_table     => $table_name,
        }
    }

database_event : /(delete|insert|update)/i

database_event : /update of/i column_list

trigger_action : for_each(?) when(?) BEGIN_C trigger_step(s) END_C
    {
        $return = {
            for_each => $item[1][0],
            when     => $item[2][0],
            steps    => $item[4],
        }
    }

for_each : /FOR EACH ROW/i

when : WHEN expr { $item[2] }

string :
   /'(\\.|''|[^\\\'])*'/ 

nonstring : /[^;\'"]+/

statement_body : string | nonstring

trigger_step : /(select|delete|insert|update)/i statement_body(s?) SEMICOLON
    {
        $return = join( ' ', $item[1], join ' ', @{ $item[2] || [] } )
    }   

before_or_after : /(before|after)/i { $return = lc $1 }

instead_of : /instead of/i

if_exists : /if exists/i

view_name : qualified_name

trigger_name : qualified_name

#
# Create View
#
create : CREATE TEMPORARY(?) VIEW view_name AS select_statement 
    {
        push @views, {
            name         => $item[4]->{'name'},
            sql          => $item[6], 
            is_temporary => $item[2][0] ? 1 : 0,
        }
    }

select_statement : SELECT /[^;]+/ SEMICOLON
    {
        $return = join( ' ', $item[1], $item[2] );
    }

#
# Tokens
#
BEGIN_C : /begin/i

END_C : /end/i

TRANSACTION: /transaction/i

CREATE : /create/i

TEMPORARY : /temp(orary)?/i { 1 }

TABLE : /table/i

INDEX : /index/i

NOT_NULL : /not null/i

PRIMARY_KEY : /primary key/i

CHECK_C : /check/i

DEFAULT : /default/i

TRIGGER : /trigger/i

VIEW : /view/i

SELECT : /select/i

ON : /on/i

AS : /as/i

WORD : /\w+/

WHEN : /when/i

UNIQUE : /unique/i { 1 }

SEMICOLON : ';'

NAME : /'?(\w+)'?/ { $return = $1 }

VALUE : /[-+]?\.?\d+(?:[eE]\d+)?/
    { $item[1] }
    | /'.*?'/   
    { 
        # remove leading/trailing quotes 
        my $val = $item[1];
        $val    =~ s/^['"]|['"]$//g;
        $return = $val;
    }
    | /NULL/
    { 'NULL' }
    | /CURRENT_TIMESTAMP/i
    { 'CURRENT_TIMESTAMP' }
!;
}
}
