
use v5.10.0;
use strict;

use Test::More;

plan tests => 2;


use_ok 'Exporter::Proxy';

ok Exporter::Proxy->can( 'import' ), "Exporter::Proxy can 'import'";

__END__
