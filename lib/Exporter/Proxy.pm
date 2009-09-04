########################################################################
# housekeeping
########################################################################

package Exporter::Proxy;

use v5.10.0;
use strict;

use Carp;

use Symbol  qw( qualify_to_ref );

########################################################################
# package variables
########################################################################

our $VERSION    = '0.01';

########################################################################
# utility functions
########################################################################

########################################################################
# methods (public interface)
########################################################################

sub import
{
    # discard this package.
    # left on the stack are assignment operators and 
    # exported names.

    shift;

    my @exportz = ();

    my %argz
    = do
    {
        my @argz    = grep /=/, @_;
        @exportz    = grep { ! ( $_ ~~ @argz ) } @_;
        
        map { split /=/ } @argz
    };

    # maybe carp about extraneous arguments here?

    my $disp    = delete $argz{ dispatch } || '';

    # avoid colliding with '$caller' in the exported subs.

    my $source  = caller;

    # if a dispatcher is being used then it must
    # be exported. in many cases this will be the
    # only thing exported.

    if( $disp )
    {
        $disp ~~ @exportz 
        or push @exportz, $disp;

        my $ref = qualify_to_ref $disp, $source;

        undef &{ *$ref };

        *$ref
        = sub
        {
            my $op      = splice @_, 1, 1;

            my $handler = $source->can( $op )
            or croak "Bogus $disp: $source cannot '$op'";

            goto &$handler
        };
    }

    @exportz
    or carp "Oddity: nothing requested for export!";

    my $exports = qualify_to_ref 'exports', $source;
    my $import  = qualify_to_ref 'import',  $source;

    undef &{ *$_ } for ( $exports, $import );

    *$exports
    = sub
    {
        # avoid giving away ref's to the closed-over
        # variable.

        wantarray
        ?   @exportz
        : [ @exportz ]
    };

    *$import
    = sub
    {
        # discard the package as first argument:
        # $pkg->import

        shift;

        my $caller  = caller;

        # empty list => use @exportz.
        # :noexport  => use empty list.

        if( ':noexport' ~~ @_ )
        {
            @_  = ();
        }
        elsif( @_ )
        {
            # nothing more for the moment.
        }
        else
        {
            @_  = @exportz;
        }

        # resolve these at runtime to account for
        # possible autoloading, etc.

        for( @_ )
        {
            index $_, ':'
            or next;

            if( $_ ~~ @exportz )
            {
                my $source  = qualify_to_ref $_, $source;
                my $install = qualify_to_ref $_, $caller;

                *$install   = *$source;
            }
            else
            {
                die "Bogus $source: '$_' not exported";
            }
        }
    };

    return
}

# keep require happy

1

__END__

=head1 NAME

Exporter::Proxy - Simplified symbol export by name with
optional dispatcher.

=head1 SYNOPSIS

    package My::Module;

    use Exporter::Proxy qw( foo Bar );

    # at this point users of My::Module will get
    # *My::Module::foo and *My::Module::Bar 
    # installed.
    #
    # My::Module also gets an 'exports' method
    # that lists the exported items; array refs
    # are exported as copies by value.

    my @exported    = My::Module->exports;

    my $object      = My::Module->construct;

    my $exported    = $object->exports;


    package Some::Other;

    use My::Module qw( foo );   # only exports foo
    use My::Module qw( Bar );   # only exports Bar

    use My::Module qw( bar );   # croaks, 'bar' is not exported.

    # caller can specify the items to export by 
    # name -- not type. foo might be used as a
    # subroutine, Bar as an array, or foo may 
    # be overloaded with &foo, %foo, @foo, $foo.

    $value ~~ @Bar
    or croak "Invalid '$value'";

    delete $foo{ somekey }
    or croak "Oops: foo is missing 'somekey'";

    my $bletch  = $foo || 'oops, no $foo';

    # if the caller does not want to export
    # anything from the module when it is used,
    # ":noexport" does just that.

    use My::Module qw( :noexport );

    # there are times when it is easier to use
    # a dispatcher for things like service classes
    # than to pollute the caller's namespace with 
    # all of the available methods.

    use Exporter::Proxy qw( dispatch=frobnicate );

    # at this point 'frobnicate' is installed in 
    # My::Module. it splices out the second
    # argument, uses My::Module->can( $name ) to
    # check if the module has the service availble
    # and then dispatches to it via goto.
    #
    # My::Module->exports will include the dispatcher,
    # in the last example it will have only the
    # dispatcher since no other names were included.
    #
    # now modules use-ing this one look like:

    use My::Module;

    my $object  = My::Module->construct;

    $object->frobnicate( foo => @foo_args );

    my @test_these  = $object->exports;

    my $test_ref    = $objeect->exports;

    # @test_these will be qw( frobnicate )
    # $test_ref will be an arrayref of a 
    # copy of the exported values (i.e., 
    # modifying $test_ref does not affect
    # the exported items.

=head1 DESCRIPTION

This installs 'import' and 'exports' subroutines 
into the callers namespace. The 'import' does 
the usual deed: exporting symbols by name; 
'exports' simplifies introspection by listing 
the exported symbols (useful for testing).

The optional "dispather=name" argument is used
to install a dispatcher. This allows the module
to offer a variety of services without polluting
the caller's namespace with too many of them. All
it does is check for $module->can( $name ) and 
goto &$handler if the module can handle the 
request.

=head2 Public Interface

=over 4

=item import

The arguments to this are the symbol names to 
export with an optional "dispatch=<name>" for
installing the dispatcher.

The import extracts the exported symbols, adding
the dispatcher's name to the list if necessary,
and then installs import, exports, and the 
dispathcher as necessary.

=back

=head2 Installed methods

=over 4

=item import

With no arguments the import uses the original
exports list, pushing all of the symbols into
the caller's space.

The optional argument ':noexport' short-circuts
export of any symbols to the caller's space.

Other than ':noexport' any arguments with leading
colons are silently ignored by import.

Anything without a leading colon is assumed to
be a name, and is checked againsed the exports
list. If it is on the list then the caller's 
$name symbol is aliased to the source module's.

Note that this is not a copy-by-value into
the caller's space, it is aliaing via the symbol
table. 

i.e., 

    my $dest    = qualify_to_ref $name, $caller;
    my $src     = qualify_to_ref $name, $source;

    *$dest  = *$src;

Callers modifying their copy of the item will be
modifiying a global copy. 

Aside: Once read-only references are avaialble
then they will be an option.

=item exports

Mainly for testing, calling:

    $module->exports;

or

    $object->exports

returns an array[ref] copy of the exported names.

=item dispatcher (optional)

When exporting a large number of symbols is
problematic, a dispatcher can be installed 
instead. This splices off the second argument,
checks that the module can perform the name,
and does a goto.

Calls to the dispatcher look like:

    $module->$dispatcher( $name => @name_argz );

The dispatcher splices $name off the stack,
checks that $module->can( $name ) (or $object
can), croaks if it cannot or does a goto &$handler.

Note that the dispatcher can only be exported
once: the last dispatch=name will be the only
one installed.

For example:

    package Query::Services;

    use Exporter::Proxy qw( dispatch=query );

    sub lookup
    {
        ...
    }

    sub modify
    {
        ...
    }

    sub insert_returning
    {
        ...
    }

allows the caller to:

    use Query::Services;

    # caller now can 'query', which can dispatch
    # calls to lookup, modify, and insert_returning.

    __PACKAGE__->query( modify => $sql, @argz );

    $object->query( lookup => @lookup_argz );

=back

A more general use of this is combining a number of 
service classes with a single 'dispatcher' class that
users others. In this case various separate My::Query::* 
modules help break up what would otherwise be a 
monstrosity into manageable chunks. They can use 
fairly short names that are obvious in context 
becuase the names only propagate up to My::Query. 

My::Query can even use "if" to limit the number
of services available (e.g., only packages that
already have an 'IsSafe' method have the modify 
calls available.


=over 4

    package My::Query::Handle;

    use Exporter::Proxy 
    qw
    (
        connect
        prepare
        disconnect
        fetch
        non_fetch
        insert_returning
    );

    # implementations...


    package My::Query::Lookup

    use Exporter::Proxy
    qw
    (
        lookup
        single_vale
    );

    ...

    package My::Query::Modify

    use Exporter::Proxy
    qw
    (
        insert
        insert_returning
        update
    );

    ...

    # all this needs is to install a dispatcher
    # and pull in the modules that implement the
    # methods it dispatches into.

    package My::Query;

    use Exporter::Proxy qw( dispatch=query );

    use My::Query::Handle;
    use My::Query::Lookup;

    use if $::can_modify, 'My::Query::Modify';

    __END__


    # the object class use-ing My::Query gets a
    # "query" method without having its namespace
    # polluted with "insert", "modify", etc.

    use My::Query;

    ...

    $object->query( lookup => $sql, @valz );

=back

=head2 Simple Test

The exports method provides a simple technique for
baseline testing of modules: check that they can
be used and actually can do what they've claimed
to export.

Say your tests are standardized as '00-Module-Name-Here.t'.

    use Test::More;
    use File::Basename;

    # whatever your naming convention is, 
    # munge it into a package name.

    my $madness = basename $0, '.t';

    $madness    =~ s/^ \d+ - //;
    $madness    =~ s/-/::/g;

    use_ok $madness;

    my @methodz = 
    (
        qw
        (
            import
            exports
        ),
        $madness->exports
    );

    ok $madness->can( $_ ), "$madness can '$_'"
    for @methodz;

    done_testing;

    __END__

Symlink this to whatever modules you need testing 
and "prove t/00*.t" will give a quick, standard
first pass as to whether they compile and are 
minimally usable.

=head1 AUTHOR

Steven Lembark <lembark@wrkhors.com>

=head1 LICENSE

Copyright (C) 2009 Workhorse Computing.
This code is released under the same terms as Perl 5.10.0,
or any later version of Perl, itself.
