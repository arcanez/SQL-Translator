use MooseX::Declare;
class SQL::Translator::Parser {
    use MooseX::Types::Moose qw(Str);
    use SQL::Translator::Types qw(DBIHandle);
    use aliased 'SQL::Translator::Object::Schema';

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
        isa => Str,
        is => 'ro',
        predicate => 'has_type',
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

    method parse {
        my $schema = Schema->new({ name => $self->schema_name });
        $self->_add_tables($schema);
        $schema;
    }
}
