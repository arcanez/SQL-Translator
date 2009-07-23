use MooseX::Declare;
class SQL::Translator::Object::Trigger {
    use MooseX::Types::Moose qw(Str);
    use SQL::Translator::Types qw();
    extends 'SQL::Translator::Object';
    
    has 'name' => (
        is => 'ro',
        isa => Str,
        required => 1
    );
}
