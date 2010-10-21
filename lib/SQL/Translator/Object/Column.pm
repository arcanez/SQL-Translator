use MooseX::Declare;
class SQL::Translator::Object::Column extends SQL::Translator::Object is dirty {
    use MooseX::Types::Moose qw(Int Maybe ScalarRef Str);
    use MooseX::MultiMethods;
    use SQL::Translator::Types qw(Bit Constraint Table Trigger);
    use Tie::IxHash;
    clean;

    use overload
        '""'     => sub { shift->name },
        'bool'   => sub { $_[0]->name || $_[0] },
        fallback => 1,
    ;

    has 'table' => (
        is => 'rw',
        isa => Table,
        weak_ref => 1,
    );
    
    has 'name' => (
        is => 'rw',
        isa => Str,
        required => 1,
#        trigger => sub { my ($self, $new, $old) = @_; if (defined $old) { $self->table->remove_column($old); $self->table->add_column($self) } }
    );
    
    has 'data_type' => (
        is => 'rw',
        isa => Str,
        required => 1,
        default => '',
        trigger => sub { my ($self, $new, $old) = @_; $self->is_auto_increment(1) if $new =~ /^serial$/i; },
    );

    has 'sql_data_type' => (
        is => 'rw',
        isa => Int,
        required => 1,
        default => 0
    );
    
    has 'length' => (
        is => 'rw',
        isa => Int,
        default => 0,
        lazy => 1,
        predicate => 'has_length',
    );

    has 'precision' => (
        is => 'rw',
        isa => Int,
        default => 0,
        lazy => 1,
        predicate => 'has_precision',
    );
    
    has 'is_nullable' => (
        is => 'rw',
        isa => Bit,
        required => 1,
        default => 1,
    );

    has 'is_unique' => (
        is => 'rw',
        isa => Bit,
        default => 0,
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
        isa => Bit,
        default => 0
    );

    has 'is_foreign_key' => (
        is => 'rw',
        isa => Bit,
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

    has '_order' => (
        is => 'rw',
        isa => Int,
    );

    around size(@args) {
        $self->$orig(@args) if @args;
        my @sizes = $self->$orig;
        return wantarray ? @sizes
                         : join ',', @sizes;
    }

    method full_name { $self->table->name . '.' . $self->name }
    method schema { $self->table->schema }

    before name($name?) { die "Can't use column name $name" if defined $name && $self->table->exists_column($name) && $name ne $self->name }

    multi method size(Str $size) { my ($length, $precision) = split /,/, $size; $self->length($length); $self->precision($precision) if $precision; $self->size }
    multi method size(Int $length, Int $precision) { $self->length($length); $self->precision($precision); $self->size }
    multi method size(ArrayRef $size) { $self->length($size->[0]); $self->precision($size->[1]) if @$size == 2; $self->size }

    multi method size {
        return $self->has_precision
        ? wantarray
            ? ($self->length, $self->precision) 
            : join ',', ($self->length, $self->precision)
        : $self->length;
    }

    multi method order(Int $order) { $self->_order($order); }
    multi method order {
        my $order = $self->_order;
        unless (defined $order && $order) {
            my $columns = Tie::IxHash->new( map { $_->name => $_ } $self->table->get_columns );
            $order = $columns->Indices($self->name) || 0; $order++;
            $self->_order($order);
        }
        return $order;
    }

    method BUILD(HashRef $args) {
        die "Cannot use column name $args->{name}" if $args->{name} eq '';
        $self->size($args->{size}) if $args->{size};
    }
}
