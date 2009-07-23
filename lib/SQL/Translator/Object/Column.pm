use MooseX::Declare;
class SQL::Translator::Object::Column {
    use MooseX::Types::Moose qw(Bool Int Maybe Str);
    use SQL::Translator::Types qw(Trigger);
    extends 'SQL::Translator::Object';
    
    has 'name' => (
        is => 'rw',
        isa => Str,
        required => 1
    );
    
    has 'data_type' => (
        is => 'rw',
        isa => Int,
        required => 1
    );
    
    has 'size' => (
        is => 'rw',
        isa => Maybe[Int],
        required => 1
    );
    
    has 'is_nullable' => (
        is => 'rw',
        isa => Bool,
        required => 1,
        default => 1
    );
    
    has 'is_auto_increment' => (
        is => 'rw',
        isa => Bool,
        required => 1,
        default => 0
    );
    
    has 'default_value' => (
        is => 'rw',
        isa => Maybe[Str],
    );
    
    has 'remarks' => (
        is => 'rw',
        isa => Maybe[Str],
    );
    
    has 'trigger' => (
        is => 'rw',
        isa => Trigger,
    );
}
