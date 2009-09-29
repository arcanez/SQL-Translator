use MooseX::Declare;
class SQL::Translator::Object::Procedure extends SQL::Translator::Object {
    use MooseX::Types::Moose qw(ArrayRef Str);
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
        traits => ['Array'],
        isa => ArrayRef,
        handles => {
            _parameters           => 'elements',
            add_parameter         => 'push',
            remove_last_parameter => 'pop',
        },
        default => sub { [] },

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
