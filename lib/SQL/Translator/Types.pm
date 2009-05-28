package SQL::Translator::Types;
use MooseX::Types -declare => [qw(Column Constraint Index Procedure Schema Table Trigger View)];

subtype Column => as 'SQL::Translator::Object::Column';
subtype Constraint => as 'SQL::Translator:Object::Constraint';
subtype Index => as 'SQL::Translator:Object::Index';
subtype Procedure => as 'SQL::Translator:Object::Procedure';
subtype Schema => as 'SQL::Translator:Object::Schema';
subtype Table => as 'SQL::Translator::Object::Table';
subtype Trigger => as 'SQL::Translator:Object::Trigger';
subtype View => as 'SQL::Translator:Object::View';

1;
