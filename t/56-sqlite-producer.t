use strict;
use warnings;
use Test::More;

use SQL::Translator;
use SQL::Translator::Object::View;

{
  my $sqlt = SQL::Translator->new( to => 'SQLite' );
  my $producer = $sqlt->_producer;

  my $view1 = SQL::Translator::Object::View->new( name => 'view_foo',
                                                  fields => [qw/id name/],
                                                  sql => 'SELECT id, name FROM thing',
                                                  extra => {
                                                    temporary => 1,
                                                    if_not_exists => 1,
                                                  });

  my $create_opts = { no_comments => 1 };
  my $view1_sql1 = $producer->create_view($view1, $create_opts);

  my $view_sql_replace = "CREATE TEMPORARY VIEW IF NOT EXISTS view_foo AS
    SELECT id, name FROM thing";
  is($view1_sql1, $view_sql_replace, 'correct "CREATE TEMPORARY VIEW" SQL');

  my $view2 = SQL::Translator::Object::View->new( name => 'view_foo',
                                                  fields => [qw/id name/],
                                                  sql => 'SELECT id, name FROM thing',);

  my $view1_sql2 = $producer->create_view($view2, $create_opts);
  my $view_sql_noreplace = "CREATE VIEW view_foo AS
    SELECT id, name FROM thing";
  is($view1_sql2, $view_sql_noreplace, 'correct "CREATE VIEW" SQL');
}

done_testing;
