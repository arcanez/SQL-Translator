use MooseX::Declare;
role SQL::Translator::Producer::XML {
use MooseX::Types::Moose qw(HashRef);
use IO::Scalar;
#use SQL::Translator::Utils qw(header_comment debug);
BEGIN {
    # Will someone fix XML::Writer already?
    local $^W = 0;
    require XML::Writer;
    import XML::Writer;
}

# Which schema object attributes (methods) to write as xml elements rather than
# as attributes. e.g. <comments>blah, blah...</comments>
my @MAP_AS_ELEMENTS = qw/sql comments action extra/;

my $Namespace = 'http://sqlfairy.sourceforge.net/sqlfairy.xml';
my $Name      = 'sqlf';
my $PArgs     = {};
my $no_comments;

method produce {
    my $translator  = $self;
    my $schema      = $translator->schema;
    $no_comments    = $translator->no_comments;
#    $PArgs          = $translator->producer_args;
    my $newlines    = defined $PArgs->{newlines} ? $PArgs->{newlines} : 1;
    my $indent      = defined $PArgs->{indent}   ? $PArgs->{indent}   : 2;
    my $io          = IO::Scalar->new;

    # Setup the XML::Writer and set the namespace
    my $prefix = "";
    $prefix    = $Name            if $PArgs->{add_prefix};
    $prefix    = $PArgs->{prefix} if $PArgs->{prefix};
    my $xml         = XML::Writer->new(
        OUTPUT      => $io,
        NAMESPACES  => 1,
        PREFIX_MAP  => { $Namespace => $prefix },
        DATA_MODE   => $newlines,
        DATA_INDENT => $indent,
    );

    # Start the document
    $xml->xmlDecl('UTF-8');

#    $xml->comment(header_comment('', ''))
#      unless $no_comments;

    xml_obj($xml, $schema,
        { tag => "schema", methods => [qw/name database /], end_tag => 0 });
#        tag => "schema", methods => [qw/name database extra/], end_tag => 0 );

    #
    # Table
    #
    $xml->startTag( [ $Namespace => "tables" ] );
    for my $table ( $schema->get_tables ) {
#        debug "Table:",$table->name;
        xml_obj($xml, $table,
            { tag => "table",
             methods => [qw/name order/],
#             methods => [qw/name order extra/],
             end_tag => 0 }
         );

        #
        # Fields
        #
        xml_obj_children( $xml, $table,
            { tag   => 'field',
            methods =>[qw/
                name data_type size is_nullable default_value is_auto_increment
                is_primary_key is_foreign_key comments order
            /], }
#                is_primary_key is_foreign_key extra comments order
        );

        #
        # Indices
        #
        xml_obj_children( $xml, $table,
            { tag   => 'index',
            collection_tag => "indices",
            methods => [qw/name type fields options/], }
#            methods => [qw/name type fields options extra/],
        );

        #
        # Constraints
        #
        xml_obj_children( $xml, $table,
            { tag   => 'constraint',
#            methods => [qw/
#                name type fields reference_table reference_fields
#                on_delete on_update match_type expression options deferrable
#                extra
#            /],
             methods => [qw/name type expression options deferrable/], }
        );

        #
        # Comments
        #
        xml_obj_children( $xml, $table,
            { tag   => 'comment',
#            collection_tag => "comments",
            methods => [qw/
                comments
            /], }
        );

        $xml->endTag( [ $Namespace => 'table' ] );
    }
    $xml->endTag( [ $Namespace => 'tables' ] );

    #
    # Views
    #
    xml_obj_children( $xml, $schema,
        { tag   => 'view',
        methods => [qw/name sql fields/], }
#        methods => [qw/name sql fields order extra/],
    );

    #
    # Tiggers
    #
    xml_obj_children( $xml, $schema,
        { tag    => 'trigger',
        methods => [qw/name database_events action on_table perform_action_when fields order/], }
#        methods => [qw/name database_events action on_table perform_action_when fields order extra/], 
    );

    #
    # Procedures
    #
    xml_obj_children( $xml, $schema,
        { tag   => 'procedure',
        methods => [qw/name sql parameters owner comments order/], }
#        methods => [qw/name sql parameters owner comments order extra/],
    );

    $xml->endTag([ $Namespace => 'schema' ]);
    $xml->end;

    return $io;
}


#
# Takes and XML::Write object, Schema::* parent object, the tag name,
# the collection name and a list of methods (of the children) to write as XML.
# The collection name defaults to the name with an s on the end and is used to
# work out the method to get the children with. eg a name of 'foo' gives a
# collection of foos and gets the members using ->get_foos.
#
#sub xml_obj_children {
method xml_obj_children($xml: $parent, HashRef $args?) {
#    my ($xml,$parent) = (shift,shift);

#    my %args = @_;
    my ($name,$collection_name,$methods)
        = @{$args}{qw/tag collection_tag methods/};
    $collection_name ||= "${name}s";

    my $meth;
    if ( $collection_name eq 'comments' ) {
      $meth = 'comments';
    } else {
      $meth = "get_$collection_name";
    }

    my @kids = $parent->$meth;
    #@kids || return;
    $xml->startTag( [ $Namespace => $collection_name ] );

    for my $obj ( @kids ) {
        if ( $collection_name eq 'comments' ){
            $xml->dataElement( [ $Namespace => 'comment' ], $obj );
        } else {
            xml_obj($xml, $obj,
                { tag     => "$name",
                end_tag => 1,
                methods => $methods, }
            );
        }
    }
    $xml->endTag( [ $Namespace => $collection_name ] );
}

#
# Takes an XML::Writer, Schema::* object and list of method names
# and writes the obect out as XML. All methods values are written as attributes
# except for the methods listed in @MAP_AS_ELEMENTS which get written as child
# data elements.
#
# The attributes/tags are written in the same order as the method names are
# passed.
#
# TODO
# - Should the Namespace be passed in instead of global? Pass in the same
#   as Writer ie [ NS => TAGNAME ]
#
my $elements_re = join("|", @MAP_AS_ELEMENTS);
$elements_re = qr/^($elements_re)$/;
#sub xml_obj {
method xml_obj($xml: $obj, HashRef $args?) {
#    my ($xml, $obj, %args) = @_;
    my $tag                = $args->{'tag'}              || '';
    my $end_tag            = $args->{'end_tag'}          || '';
    my @meths              = @{ $args->{'methods'} };
    my $empty_tag          = 0;

    # Use array to ensure consistant (ie not hash) ordering of attribs
    # The order comes from the meths list passed in.
    my @tags;
    my @attr;
    foreach ( grep { defined $obj->$_ } @meths ) {
        my $what = m/$elements_re/ ? \@tags : \@attr;
        my $val = $_ eq 'extra'
            ? { $obj->$_ }
            : $obj->$_;
        $val = ref $val eq 'ARRAY' ? join(',', @$val) : $val;
        push @$what, $_ => $val;
    };
    my $child_tags = @tags;
    $end_tag && !$child_tags
        ? $xml->emptyTag( [ $Namespace => $tag ], @attr )
        : $xml->startTag( [ $Namespace => $tag ], @attr );
    while ( my ($name,$val) = splice @tags,0,2 ) { warn "NAME: $name, $val";
        if ( ref $val eq 'HASH' ) {
             $xml->emptyTag( [ $Namespace => $name ],
                 map { ($_, $val->{$_}) } sort keys %$val );
        }
        else {
            $xml->dataElement( [ $Namespace => $name ], $val );
        }
    }
    $xml->endTag( [ $Namespace => $tag ] ) if $child_tags && $end_tag;
}
}
