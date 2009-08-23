use inc::Module::Install 0.91;

name            'SQL-Translator';
author          'Justin Hunter <justin.d.hunter@gmail.com>';
license         'perl';

all_from        'lib/SQL/Translator.pm';
readme_from     ('lib/SQL/Translator.pm');

tests           't/*.t';
#author_tests    'xt', 'examples/MyApp-Web/t';

#requires        'Carp',                         '1.08';
#requires        'Class::Inspector',             '1.24';
#requires        'Perl6::Junction',              '1.40000';
requires        'aliased',                      '0.22';
#requires        'parent',                       '0.221';
#requires        'Data::Dump',                   '1.14';
#requires        'Catalyst',                     '5.80007';
#requires        'CLASS',                        '1.00';
requires        'Moose',                        '0.88';
requires        'MooseX::AttributeHelpers',     '0.16';
requires        'MooseX::Declare',              '0.23';
requires        'MooseX::MethodAttributes',     '0.15';
requires        'MooseX::Types',                '0.16';
requires        'MooseX::Method::Signatures',   '0.16';
requires        'MooseX::MultiMethods';
requires        'TryCatch',                     '1.001001';
requires        'FindBin';

test_requires   'Test::More',                   '0.92';
test_requires   'Test::Output',                 '0.12';
#test_requires   'Catalyst::Test';
test_requires   'FindBin';

#configure_requires  'PPI',                      '1.203';
#configure_requires  'File::Find::Rule::Perl',   '1.09';
#configure_requires  'File::Find::Rule',         '0.30';
#configure_requires  'File::Temp',               '0.21';
#configure_requires  'ExtUtils::MM_Unix',        '6.50';

repository      'http://github.com/arcanez/sql-translator/tree/master';
bugtracker      'http://github.com/arcanez/sql-translator/issues';

auto_manifest;
auto_provides_class;
auto_install;

WriteAll;
