use MooseX::Declare;
class SQL::Translator::Object::View extends SQL::Translator::Object::Table {
    use MooseX::Types::Moose qw(Str);
    
    has 'sql' => (
        is => 'rw',
        isa => Str,
    );
}
