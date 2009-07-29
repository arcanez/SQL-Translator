use MooseX::Declare;
class SQL::Translator {
    use MooseX::Types::Moose qw(Str);
    use TryCatch;
    use SQL::Translator::Types qw(DBIHandle Parser Producer);
    
    has 'parser' => (
        isa => Str,
        is => 'ro',
        init_arg => 'from',
        required => 1,
    );
    
    has 'producer' => (
        isa => Str,
        is => 'ro',
        init_arg => 'to',
        required => 1,
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
    
    has 'filename' => (
        isa => Str,
        is => 'ro',
        predicate => 'has_ddl',
    );
    
    method _build__parser {
        my $class = 'SQL::Translator::Parser';
    
        Class::MOP::load_class($class);
    
        my $parser;
        if ($self->has_dbh) {
            $parser = $class->new({ dbh => $self->dbh });
        } elsif ($self->has_ddl) {
            $parser = $class->new({ filename => $self->filename, type => $self->parser });
        } else {
            die "dbh or filename is required!";
        }
    
        return $parser;
    }
    
    method _build__producer {
        my $class = 'SQL::Translator::Producer';
        my $role = $class . '::' . $self->producer;
    
        Class::MOP::load_class($class);
        try { Class::MOP::load_class($role) } catch ($e) { $role = $class . '::SQL::' . $self->producer; Class::MOP::load_class($role) }
    
        my $producer = $class->new({ schema => $self->parse });
        $role->meta->apply($producer);
    
        return $producer;
    }
} 
