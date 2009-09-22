use MooseX::Declare;
class SQL::Translator::Object::Column extends SQL::Translator::Object {
    use MooseX::Types::Moose qw(Bool Int Maybe ScalarRef Str);
    use MooseX::MultiMethods;
    use SQL::Translator::Types qw(Bit ColumnSize Constraint Table Trigger);

    has 'table' => (
        is => 'rw',
        isa => Table,
        required => 1,
        weak_ref => 1,
    );
    
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
        isa => ColumnSize,
        coerce => 1,
        auto_deref => 1,
        default => sub { [ 0 ] },
    );
    
    has 'is_nullable' => (
        is => 'rw',
        isa => Bit,
        required => 1,
        default => 1
    );
    
    has 'default_value' => (
        is => 'rw',
        isa => Maybe[ScalarRef|Str],
    );

    has 'is_auto_increment' => (
        is => 'rw',
        isa => Bit,
        required => 1,
        coerce => 1,
        default => 0
    );

    has 'is_primary_key' => (
        is => 'rw',
        isa => Bool,
        default => 0
    );

    has 'is_foreign_key' => (
        is => 'rw',
        isa => Bool,
        default => 0
    );

    has 'foreign_key_reference' => (
         is => 'rw',
         isa => Constraint,
    );
    
    has 'trigger' => (
        is => 'rw',
        isa => Trigger,
    );

    around size(@args) {
        $self->$orig(@args) if @args;
        my @sizes = $self->$orig;
        return wantarray ? @sizes
                         : join ',', @sizes;
    }

    method order { }
    method is_unique { }
}
