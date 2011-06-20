use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'SQL-Translator',
  VERSION_FROM => 'lib/SQL/Translator.pm',
  PREREQ_PM => {
    'aliased'                        => '0.30',
    'FindBin'                        => '0',
    'Moose'                          => '0.93',
    'MooseX::Aliases'                => '0.08',
    'MooseX::Declare'                => '0.31',
    'MooseX::Types'                  => '0.20',
    'MooseX::Method::Signatures'     => '0.29',
    'MooseX::MultiMethods'           => '0.09',
    'Parse::RecDescent'              => '1.94',
    'Tie::IxHash'                    => '1.21',
    'Try::Tiny'                      => '0',
    'MooseX::Types::Parameterizable' => '0',
  },
  BUILD_REQUIRES => {
    'Test::More'                     => '0.92',
    'Test::Output'                   => '0.12',
    'FindBin'                        => '0',
  },
  META_MERGE => {
    resources => {
      license     => 'http://dev.perl.org/licenses/',
      bugtracker  => 'http://github.com/arcanez/sql-translator/issues',
      repository  => 'http://github.com/arcanez/sql-translator/tree/master',
    },
  },
);
