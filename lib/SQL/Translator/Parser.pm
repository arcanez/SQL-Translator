use MooseX::Declare;
class SQL::Translator::Parser {
    use MooseX::Types::Moose qw(Maybe Str);
    use SQL::Translator::Types qw(DBIHandle Translator);

    has 'dbh' => (
        isa => DBIHandle,
        is => 'ro',
        predicate => 'has_dbh',
    );

    has 'filename' => (
        isa => Str,
        is => 'ro',
        predicate => 'has_ddl',
    );

    has 'type' => (
        isa => Maybe[Str],
        is => 'ro',
        predicate => 'has_type',
    );

    has 'translator' => (
        isa => Translator,
        is => 'ro',
        weak_ref => 1,
        required => 1,
        handles => [ qw(schema) ],
    );

    method BUILD(@) {
        my $role = __PACKAGE__;
        if ($self->has_dbh) {
            $role .= '::DBI';
        } elsif ($self->has_type || $self->has_ddl) {
            $role .= '::DDL';
        }
        Class::MOP::load_class($role);
        $role->meta->apply($self);
        $self->_subclass();
    }
}
