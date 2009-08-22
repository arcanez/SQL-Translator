use MooseX::Declare;
class SQL::Translator {
    use TryCatch;
    use MooseX::Types::Moose qw(Bool HashRef Str);
    use SQL::Translator::Types qw(DBIHandle Parser Producer Schema);
    use SQL::Translator::Object::Schema;

    has 'parser' => (
        isa => Str,
        is => 'rw',
        init_arg => 'from',
    );
    
    has 'producer' => (
        isa => Str,
        is => 'rw',
        init_arg => 'to',
    );
    
    has '_parser' => (
        isa => Parser,
        is => 'rw',
        lazy_build => 1,
        handles => [ qw(parse) ],
    );
    
    has '_producer' => (
        isa => Producer,
        is => 'rw',
        lazy_build => 1,
        handles => [ qw(produce) ],
    );
    
    has 'dbh' => (
        isa => DBIHandle,
        is => 'ro',
        predicate => 'has_dbh',
    );

    has 'schema' => (
        isa => Schema,
        is => 'rw',
        default => sub { SQL::Translator::Object::Schema->new }
    );

    has 'parser_args' => (
        isa => HashRef,
        is => 'rw',
    );

    has 'producer_args' => (
        isa => HashRef,
        is => 'rw',
    );
    
    has 'add_drop_table' => (isa => Bool, is => 'rw', default => 0);
    has 'no_comments' => (isa => Bool, is => 'rw', default => 0);
    has 'show_warnings' => (isa => Bool, is => 'rw', default => 1);
    has 'trace' => (isa => Bool, is => 'rw', default => 0);
    has 'quote_table_names' => (isa => Bool, is => 'rw', default => 0);
    has 'quote_field_names' => (isa => Bool, is => 'rw', default => 0);
    has 'version' => (isa => Str, is => 'rw');
    has 'filename' => (isa => Str, is => 'rw');

    method _build__parser {
        my $class = 'SQL::Translator::Parser';
    
        Class::MOP::load_class($class);
    
        my $parser;
        if ($self->has_dbh) {
            $parser = $class->new({ translator => $self, dbh => $self->dbh });
        } else {
            $parser = $class->new({ translator => $self, type => $self->parser || '' });
        }
    
        return $parser;
    }
    
    method _build__producer {
        my $class = 'SQL::Translator::Producer';
        my $role = $class . '::' . $self->producer;

        Class::MOP::load_class($class);
        try {
            Class::MOP::load_class($role)
        } catch ($e) {
            $role = $class . '::SQL::' . $self->producer;
            Class::MOP::load_class($role)
        }
    
        my $producer = $class->new({ translator => $self });
        $role->meta->apply($producer);
    
        return $producer;
    }

    method translate(:$data, :$producer?, :$producer_args?, :$parser?, :$parser_args?) {
        if ($parser) {
            $self->_clear_parser;
            $self->parser($parser);
            $self->parse($data);
            $self->schema;
        } elsif ($producer) {
            $self->_clear_producer;
            $self->schema($self->parse($data)) if $data;
            $self->producer($producer);
            $self->produce;
        }
    }

    method parser_type { return $self->parser }
    method producer_type { return $self->producer }
} 
