use MooseX::Declare;
class SQL::Translator::Object {
    use Tie::IxHash;
    use MooseX::MultiMethods;
    use MooseX::Types::Moose qw(Any ArrayRef Str);

    has '_comments' => (
        metaclass => 'Collection::Array',
        is => 'rw',
        isa => ArrayRef,
        provides => {
            push => 'add_comment',
            pop  => 'remove_last_comment',
        },
        default => sub { [] },
        auto_deref => 1,
    );

    multi method comments(Str $comment) { $self->add_comment($comment) }
    multi method comments(ArrayRef $comment) { $self->add_comment($comment) }
    multi method comments(Any $) { return wantarray ? @{$self->_comments} : join "\n", $self->_comments }
}
