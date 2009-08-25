use MooseX::Declare;
class SQL::Translator::Object::Procedure extends SQL::Translator::Object {
    use MooseX::Types::Moose qw(ArrayRef Str);
    
    has 'name' => (
        is => 'rw',
        isa => Str,
        required => 1
    );
    
    has 'sql' => (
        is => 'rw',
        isa => Str,
        required => 1
    );
    
    has 'parameters' => (
        is => 'rw',
        isa => ArrayRef,
    );
    
    has 'owner' => (
        is => 'rw',
        isa => Str,
        required => 1
    );
}
