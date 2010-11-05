
use Test::More;

BEGIN
{
    eval { use v5.10; 1 }
    or plan skip_all => 'This test uses smart matches';
}

package Base;

use v5.8;
use strict;

use Exporter::Proxy qw( dispatch=frobnicate );

sub foo { [ @_, 'FOO' ] }
sub bar { [ @_, 'BAR' ] }

package Derived;

use v5.8;
use strict;

use Test::More;

Base->import;

plan tests => 4;

my @expect  = qw( frobnicate );
my @found   = Base->exports;

ok @expect ~~ @found, "Base exports @found (@expect)";

ok __PACKAGE__->can( 'frobnicate' ), 'frobnicate exported';

for
(
    [ foo => qw( a b c ) ], 
    [ bar => qw( i j k ) ],
)
{
    my ( $name, @argz ) = @$_;

    # order checks that the name is spliced off properly
    # in the dispatcher.

    my $expect  = [ 'Derived', @argz, uc $name ];
    my $found   = __PACKAGE__->frobnicate( $name => @argz  );

    ok $expect ~~ $found, "$name => @$found (@$expect)";
}


__END__
