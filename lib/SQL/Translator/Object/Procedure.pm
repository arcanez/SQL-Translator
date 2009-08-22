use MooseX::Declare;
class SQL::Translator::Object::Procedure {
    use MooseX::Types::Moose qw(ArrayRef Int Str);
    extends 'SQL::Translator::Object';
    
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
