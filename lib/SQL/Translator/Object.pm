use MooseX::Declare;
class SQL::Translator::Object {
    use Tie::IxHash;
    use MooseX::MultiMethods;
    use MooseX::Types::Moose qw(Any ArrayRef HashRef Str);

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

    has '_options' => (
        metaclass => 'Collection::Array',
        is => 'rw',
        isa => ArrayRef,
        provides => {
            push => 'add_option',
            pop  => 'remove_last_option',
        },
        default => sub { [] },
        auto_deref => 1,
    );

    has '_extra' => (
        metaclass => 'Collection::Hash',
        is => 'rw',
        isa => HashRef,
        provides => {
            exists => 'exists_extra',
            keys   => 'extra_ids',
            values => 'get_extras',
            get    => 'get_extra',
            set    => 'add_extra',
        },
        default => sub { {} },
        auto_deref => 1,
    );

    multi method comments(Str $comment) { $self->add_comment($comment) }
    multi method comments(ArrayRef $comment) { $self->add_comment($comment) }
    multi method comments(Any $) { wantarray ? @{$self->_comments} : join "\n", $self->_comments }

    multi method options(Str $option) { $self->add_option($option) }
    multi method options(ArrayRef $option) { $self->add_option($option) if scalar @$option }
    multi method options(Any $) { wantarray ? @{$self->_options} : $self->_options }

    multi method extra(Str $extra) { $self->get_extra($extra) }
    multi method extra(HashRef $extra) { $self->_extra($extra) }
    multi method extra(Any $) { wantarray ? %{$self->_extra} : $self->_extra }
}
