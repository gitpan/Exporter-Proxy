
use Test::More;

BEGIN
{
    plan skip_all => "This test requires 5.10 (found $])"
    if $] < 5.10;
}

package Testify;

use v5.8;
use strict;

use Exporter::Proxy qw( foo );

use Test::More;

plan tests => 3;

sub foo { 'foo' }

my %foo     = qw( this is a hash );
my @foo     = qw( this is an array );
my $foo     = 'this is a scalar';

my @expect  = qw( foo );

ok __PACKAGE__->can( $_ ), __PACKAGE__ . "can $_"
for qw( import exports );

my @found   = __PACKAGE__->exports;

ok @found ~~ @expect, "Testify exports @found (@expect)";

__END__
