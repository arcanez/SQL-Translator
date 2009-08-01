use MooseX::Declare;
class SQL::Translator::Parser {
    use MooseX::Types::Moose qw(Str);
    use SQL::Translator::Types qw(DBIHandle);
    use aliased 'SQL::Translator::Object::Schema';

    my $apply_role_dbi = sub {
        my $self = shift;
        my $role = __PACKAGE__ . '::DBI';
        Class::MOP::load_class($role);
        $role->meta->apply($self);
        $self->_subclass();
    };

    my $apply_role_ddl = sub {
        my $self = shift;
        my $role =  __PACKAGE__ . '::DDL';
        Class::MOP::load_class($role);
        $role->meta->apply($self);
        $self->_subclass();
    };

    has 'dbh' => (
        isa => DBIHandle,
        is => 'ro',
        predicate => 'has_dbh',
        trigger => $apply_role_dbi,
    );

    has 'filename' => (
        isa => Str,
        is => 'ro',
        predicate => 'has_ddl',
        trigger => $apply_role_ddl,
    );

    has 'type' => (
        isa => Str,
        is => 'ro',
    );

    method parse {
        my $schema = Schema->new({ name => $self->schema_name });
        $self->_add_tables($schema);
        $schema;
    }
}
