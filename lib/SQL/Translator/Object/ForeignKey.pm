use MooseX::Declare;
class SQL::Translator::Object::ForeignKey {
    use SQL::Translator::Types qw(Index PrimaryKey);
    extends 'SQL::Translator::Object::Constraint';
    
    has '+type' => (
        default => 'FOREIGN_KEY',
    );
    
    has 'references' => (
        isa => PrimaryKey | Index,
        is => 'rw',
        required => 1,
    );
}
