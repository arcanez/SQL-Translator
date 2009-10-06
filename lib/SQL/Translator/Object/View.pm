use MooseX::Declare;
class SQL::Translator::Object::View extends SQL::Translator::Object::Table {
    use MooseX::Types::Moose qw(HashRef Str);
    use SQL::Translator::Types qw(Column Schema);
    
    has 'sql' => (
        is => 'rw',
        isa => Str,
    );

    around add_column(Column $column does coerce) {
        die "Can't use column name " . $column->name if $self->exists_column($column->name) || $column->name eq '';
        $column->table($self);
        return $self->$orig($column->name, $column);
    }
}
