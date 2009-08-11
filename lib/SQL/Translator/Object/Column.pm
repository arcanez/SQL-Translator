use MooseX::Declare;
class SQL::Translator::Object::Column {
    use MooseX::Types::Moose qw(Bool HashRef Int Maybe Str);
    use SQL::Translator::Types qw(Trigger);
    extends 'SQL::Translator::Object';
    
    has 'name' => (
        is => 'rw',
        isa => Str,
        required => 1
    );
    
    has 'data_type' => (
        is => 'rw',
        isa => Str,
        required => 1
    );

    has 'sql_data_type' => (
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
    
    has 'default_value' => (
        is => 'rw',
        isa => Maybe[Str],
    );
    
    has 'comments' => (
        is => 'rw',
        isa => Maybe[Str],
    );

    has 'is_auto_increment' => (
        is => 'rw',
        isa => Bool,
        required => 1,
        default => 0
    );

    has 'is_primary_key' => (
        is => 'rw',
        isa => Bool,
        default => 0
    );
    
    has 'trigger' => (
        is => 'rw',
        isa => Trigger,
    );

    has 'extra' => (
        is => 'rw',
        isa => HashRef,
        auto_deref => 1,
    );
}
