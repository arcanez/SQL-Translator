use MooseX::Declare;
class SQL::Translator::Object::Procedure {
    use namespace::autoclean;
    use Moose;
    use MooseX::Types::Moose qw(ArrayRef Int Str);
    use aliased 'SQL::Translator::Object::Schema';
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
    
    has 'comments' => (
        is => 'rw',
        isa => Str,
    );
    
    has 'schema' => (
        is => 'rw',
        isa => Schema,
        required => 1,
        default => sub { Schema->new }
    );
}
