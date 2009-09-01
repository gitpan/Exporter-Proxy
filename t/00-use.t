
use v5.10.0;
use strict;

use Test::More;

plan tests => 2;


use_ok 'Export::Proxy';

ok Export::Proxy->can( 'import' ), "Export::Proxy can 'import'";

__END__
