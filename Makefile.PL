use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile
(
    NAME          => 'Exporter::Proxy',
    VERSION_FROM  => 'lib/Exporter/Proxy.pm',
    ABSTRACT_FROM => 'lib/Exporter/Proxy.pm',
    PREREQ_PM     =>
    {
        # standard distro, particular versions 
        # are unlikely to cause pain.

        strict      => 0,
        Carp        => 0,
        Symbol      => 0,
        Test::More  => 0,
    }
);
