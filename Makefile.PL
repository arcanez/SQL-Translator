use inc::Module::Install 0.91;

name            'SQL-Translator';
author          'Justin Hunter <justin.d.hunter@gmail.com>';
license         'perl';

all_from        'lib/SQL/Translator.pm';
readme_from     ('lib/SQL/Translator.pm');

tests           't/*.t';

requires        'aliased',                      '0.30';
requires        'FindBin';
requires        'Moose',                        '0.89_01';
requires        'MooseX::Declare',              '0.29';
requires        'MooseX::Types',                '0.19';
requires        'MooseX::Method::Signatures',   '0.24';
requires        'MooseX::MultiMethods',         '0.07';
requires        'Parse::RecDescent',            '1.94';
requires        'Tie::IxHash',                  '1.21';
requires        'TryCatch',                     '1.001001';

test_requires   'Test::More',                   '0.92';
test_requires   'Test::Output',                 '0.12';
test_requires   'FindBin';

repository      'http://github.com/arcanez/sql-translator/tree/master';
bugtracker      'http://github.com/arcanez/sql-translator/issues';

auto_manifest;
auto_provides_class;
auto_install;

WriteAll;
