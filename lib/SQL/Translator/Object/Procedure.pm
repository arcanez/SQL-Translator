use MooseX::Declare;
class SQL::Translator::Object::Procedure extends SQL::Translator::Object {
    use MooseX::Types::Moose qw(ArrayRef Str);
    use MooseX::AttributeHelpers;
    use MooseX::MultiMethods;
    
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
    
    has '_parameters' => (
        metaclass => 'Collection::Array',
        is => 'rw',
        isa => ArrayRef,
        provides => {
            push => 'add_parameter',
            pop  => 'remove_last_parameter',
        },
        default => sub { [] },
        auto_deref => 1,

    );
    
    has 'owner' => (
        is => 'rw',
        isa => Str,
        required => 1
    );

    multi method parameters(Str $parameter) { $self->add_parameter($parameter) }
    multi method parameters(ArrayRef $parameter) { $self->add_parameter($parameter) }
    multi method parameters(Any $) { wantarray ? @{$self->_parameters} : $self->_parameters }
}
