package SQL::Translator::Types;
use MooseX::Types -declare, [qw(Column Constraint Index Procedure Schema Table Trigger View)];

class_type Column, { class => 'SQL::Translator::Object::Column' };
class_type Constraint, { class => 'SQL::Translator::Object::Constraint' };
class_type Index, { class => 'SQL::Translator::Object::Index' };
class_type Procedure, { class => 'SQL::Translator::Object::Procedure' };
class_type Schema, { class => 'SQL::Translator::Object::Schema' };
class_type Table, { class => 'SQL::Translator::Object::Table' };
class_type Trigger, { class => 'SQL::Translator::Object::Trigger' };
class_type View, { class => 'SQL::Translator::Object::View' };

1;
