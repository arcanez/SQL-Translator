use MooseX::Declare;
role SQL::Translator::Parser::DDL::DBIx::Class {
    use MooseX::Types::Moose qw();
    use MooseX::MultiMethods;
    use SQL::Translator::Constants qw(:sqlt_types :sqlt_constants);
    use aliased 'SQL::Translator::Object::Column';
    use aliased 'SQL::Translator::Object::Constraint';
    use aliased 'SQL::Translator::Object::ForeignKey';
    use aliased 'SQL::Translator::Object::Index';
    use aliased 'SQL::Translator::Object::PrimaryKey';
    use aliased 'SQL::Translator::Object::Procedure';
    use aliased 'SQL::Translator::Object::Schema';
    use aliased 'SQL::Translator::Object::Table';
    use aliased 'SQL::Translator::Object::View';

    multi method parse(Schema $data) { $data }

    multi method parse(Str $data) {
    }
}
