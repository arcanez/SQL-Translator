use MooseX::Declare;
class SQL::Translator::Object::PrimaryKey {
    extends 'SQL::Translator::Object::Index';

    has '+type' => (
        default => 'PRIMARY_KEY',
    );
}
