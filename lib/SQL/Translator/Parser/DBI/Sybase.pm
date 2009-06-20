package SQL::Translator::Parser::DBI::Sybase;
use Moose;
with 'SQL::Translator::Parser::DBI::Dialect';

has 'schema' => (is => 'ro', isa => Str, default => { sub { SQL::Translator::Object::Schema->new( { name => '' }));

1;
