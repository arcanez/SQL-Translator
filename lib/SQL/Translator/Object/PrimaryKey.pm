use MooseX::Declare;
class SQL::Translator::Object::PrimaryKey extends (SQL::Translator::Object::Index, SQL::Translator::Object::Constraint) {
    has '+type' => (
        default => 'PRIMARY KEY',
    );
}
