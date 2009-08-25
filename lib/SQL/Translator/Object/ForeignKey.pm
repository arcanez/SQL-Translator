use MooseX::Declare;
class SQL::Translator::Object::ForeignKey extends SQL::Translator::Object::Constraint {
    use MooseX::Types::Moose qw(ArrayRef Maybe Undef Str);
    
    has '+type' => (
        default => 'FOREIGN KEY',
    );
    
    has 'on_delete' => (
        isa => Maybe[Str],
        is => 'rw',
    );

    has 'on_update' => (
        isa => Maybe[Str],
        is => 'rw',
    );

    has 'reference_table' => (
        isa => Str,
        is => 'rw',
    );
}
