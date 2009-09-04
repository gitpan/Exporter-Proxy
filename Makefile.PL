use v5.10.0;
use ExtUtils::MakeMaker;

WriteMakefile
(

  NAME          => 'Exporter::Proxy',
  VERSION       => '0.02',
  ABSTRACT_FROM => 'lib/Exporter/Proxy.pm',
  PREREQ_PM     =>
  {
    # standard distro, particular versions 
    # are unlikely to cause pain.

    strict      => 0,
    Carp        => 0,
    Symbol      => 0,
    Test::More  => 0,
  },

);
