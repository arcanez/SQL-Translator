use MooseX::Declare;
class SQL::Translator::Object::PrimaryKey {
    extends qw(SQL::Translator::Object::Index SQL::Translator::Object::Constraint);

    has '+type' => (
        default => 'PRIMARY KEY',
    );
}
