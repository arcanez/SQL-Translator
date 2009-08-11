role SQL::Translator::Grammar::MySQL {
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
        { 
            my ( $database_name, %tables, $table_order, @table_comments, %views,
                $view_order, %procedures, $proc_order );
            my $delimiter = ';';
        }
        
        #
        # The "eofile" rule makes the parser fail if any "statement" rule
        # fails.  Otherwise, the first successful match by a "statement" 
        # won't cause the failure needed to know that the parse, as a whole,
        # failed. -ky
        #
        startrule : statement(s) eofile { 
            { 
                database_name => $database_name, 
                tables        => \%tables, 
                views         => \%views, 
                procedures    => \%procedures,
            } 
        }
        
        eofile : /^\Z/
        
        statement : comment
            | use
            | set
            | drop
            | create
            | alter
            | insert
            | delimiter
            | empty_statement
            | <error>
        
        use : /use/i WORD "$delimiter"
            {
                $database_name = $item[2];
                @table_comments = ();
            }
        
        set : /set/i /[^;]+/ "$delimiter"
            { @table_comments = () }
        
        drop : /drop/i TABLE /[^;]+/ "$delimiter"
        
        drop : /drop/i WORD(s) "$delimiter"
            { @table_comments = () }
        
        string :
          # MySQL strings, unlike common SQL strings, can be double-quoted or 
          # single-quoted, and you can escape the delmiters by doubling (but only the 
          # delimiter) or by backslashing.
        
           /'(\\.|''|[^\\\'])*'/ |
           /"(\\.|""|[^\\\"])*"/
          # For reference, std sql str: /(?:(?:\')(?:[^\']*(?:(?:\'\')[^\']*)*)(?:\'))//
        
        nonstring : /[^;\'"]+/
        
        statement_body : string | nonstring
        
        insert : /insert/i  statement_body(s?) "$delimiter"
        
        delimiter : /delimiter/i /[\S]+/
            { $delimiter = $item[2] }
        
        empty_statement : "$delimiter"
        
        alter : ALTER TABLE table_name alter_specification(s /,/) "$delimiter"
            {
                my $table_name                       = $item{'table_name'};
            die "Cannot ALTER table '$table_name'; it does not exist"
                unless $tables{ $table_name };
                for my $definition ( @{ $item[4] } ) { 
                $definition->{'extra'}->{'alter'} = 1;
                push @{ $tables{ $table_name }{'constraints'} }, $definition;
            }
            }
        
        alter_specification : ADD foreign_key_def
            { $return = $item[2] }
        
        create : CREATE /database/i WORD "$delimiter"
            { @table_comments = () }
        
        create : CREATE TEMPORARY(?) TABLE opt_if_not_exists(?) table_name '(' create_definition(s /,/) /(,\s*)?\)/ table_option(s?) "$delimiter"
            { 
                my $table_name                       = $item{'table_name'};
                $tables{ $table_name }{'order'}      = ++$table_order;
                $tables{ $table_name }{'table_name'} = $table_name;
        
                if ( @table_comments ) {
                    $tables{ $table_name }{'comments'} = [ @table_comments ];
                    @table_comments = ();
                }
        
                my $i = 1;
                for my $definition ( @{ $item[7] } ) {
                    if ( $definition->{'supertype'} eq 'field' ) {
                        my $field_name = $definition->{'name'};
                        $tables{ $table_name }{'fields'}{ $field_name } = 
                            { %$definition, order => $i };
                        $i++;
                
                        if ( $definition->{'is_primary_key'} ) {
                            push @{ $tables{ $table_name }{'constraints'} },
                                {
                                    type   => 'primary_key',
                                    fields => [ $field_name ],
                                }
                            ;
                        }
                    }
                    elsif ( $definition->{'supertype'} eq 'constraint' ) {
                        push @{ $tables{ $table_name }{'constraints'} }, $definition;
                    }
                    elsif ( $definition->{'supertype'} eq 'index' ) {
                        push @{ $tables{ $table_name }{'indices'} }, $definition;
                    }
                }
        
                if ( my @options = @{ $item{'table_option(s?)'} } ) {
                    for my $option ( @options ) {
                        my ( $key, $value ) = each %$option;
                        if ( $key eq 'comment' ) {
                            push @{ $tables{ $table_name }{'comments'} }, $value;
                        }
                        else {
                            push @{ $tables{ $table_name }{'table_options'} }, $option;
                        }
                    }
                }
        
                1;
            }
        
        opt_if_not_exists : /if not exists/i
        
        create : CREATE UNIQUE(?) /(index|key)/i index_name /on/i table_name '(' field_name(s /,/) ')' "$delimiter"
            {
                @table_comments = ();
                push @{ $tables{ $item{'table_name'} }{'indices'} },
                    {
                        name   => $item[4],
                        type   => $item[2][0] ? 'unique' : 'normal',
                        fields => $item[8],
                    }
                ;
            }
        
        create : CREATE /trigger/i NAME not_delimiter "$delimiter"
            {
                @table_comments = ();
            }
        
        create : CREATE PROCEDURE NAME not_delimiter "$delimiter"
            {
                @table_comments = ();
                my $func_name = $item[3];
                my $owner = '';
                my $sql = "$item[1] $item[2] $item[3] $item[4]";
                
                $procedures{ $func_name }{'order'}  = ++$proc_order;
                $procedures{ $func_name }{'name'}   = $func_name;
                $procedures{ $func_name }{'owner'}  = $owner;
                $procedures{ $func_name }{'sql'}    = $sql;
            }
        
        PROCEDURE : /procedure/i
            | /function/i
        
        create : CREATE replace(?) algorithm(?) /view/i NAME not_delimiter "$delimiter"
            {
                @table_comments = ();
                my $view_name = $item[5];
                my $sql = join(q{ }, grep { defined and length } $item[1], $item[2]->[0], $item[3]->[0])
                    . " $item[4] $item[5] $item[6]";
                
                # Hack to strip database from function calls in SQL
                $sql =~ s#`\w+`\.(`\w+`\()##g;
                
                $views{ $view_name }{'order'}  = ++$view_order;
                $views{ $view_name }{'name'}   = $view_name;
                $views{ $view_name }{'sql'}    = $sql;
            }
        
        replace : /or replace/i
        
        algorithm : /algorithm/i /=/ WORD
            {
                $return = "$item[1]=$item[3]";
            }
        
        not_delimiter : /.*?(?=$delimiter)/is
        
        create_definition : constraint 
            | index
            | field
            | comment
            | <error>
        
        comment : /^\s*(?:#|-{2}).*\n/ 
            { 
                my $comment =  $item[1];
                $comment    =~ s/^\s*(#|--)\s*//;
                $comment    =~ s/\s*$//;
                $return     = $comment;
            }
        
        comment : /\/\*/ /.*?\*\//s
            {
                my $comment = $item[2];
                $comment = substr($comment, 0, -2);
                $comment    =~ s/^\s*|\s*$//g;
                $return = $comment;
            }
            
        field_comment : /^\s*(?:#|-{2}).*\n/ 
            { 
                my $comment =  $item[1];
                $comment    =~ s/^\s*(#|--)\s*//;
                $comment    =~ s/\s*$//;
                $return     = $comment;
            }
        
        
        field_comment2 : /comment/i /'.*?'/
            {
                my $comment = $item[2];
                $comment    =~ s/^'//;
                $comment    =~ s/'$//;
                $return     = $comment;
            }
        
        blank : /\s*/
        
        field : field_comment(s?) field_name data_type field_qualifier(s?) field_comment2(?) reference_definition(?) on_update(?) field_comment(s?)
            { 
                my %qualifiers  = map { %$_ } @{ $item{'field_qualifier(s?)'} || [] };
                if ( my @type_quals = @{ $item{'data_type'}{'qualifiers'} || [] } ) {
                    $qualifiers{ $_ } = 1 for @type_quals;
                }
        
                my $null = defined $qualifiers{'not_null'} 
                           ? $qualifiers{'not_null'} : 1;
                delete $qualifiers{'not_null'};
        
                my @comments = ( @{ $item[1] }, @{ $item[5] }, @{ $item[8] } );
        
                $return = { 
                    supertype   => 'field',
                    name        => $item{'field_name'}, 
                    data_type   => $item{'data_type'}{'type'},
                    size        => $item{'data_type'}{'size'},
                    list        => $item{'data_type'}{'list'},
                    null        => $null,
                    constraints => $item{'reference_definition(?)'},
                    comments    => [ @comments ],
                    %qualifiers,
                } 
            }
            | <error>
        
        field_qualifier : not_null
            { 
                $return = { 
                     null => $item{'not_null'},
                } 
            }
        
        field_qualifier : default_val
            { 
                $return = { 
                     default => $item{'default_val'},
                } 
            }
        
        field_qualifier : auto_inc
            { 
                $return = { 
                     is_auto_inc => $item{'auto_inc'},
                } 
            }
        
        field_qualifier : primary_key
            { 
                $return = { 
                     is_primary_key => $item{'primary_key'},
                } 
            }
        
        field_qualifier : unsigned
            { 
                $return = { 
                     is_unsigned => $item{'unsigned'},
                } 
            }
        
        field_qualifier : /character set/i WORD 
            {
                $return = {
                    'CHARACTER SET' => $item[2],
                }
            }
        
        field_qualifier : /collate/i WORD
            {
                $return = {
                    COLLATE => $item[2],
                }
            }
        
        field_qualifier : /on update/i CURRENT_TIMESTAMP
            {
                $return = {
                    'ON UPDATE' => $item[2],
                }
            }
        
        field_qualifier : /unique/i KEY(?)
            {
                $return = {
                    is_unique => 1,
                }
            }
        
        field_qualifier : KEY
            {
                $return = {
                    has_index => 1,
                }
            }
        
        reference_definition : /references/i table_name parens_field_list(?) match_type(?) on_delete(?) on_update(?)
            {
                $return = {
                    type             => 'foreign_key',
                    reference_table  => $item[2],
                    reference_fields => $item[3][0],
                    match_type       => $item[4][0],
                    on_delete        => $item[5][0],
                    on_update        => $item[6][0],
                }
            }
        
        match_type : /match full/i { 'full' }
            |
            /match partial/i { 'partial' }
        
        on_delete : /on delete/i reference_option
            { $item[2] }
        
        on_update : 
            /on update/i 'CURRENT_TIMESTAMP'
            { $item[2] }
            |
            /on update/i reference_option
            { $item[2] }
        
        reference_option: /restrict/i | 
            /cascade/i   | 
            /set null/i  | 
            /no action/i | 
            /set default/i
            { $item[1] }  
        
        index : normal_index
            | fulltext_index
            | spatial_index
            | <error>
        
        table_name   : NAME
        
        field_name   : NAME
        
        index_name   : NAME
        
        data_type    : WORD parens_value_list(s?) type_qualifier(s?)
            { 
                my $type = $item[1];
                my $size; # field size, applicable only to non-set fields
                my $list; # set list, applicable only to sets (duh)
        
                if ( uc($type) =~ /^(SET|ENUM)$/ ) {
                    $size = undef;
                    $list = $item[2][0];
                }
                else {
                    $size = $item[2][0];
                    $list = [];
                }
        
        
                $return        = { 
                    type       => $type,
                    size       => $size,
                    list       => $list,
                    qualifiers => $item[3],
                } 
            }
        
        parens_field_list : '(' field_name(s /,/) ')'
            { $item[2] }
        
        parens_value_list : '(' VALUE(s /,/) ')'
            { $item[2] }
        
        type_qualifier : /(BINARY|UNSIGNED|ZEROFILL)/i
            { lc $item[1] }
        
        field_type   : WORD
        
        create_index : /create/i /index/i
        
        not_null     : /not/i /null/i 
            { $return = 0 }
            |
            /null/i
            { $return = 1 }
        
        unsigned     : /unsigned/i { $return = 0 }
        
        #default_val  : /default/i /(?:')?[\s\w\d:.-]*(?:')?/ 
        #    { 
        #        $item[2] =~ s/'//g; 
        #        $return  =  $item[2];
        #    }
        
        default_val : 
            /default/i 'CURRENT_TIMESTAMP'
            {
                $return =  \$item[2];
            }
            |
            /default/i /'(?:.*?(?:\\'|''))*.*?'|(?:')?[\w\d:.-]*(?:')?/
            {
                $item[2] =~ s/^\s*'|'\s*$//g;
                $return  =  $item[2];
            }
        
        auto_inc : /auto_increment/i { 1 }
        
        primary_key : /primary/i /key/i { 1 }
        
        constraint : primary_key_def
            | unique_key_def
            | foreign_key_def
            | <error>
        
        foreign_key_def : foreign_key_def_begin parens_field_list reference_definition
            {
                $return              =  {
                    supertype        => 'constraint',
                    type             => 'foreign_key',
                    name             => $item[1],
                    fields           => $item[2],
                    %{ $item{'reference_definition'} },
                }
            }
        
        foreign_key_def_begin : /constraint/i /foreign key/i WORD
            { $return = $item[3] }
            |
            /constraint/i NAME /foreign key/i
            { $return = $item[2] }
            |
            /constraint/i /foreign key/i
            { $return = '' }
            |
            /foreign key/i WORD
            { $return = $item[2] }
            |
            /foreign key/i
            { $return = '' }
        
        primary_key_def : primary_key index_name(?) '(' name_with_opt_paren(s /,/) ')'
            { 
                $return       = { 
                    supertype => 'constraint',
                    name      => $item{'index_name(?)'}[0],
                    type      => 'primary_key',
                    fields    => $item[4],
                };
            }
        
        unique_key_def : UNIQUE KEY(?) index_name(?) '(' name_with_opt_paren(s /,/) ')'
            { 
                $return       = { 
                    supertype => 'constraint',
                    name      => $item{'index_name(?)'}[0],
                    type      => 'unique',
                    fields    => $item[5],
                } 
            }
        
        normal_index : KEY index_name(?) '(' name_with_opt_paren(s /,/) ')'
            { 
                $return       = { 
                    supertype => 'index',
                    type      => 'normal',
                    name      => $item{'index_name(?)'}[0],
                    fields    => $item[4],
                } 
            }
        
        fulltext_index : /fulltext/i KEY(?) index_name(?) '(' name_with_opt_paren(s /,/) ')'
            { 
                $return       = { 
                    supertype => 'index',
                    type      => 'fulltext',
                    name      => $item{'index_name(?)'}[0],
                    fields    => $item[5],
                } 
            }
        
        spatial_index : /spatial/i KEY(?) index_name(?) '(' name_with_opt_paren(s /,/) ')'
            { 
                $return       = { 
                    supertype => 'index',
                    type      => 'spatial',
                    name      => $item{'index_name(?)'}[0],
                    fields    => $item[5],
                } 
            }
        
        name_with_opt_paren : NAME parens_value_list(s?)
            { $item[2][0] ? "$item[1]($item[2][0][0])" : $item[1] }
        
        UNIQUE : /unique/i
        
        KEY : /key/i | /index/i
        
        table_option : /comment/i /=/ /'.*?'/
            {
                my $comment = $item[3];
                $comment    =~ s/^'//;
                $comment    =~ s/'$//;
                $return     = { comment => $comment };
            }
            | /(default )?(charset|character set)/i /\s*=?\s*/ WORD
            { 
                $return = { 'CHARACTER SET' => $item[3] };
            }
            | /collate/i WORD
            {
                $return = { 'COLLATE' => $item[2] }
            }
            | /union/i /\s*=\s*/ '(' table_name(s /,/) ')'
            { 
                $return = { $item[1] => $item[4] };
            }
            | WORD /\s*=\s*/ MAYBE_QUOTED_WORD
            {
                $return = { $item[1] => $item[3] };
            }
        
        MAYBE_QUOTED_WORD: /\w+/
                         | /'(\w+)'/
                         { $return = $1 }
                         | /"(\w+)"/
                         { $return = $1 }
        
        default : /default/i
        
        ADD : /add/i
        
        ALTER : /alter/i
        
        CREATE : /create/i
        
        TEMPORARY : /temporary/i
        
        TABLE : /table/i
        
        WORD : /\w+/
        
        DIGITS : /\d+/
        
        COMMA : ','
        
        BACKTICK : '`'
        
        DOUBLE_QUOTE: '"'
        
        NAME    : BACKTICK /[^`]+/ BACKTICK
            { $item[2] }
            | DOUBLE_QUOTE /[^"]+/ DOUBLE_QUOTE
            { $item[2] }
            | /\w+/
            { $item[1] }
        
        VALUE   : /[-+]?\.?\d+(?:[eE]\d+)?/
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
        
        CURRENT_TIMESTAMP : /current_timestamp(\(\))?/i
            | /now\(\)/i
            { 'CURRENT_TIMESTAMP' }
        !;
    }
}
