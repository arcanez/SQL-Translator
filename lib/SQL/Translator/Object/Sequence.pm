use MooseX::Declare;
class SQL::Translator::Object::Sequence extends SQL::Translator::Object {
    use MooseX::Types::Moose qw(Str);
    
    has 'name' => (
        is => 'ro',
        isa => Str,
        required => 1
    );
}
