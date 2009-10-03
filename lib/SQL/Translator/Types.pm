use MooseX::Declare;
class SQL::Translator::Types {
    use MooseX::Types::Moose qw(ArrayRef CodeRef HashRef Int Maybe Str Undef);
    use MooseX::Types -declare, [qw(Column Constraint ForeignKey Index PrimaryKey Procedure Schema Sequence Table Trigger View
                                    Bit DBIHandle ColumnSize Parser Producer Translator)];
    
    class_type Column, { class => 'SQL::Translator::Object::Column' };
    class_type Constraint, { class => 'SQL::Translator::Object::Constraint' };
    class_type ForeignKey, { class => 'SQL::Translator::Object::ForeignKey' };
    class_type Index, { class => 'SQL::Translator::Object::Index' };
    class_type PrimaryKey, { class => 'SQL::Translator::Object::PrimaryKey' };
    class_type Procedure, { class => 'SQL::Translator::Object::Procedure' };
    class_type Schema, { class => 'SQL::Translator::Object::Schema' };
    class_type Sequence, { class=> 'SQL::Translator::Object::Sequence' };
    class_type Table, { class => 'SQL::Translator::Object::Table' };
    class_type Trigger, { class => 'SQL::Translator::Object::Trigger' };
    class_type View, { class => 'SQL::Translator::Object::View' };
    
    class_type Parser, { class => 'SQL::Translator::Parser' };
    class_type Producer, { class => 'SQL::Translator::Producer' };
    class_type Translator, { class => 'SQL::Translator' };

    coerce Column, from HashRef, via { SQL::Translator::Object::Column->new($_) };
    coerce Constraint, from HashRef, via { SQL::Translator::Object::Constraint->new($_) };
    coerce ForeignKey, from HashRef, via { SQL::Translator::Object::ForeignKey->new($_) };
    coerce Index, from HashRef, via { SQL::Translator::Object::Index->new($_) };
    coerce PrimaryKey, from HashRef, via { SQL::Translator::Object::PrimaryKey->new($_) };
    coerce Procedure, from HashRef, via { SQL::Translator::Object::Procedure->new($_) };
    coerce Schema, from HashRef, via { SQL::Translator::Object::Schema->new($_) };
    coerce Sequence, from HashRef, via { SQL::Translator::Object::Sequence->new($_) };
    coerce Table, from HashRef, via { SQL::Translator::Object::Table->new($_) };
    coerce Trigger, from HashRef, via { SQL::Translator::Object::Trigger->new($_) };
    coerce View, from HashRef, via { SQL::Translator::Object::View->new($_) };

    subtype Bit, as Int, where { $_ == 1 || $_ == 0 };
    coerce Bit,
        from Undef, via { 0 },
        from Str,  via { $_ eq '1' ? 1 : 0 };

    subtype ColumnSize, as ArrayRef[Int];
    coerce ColumnSize,
        from Int, via { [ $_ ] },
        from Str, via { [ split /,/ ] },
        from Undef, via { [ 0 ] };

    subtype DBIHandle, as 'DBI::db';
    
    coerce DBIHandle,
        from Str,
        via(\&_coerce_dbihandle_from_str),
        from ArrayRef,
        via(\&_coerce_dbihandle_from_arrayref);
        from CodeRef,
        via(\&_coerce_dbihandle_from_coderef);
    
    sub coerce_dbihandle_from_str { }
    sub coerce_dbihandle_from_arrayref { }
    sub coerce_dbihandle_from_coderef { }
    
}    
