use MooseX::Declare;
role SQL::Translator::Grammar::PostgreSQL {
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

    method _build_grammar {
        return q!
        { my ( %tables, @views, $table_order, $field_order, @table_comments) }
    
        #
        # The "eofile" rule makes the parser fail if any "statement" rule
        # fails.  Otherwise, the first successful match by a "statement" 
        # won't cause the failure needed to know that the parse, as a whole,
        # failed. -ky
        #
        startrule : statement(s) eofile { { tables => \%tables, views => \@views } }
    
        eofile : /^\Z/
           
    
        statement : create
          | comment_on_table
          | comment_on_column
          | comment_on_other
          | comment
          | alter
          | grant
          | revoke
          | drop
          | insert
          | connect
          | update
          | set
          | select
          | copy
          | readin_symbol
          | <error>
    
        connect : /^\s*\\\connect.*\n/
    
        set : /set/i /[^;]*/ ';'
    
        revoke : /revoke/i WORD(s /,/) /on/i TABLE(?) table_id /from/i name_with_opt_quotes(s /,/) ';'
            {
            my $table_info  = $item{'table_id'};
            my $schema_name = $table_info->{'schema_name'};
            my $table_name  = $table_info->{'table_name'};
            push @{ $tables{ $table_name }{'permissions'} }, {
                type       => 'revoke',
                actions    => $item[2],
                users      => $item[7],
            }
            }
    
        revoke : /revoke/i WORD(s /,/) /on/i SCHEMA(?) schema_name /from/i name_with_opt_quotes(s /,/) ';'
            { 1 }
    
        grant : /grant/i WORD(s /,/) /on/i TABLE(?) table_id /to/i name_with_opt_quotes(s /,/) ';'
            {
            my $table_info  = $item{'table_id'};
            my $schema_name = $table_info->{'schema_name'};
            my $table_name  = $table_info->{'table_name'};
            push @{ $tables{ $table_name }{'permissions'} }, {
                type       => 'grant',
                actions    => $item[2],
                users      => $item[7],
            }
            }
    
        grant : /grant/i WORD(s /,/) /on/i SCHEMA(?) schema_name /to/i name_with_opt_quotes(s /,/) ';'
            { 1 }
    
        drop : /drop/i /[^;]*/ ';'
    
        string :
           /'(\\.|''|[^\\\'])*'/ 
    
        nonstring : /[^;\'"]+/
    
        statement_body : string | nonstring
    
        insert : /insert/i statement_body(s?) ';'
    
        update : /update/i statement_body(s?) ';'
    
        #
        # Create table.
        #
        create : CREATE temporary(?) TABLE table_id '(' create_definition(s? /,/) ')' table_option(s?) ';'
            {
            my $table_info  = $item{'table_id'};
            my $schema_name = $table_info->{'schema_name'};
            my $table_name  = $table_info->{'table_name'};
            $tables{ $table_name }{'order'}       = ++$table_order;
            $tables{ $table_name }{'schema_name'} = $schema_name;
            $tables{ $table_name }{'table_name'}  = $table_name;
    
            $tables{ $table_name }{'temporary'} = $item[2][0];
    
            if ( @table_comments ) {
                $tables{ $table_name }{'comments'} = [ @table_comments ];
                @table_comments = ();
            }
    
            my @constraints;
            for my $definition ( @{ $item[6] } ) {
                if ( $definition->{'supertype'} eq 'field' ) {
                my $field_name = $definition->{'name'};
                $tables{ $table_name }{'fields'}{ $field_name } = 
                    { %$definition, order => $field_order++ };
                        
                for my $constraint ( @{ $definition->{'constraints'} || [] } ) {
                    $constraint->{'fields'} = [ $field_name ];
                    push @{ $tables{ $table_name }{'constraints'} },
                    $constraint;
                }
                }
                elsif ( $definition->{'supertype'} eq 'constraint' ) {
                push @{ $tables{ $table_name }{'constraints'} }, $definition;
                }
                elsif ( $definition->{'supertype'} eq 'index' ) {
                push @{ $tables{ $table_name }{'indices'} }, $definition;
                }
            }
    
            for my $option ( @{ $item[8] } ) {
                $tables{ $table_name }{'table_options(s?)'}{ $option->{'type'} } = 
                $option;
            }
    
            1;
            }
    
        create : CREATE unique(?) /(index|key)/i index_name /on/i table_id using_method(?) '(' field_name(s /,/) ')' where_predicate(?) ';'
            {
            my $table_info  = $item{'table_id'};
            my $schema_name = $table_info->{'schema_name'};
            my $table_name  = $table_info->{'table_name'};
            push @{ $tables{ $table_name }{'indices'} },
                {
                name      => $item{'index_name'},
                supertype => $item{'unique'}[0] ? 'constraint' : 'index',
                type      => $item{'unique'}[0] ? 'unique'     : 'normal',
                fields    => $item[9],
                method    => $item{'using_method'}[0],
                }
            ;
            }
    
        create : CREATE or_replace(?) temporary(?) VIEW view_id view_fields(?) /AS/i view_target ';'
            {
            push @views, {
                schema_name  => $item{view_id}{schema_name},
                view_name    => $item{view_id}{view_name},
                sql          => $item{view_target},
                fields       => $item[6],
                is_temporary => $item[3][0],
            }
            }
    
        #
        # Create anything else (e.g., domain, etc.)
        #
        create : CREATE WORD /[^;]+/ ';'
            { @table_comments = (); }
    
        using_method : /using/i WORD { $item[2] }
    
        where_predicate : /where/i /[^;]+/
    
        create_definition : field
            | table_constraint
            | <error>
    
        comment : /^\s*(?:#|-{2})(.*)\n/ 
            { 
            my $comment =  $item[1];
            $comment    =~ s/^\s*(#|-*)\s*//;
            $comment    =~ s/\s*$//;
            $return     = $comment;
            push @table_comments, $comment;
            }
    
        comment_on_table : /comment/i /on/i /table/i table_id /is/i comment_phrase ';'
            {
            my $table_info  = $item{'table_id'};
            my $schema_name = $table_info->{'schema_name'};
            my $table_name  = $table_info->{'table_name'};
            push @{ $tables{ $table_name }{'comments'} }, $item{'comment_phrase'};
            }
    
        comment_on_column : /comment/i /on/i /column/i column_name /is/i comment_phrase ';'
            {
            my $table_name = $item[4]->{'table'};
            my $field_name = $item[4]->{'field'};
            if ($tables{ $table_name }{'fields'}{ $field_name } ) {
              push @{ $tables{ $table_name }{'fields'}{ $field_name }{'comments'} }, 
                  $item{'comment_phrase'};
            }
            else {
               die "No such column as $table_name.$field_name";
            }
            }
    
        comment_on_other : /comment/i /on/i /\w+/ /\w+/ /is/i comment_phrase ';'
            {
            push(@table_comments, $item{'comment_phrase'});
            }
    
        # [added by cjm 20041019]
        # [TODO: other comment-on types]
        # for now we just have a general mechanism for handling other
        # kinds of comments than table/column; I'm not sure of the best
        # way to incorporate these into the datamodel
        #
        # this is the exhaustive list of types of comment:
        #COMMENT ON DATABASE my_database IS 'Development Database';
        #COMMENT ON INDEX my_index IS 'Enforces uniqueness on employee id';
        #COMMENT ON RULE my_rule IS 'Logs UPDATES of employee records';
        #COMMENT ON SEQUENCE my_sequence IS 'Used to generate primary keys';
        #COMMENT ON TABLE my_table IS 'Employee Information';
        #COMMENT ON TYPE my_type IS 'Complex Number support';
        #COMMENT ON VIEW my_view IS 'View of departmental costs';
        #COMMENT ON COLUMN my_table.my_field IS 'Employee ID number';
        #COMMENT ON TRIGGER my_trigger ON my_table IS 'Used for R.I.';
        #
        # this is tested by test 08
    
        column_name : NAME '.' NAME
            { $return = { table => $item[1], field => $item[3] } }
    
        comment_phrase : /null/i
            { $return = 'NULL' }
    
        comment_phrase : /'/ comment_phrase_unquoted(s) /'/
            { my $phrase = join(' ', @{ $item[2] });
              $return = $phrase}
    
        # [cjm TODO: double-single quotes in a comment_phrase]
        comment_phrase_unquoted : /[^\']*/
            { $return = $item[1] }
    
    
        xxxcomment_phrase : /'.*?'|NULL/ 
            { 
            my $val = $item[1] || '';
            $val =~ s/^'|'$//g;
            $return = $val;
            }
    
        field : field_comment(s?) field_name data_type field_meta(s?) field_comment(s?)
            {
            my ( $default, @constraints, $is_pk );
            my $is_nullable = 1;
            for my $meta ( @{ $item[4] } ) {
                if ( $meta->{'type'} eq 'default' ) {
                $default = $meta;
                next;
                }
                elsif ( $meta->{'type'} eq 'not_null' ) {
                $is_nullable = 0;
                }
                elsif ( $meta->{'type'} eq 'primary_key' ) {
                $is_pk = 1;
                }
    
                push @constraints, $meta if $meta->{'supertype'} eq 'constraint';
            }
    
            my @comments = ( @{ $item[1] }, @{ $item[5] } );
    
            $return = {
                supertype         => 'field',
                name              => $item{'field_name'}, 
                data_type         => $item{'data_type'}{'type'},
                size              => $item{'data_type'}{'size'},
                is_nullable       => $is_nullable,
                default           => $default->{'value'},
                constraints       => [ @constraints ],
                comments          => [ @comments ],
                is_primary_key    => $is_pk || 0,
                is_auto_increment => $item{'data_type'}{'is_auto_increment'},
            } 
            }
            | <error>
    
        field_comment : /^\s*(?:#|-{2})(.*)\n/ 
            { 
            my $comment =  $item[1];
            $comment    =~ s/^\s*(#|-*)\s*//;
            $comment    =~ s/\s*$//;
            $return     = $comment;
            }
    
        field_meta : default_val
            | column_constraint
    
        view_fields : '(' field_name(s /,/) ')'
            { $return = join (',', @{$item[2]} ) }
    
        column_constraint : constraint_name(?) column_constraint_type deferrable(?) deferred(?)
            {
            my $desc       = $item{'column_constraint_type'};
            my $type       = $desc->{'type'};
            my $fields     = $desc->{'fields'}     || [];
            my $expression = $desc->{'expression'} || '';
    
            $return              =  {
                supertype        => 'constraint',
                name             => $item{'constraint_name'}[0] || '',
                type             => $type,
                expression       => $type eq 'check' ? $expression : '',
                deferrable       => $item{'deferrable'},
                deferred         => $item{'deferred'},
                reference_table  => $desc->{'reference_table'},
                reference_fields => $desc->{'reference_fields'},
                match_type       => $desc->{'match_type'},
                on_delete        => $desc->{'on_delete'} || $desc->{'on_delete_do'},
                on_update        => $desc->{'on_update'} || $desc->{'on_update_do'},
            } 
            }
    
        constraint_name : /constraint/i name_with_opt_quotes { $item[2] }
    
        column_constraint_type : /not null/i { $return = { type => 'not_null' } }
            |
            /null/i
            { $return = { type => 'null' } }
            |
            /unique/i
            { $return = { type => 'unique' } }
            |
            /primary key/i 
            { $return = { type => 'primary_key' } }
            |
            /check/i '(' /[^)]+/ ')' 
            { $return = { type => 'check', expression => $item[3] } }
            |
            /references/i table_id parens_word_list(?) match_type(?) key_action(s?)
            {
            my $table_info  = $item{'table_id'};
            my $schema_name = $table_info->{'schema_name'};
            my $table_name  = $table_info->{'table_name'};
            my ( $on_delete, $on_update );
            for my $action ( @{ $item[5] || [] } ) {
                $on_delete = $action->{'action'} if $action->{'type'} eq 'delete';
                $on_update = $action->{'action'} if $action->{'type'} eq 'update';
            }
    
            $return              =  {
                type             => 'foreign_key',
                reference_table  => $table_name,
                reference_fields => $item[3][0],
                match_type       => $item[4][0],
                on_delete        => $on_delete,
                on_update        => $on_update,
            }
            }
    
        table_id : schema_qualification(?) name_with_opt_quotes {
            $return = { schema_name => $item[1][0], table_name => $item[2] }
        }
    
        view_id : schema_qualification(?) name_with_opt_quotes {
            $return = { schema_name => $item[1][0], view_name => $item[2] }
        }
    
        view_target : /select|with/i /[^;]+/ {
            $return = "$item[1] $item[2]";
        }
    
        # SELECT views _may_ support outer parens, and we used to produce
        # such sql, although non-standard. Use ugly lookeahead to parse
        view_target : '('   /select/i    / [^;]+ (?= \) ) /x    ')'    {
            $return = "$item[2] $item[3]"
        }
    
        view_target_spec :  
    
        schema_qualification : name_with_opt_quotes '.'
    
        schema_name : name_with_opt_quotes
    
        field_name : name_with_opt_quotes
    
        name_with_opt_quotes : double_quote(?) NAME double_quote(?) { $item[2] }
    
        double_quote: /"/
    
        index_name : name_with_opt_quotes
    
        data_type : pg_data_type parens_value_list(?)
            { 
            my $data_type = $item[1];
    
            #
            # We can deduce some sizes from the data type's name.
            #
            if ( my $size = $item[2][0] ) {
                $data_type->{'size'} = $size;
            }
    
            $return  = $data_type;
            }
    
        pg_data_type :
            /(bigint|int8)/i
            { 
                $return = { 
                type => 'integer',
                size => 20,
                };
            }
            |
            /(smallint|int2)/i
            { 
                $return = {
                type => 'integer', 
                size => 5,
                };
            }
            |
            /interval/i
            {
                $return = { type => 'interval' };
            }
            |
            /(integer|int4?)/i # interval must come before this
            { 
                $return = {
                type => 'integer', 
                size => 10,
                };
            }
            |    
            /(real|float4)/i
            { 
                $return = {
                type => 'real', 
                size => 10,
                };
            }
            |
            /(double precision|float8?)/i
            { 
                $return = {
                type => 'float', 
                size => 20,
                }; 
            }
            |
            /(bigserial|serial8)/i
            { 
                $return = { 
                type              => 'integer', 
                size              => 20, 
                is_auto_increment => 1,
                };
            }
            |
            /serial4?/i
            { 
                $return = { 
                type              => 'integer',
                size              => 11, 
                is_auto_increment => 1,
                };
            }
            |
            /(bit varying|varbit)/i
            { 
                $return = { type => 'varbit' };
            }
            |
            /character varying/i
            { 
                $return = { type => 'varchar' };
            }
            |
            /char(acter)?/i
            { 
                $return = { type => 'char' };
            }
            |
            /bool(ean)?/i
            { 
                $return = { type => 'boolean' };
            }
            |
            /bytea/i
            { 
                $return = { type => 'bytea' };
            }
            |
            /(timestamptz|timestamp)(?:\(\d\))?( with(?:out)? time zone)?/i
            { 
                $return = { type => 'timestamp' . ($2||'') };
            }
            |
            /text/i
            { 
                $return = { 
                type => 'text',
                size => 64_000,
                };
            }
            |
            /(bit|box|cidr|circle|date|inet|line|lseg|macaddr|money|numeric|decimal|path|point|polygon|timetz|time|varchar)/i
            { 
                $return = { type => $item[1] };
            }
    
        parens_value_list : '(' VALUE(s /,/) ')'
            { $item[2] }
    
    
        parens_word_list : '(' name_with_opt_quotes(s /,/) ')'
            { $item[2] }
    
        field_size : '(' num_range ')' { $item{'num_range'} }
    
        num_range : DIGITS ',' DIGITS
            { $return = $item[1].','.$item[3] }
            | DIGITS
            { $return = $item[1] }
    
        table_constraint : comment(s?) constraint_name(?) table_constraint_type deferrable(?) deferred(?) comment(s?)
            {
            my $desc       = $item{'table_constraint_type'};
            my $type       = $desc->{'type'};
            my $fields     = $desc->{'fields'};
            my $expression = $desc->{'expression'};
            my @comments   = ( @{ $item[1] }, @{ $item[-1] } );
    
            $return              =  {
                name             => $item[2][0] || '',
                supertype        => 'constraint',
                type             => $type,
                fields           => $type ne 'check' ? $fields : [],
                expression       => $type eq 'check' ? $expression : '',
                deferrable       => $item{'deferrable'},
                deferred         => $item{'deferred'},
                reference_table  => $desc->{'reference_table'},
                reference_fields => $desc->{'reference_fields'},
                match_type       => $desc->{'match_type'},
                on_delete        => $desc->{'on_delete'} || $desc->{'on_delete_do'},
                on_update        => $desc->{'on_update'} || $desc->{'on_update_do'},
                comments         => [ @comments ],
            } 
            }
    
        table_constraint_type : /primary key/i '(' name_with_opt_quotes(s /,/) ')' 
            { 
            $return = {
                type   => 'primary_key',
                fields => $item[3],
            }
            }
            |
            /unique/i '(' name_with_opt_quotes(s /,/) ')' 
            { 
            $return    =  {
                type   => 'unique',
                fields => $item[3],
            }
            }
            |
            /check/i '(' /[^)]+/ ')' 
            {
            $return        =  {
                type       => 'check',
                expression => $item[3],
            }
            }
            |
            /foreign key/i '(' name_with_opt_quotes(s /,/) ')' /references/i table_id parens_word_list(?) match_type(?) key_action(s?)
            {
            my ( $on_delete, $on_update );
            for my $action ( @{ $item[9] || [] } ) {
                $on_delete = $action->{'action'} if $action->{'type'} eq 'delete';
                $on_update = $action->{'action'} if $action->{'type'} eq 'update';
            }
            
            $return              =  {
                supertype        => 'constraint',
                type             => 'foreign_key',
                fields           => $item[3],
                reference_table  => $item[6]->{'table_name'},
                reference_fields => $item[7][0],
                match_type       => $item[8][0],
                on_delete     => $on_delete || '',
                on_update     => $on_update || '',
            }
            }
    
        deferrable : not(?) /deferrable/i 
            { 
            $return = ( $item[1] =~ /not/i ) ? 0 : 1;
            }
    
        deferred : /initially/i /(deferred|immediate)/i { $item[2] }
    
        match_type : /match/i /partial|full|simple/i { $item[2] }

        key_action : key_delete 
            |
            key_update
    
        key_delete : /on delete/i key_mutation
            { 
            $return = { 
                type   => 'delete',
                action => $item[2],
            };
            }
    
        key_update : /on update/i key_mutation
            { 
            $return = { 
                type   => 'update',
                action => $item[2],
            };
            }
    
        key_mutation : /no action/i { $return = 'no_action' }
            |
            /restrict/i { $return = 'restrict' }
            |
            /cascade/i { $return = 'cascade' }
            |
            /set null/i { $return = 'set null' }
            |
            /set default/i { $return = 'set default' }
    
        alter : alter_table table_id add_column field ';' 
            { 
            my $field_def = $item[4];
            $tables{ $item[2]->{'table_name'} }{'fields'}{ $field_def->{'name'} } = {
                %$field_def, order => $field_order++
            };
            1;
            }
    
        alter : alter_table table_id ADD table_constraint ';' 
            { 
            my $table_name = $item[2]->{'table_name'};
            my $constraint = $item[4];
            push @{ $tables{ $table_name }{'constraints'} }, $constraint;
            1;
            }
    
        alter : alter_table table_id drop_column NAME restrict_or_cascade(?) ';' 
            {
            $tables{ $item[2]->{'table_name'} }{'fields'}{ $item[4] }{'drop'} = 1;
            1;
            }
    
        alter : alter_table table_id alter_column NAME alter_default_val ';' 
            {
            $tables{ $item[2]->{'table_name'} }{'fields'}{ $item[4] }{'default'} = 
                $item[5]->{'value'};
            1;
            }
    
        #
        # These will just parse for now but won't affect the structure. - ky
        #
        alter : alter_table table_id /rename/i /to/i NAME ';'
            { 1 }
    
        alter : alter_table table_id alter_column NAME SET /statistics/i INTEGER ';' 
            { 1 }
    
        alter : alter_table table_id alter_column NAME SET /storage/i storage_type ';'
            { 1 }
    
        alter : alter_table table_id rename_column NAME /to/i NAME ';'
            { 1 }
    
        alter : alter_table table_id DROP /constraint/i NAME restrict_or_cascade ';'
            { 1 }
    
        alter : alter_table table_id /owner/i /to/i NAME ';'
            { 1 }
    
        alter : alter_sequence NAME /owned/i /by/i column_name ';'
            { 1 }
    
        storage_type : /(plain|external|extended|main)/i
    
        temporary : /temp(orary)?\\b/i
          {
            1;
          }
    
        or_replace : /or replace/i
    
        alter_default_val : SET default_val 
            { 
            $return = { value => $item[2]->{'value'} } 
            }
            | DROP DEFAULT 
            { 
            $return = { value => undef } 
            } 
    
        #
        # This is a little tricky to get right, at least WRT to making the 
        # tests pass.  The problem is that the constraints are stored just as
        # a list (no name access), and the tests expect the constraints in a
        # particular order.  I'm going to leave the rule but disable the code 
        # for now. - ky
        #
        alter : alter_table table_id alter_column NAME alter_nullable ';'
            {
        #        my $table_name  = $item[2]->{'table_name'};
        #        my $field_name  = $item[4];
        #        my $is_nullable = $item[5]->{'is_nullable'};
        #
        #        $tables{ $table_name }{'fields'}{ $field_name }{'is_nullable'} = 
        #            $is_nullable;
        #
        #        if ( $is_nullable ) {
        #            1;
        #            push @{ $tables{ $table_name }{'constraints'} }, {
        #                type   => 'not_null',
        #                fields => [ $field_name ],
        #            };
        #        }
        #        else {
        #            for my $i ( 
        #                0 .. $#{ $tables{ $table_name }{'constraints'} || [] } 
        #            ) {
        #                my $c = $tables{ $table_name }{'constraints'}[ $i ] or next;
        #                my $fields = join( '', @{ $c->{'fields'} || [] } ) or next;
        #                if ( $c->{'type'} eq 'not_null' && $fields eq $field_name ) {
        #                    delete $tables{ $table_name }{'constraints'}[ $i ];
        #                    last;
        #                }
        #            }
        #        }
    
            1;
            }
    
        alter_nullable : SET not_null 
            { 
            $return = { is_nullable => 0 } 
            }
            | DROP not_null
            { 
            $return = { is_nullable => 1 } 
            }
    
        not_null : /not/i /null/i
    
        not : /not/i
    
        add_column : ADD COLUMN(?)
    
        alter_table : ALTER TABLE ONLY(?)
    
        alter_sequence : ALTER SEQUENCE 
    
        drop_column : DROP COLUMN(?)
    
        alter_column : ALTER COLUMN(?)
    
        rename_column : /rename/i COLUMN(?)
    
        restrict_or_cascade : /restrict/i | 
            /cascade/i
    
        # Handle functions that can be called
        select : SELECT select_function ';' 
            { 1 }
    
        # Read the setval function but don't do anything with it because this parser
        # isn't handling sequences
        select_function : schema_qualification(?) /setval/i '(' VALUE /,/ VALUE /,/ /(true|false)/i ')' 
            { 1 }
    
        # Skipping all COPY commands
        copy : COPY WORD /[^;]+/ ';' { 1 }
            { 1 }
    
        # The "\." allows reading in from STDIN but this isn't needed for schema
        # creation, so it is skipped.
        readin_symbol : '\.'
            {1}
    
        #
        # End basically useless stuff. - ky
        #
    
        create_table : CREATE TABLE
    
        create_index : CREATE /index/i
    
        default_val  : DEFAULT /(\d+|'[^']*'|\w+\(.*\))|\w+/
            { 
            my $val =  defined $item[2] ? $item[2] : '';
            $val    =~ s/^'|'$//g; 
            $return =  {
                supertype => 'constraint',
                type      => 'default',
                value     => $val,
            }
            }
            | /null/i
            { 
            $return =  {
                supertype => 'constraint',
                type      => 'default',
                value     => 'NULL',
            }
            }
    
        name_with_opt_paren : NAME parens_value_list(s?)
            { $item[2][0] ? "$item[1]($item[2][0][0])" : $item[1] }
    
        unique : /unique/i { 1 }
    
        key : /key/i | /index/i
    
        table_option : /inherits/i '(' name_with_opt_quotes(s /,/) ')'
            { 
            $return = { type => 'inherits', table_name => $item[3] }
            }
            |
            /with(out)? oids/i
            {
            $return = { type => $item[1] =~ /out/i ? 'without_oids' : 'with_oids' }
            }
    
        ADD : /add/i
    
        ALTER : /alter/i
    
        CREATE : /create/i
    
        ONLY : /only/i
    
        DEFAULT : /default/i
    
        DROP : /drop/i
    
        COLUMN : /column/i
    
        TABLE : /table/i
    
        VIEW : /view/i
    
        SCHEMA : /schema/i
    
        SEMICOLON : /\s*;\n?/
    
        SEQUENCE : /sequence/i
    
        SELECT : /select/i
    
        COPY : /copy/i
    
        INTEGER : /\d+/
    
        WORD : /\w+/
    
        DIGITS : /\d+/
    
        COMMA : ','
    
        SET : /set/i
    
        NAME    : "`" /\w+/ "`"
            { $item[2] }
            | /\w+/
            { $item[1] }
            | /[\$\w]+/
            { $item[1] }
    
        VALUE   : /[-+]?\.?\d+(?:[eE]\d+)?/
            { $item[1] }
            | /'.*?'/   # XXX doesn't handle embedded quotes
            { $item[1] }
            | /null/i
            { 'NULL' }
            !;
    }
}
