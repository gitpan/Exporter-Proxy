
use Test::More;

BEGIN
{
    eval { use v5.10; 1 }
    or plan skip_all => 'This test uses smart matches';
}

package Base;

use v5.8;
use strict;

use Exporter::Proxy qw( dispatch=frobnicate bim bam );

sub foo { [ @_, 'FOO' ] }
sub bar { [ @_, 'BAR' ] }

our %bim    = ( 'a' .. 'z' );
our @bam    = (  1  ..  9  );

package Derived;

use v5.8;
use strict;

use Test::More;

Base->import( qw( bim frobnicate ) );

plan tests => 6;

ok   %Derived::bim, '%bim installed';
ok ! @Derived::bam, '@bam installed';

my @expect  = qw( bim bam frobnicate );
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
