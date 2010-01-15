use MooseX::Declare;
class SQL::Translator::Object::View extends SQL::Translator::Object::Table {
    use MooseX::Types::Moose qw(HashRef Str);
    use SQL::Translator::Types qw(Column Schema);
    
    has 'sql' => (
        is => 'rw',
        isa => Str,
    );
}
