use MooseX::Declare;
role SQL::Translator::Parser::DBI::PostgreSQL {
    use MooseX::Types::Moose qw(HashRef Str);
    use SQL::Translator::Types qw(View);
    
    has '+schema_name' => (
      isa => Str,
      lazy => 1,
      default => 'public'
    );
    
    method _get_view_sql(View $view) {
        my ($sql) = $self->dbh->selectrow_array("SELECT pg_get_viewdef('$view'::regclass)");
        return $sql;
    }
    
    method _is_auto_increment(HashRef $column_info) {
        return $column_info->{COLUMN_DEF} && $column_info->{COLUMN_DEF} =~ /^nextval\(/ ? 1 : 0;
    }
    
    method _column_default_value(HashRef $column_info) {
        my $default_value = $column_info->{COLUMN_DEF};
    
        if (defined $default_value) {
            $default_value =~ s/::.*$//
        }
        return $default_value;
    }
}
