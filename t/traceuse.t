#!perl

use strict;
use warnings;
use Test::More;
use IPC::Open3;
use File::Spec;
use Config;

my $tlib  = File::Spec->catdir( 't', 'lib' );
my $tlib2 = File::Spec->catdir( 't', 'lib2' );

# all command lines prefixed with $^X -I"t/lib"
my @tests = (
    [ << 'OUT', qw(-d:TraceUse -MParent -e1) ],
Modules used from -e:
   1.  Parent, -e line 0 [main]
   2.    Child, Parent.pm line 3
   3.      Sibling, Child.pm line 3
OUT
    [ << 'OUT', qw(-d:TraceUse -MChild -e1) ],
Modules used from -e:
   1.  Child, -e line 0 [main]
   2.    Sibling, Child.pm line 3
   3.      Parent, Sibling.pm line 4
OUT
    [ << 'OUT', qw(-d:TraceUse -MSibling -e1) ],
Modules used from -e:
   1.  Sibling, -e line 0 [main]
   2.    Child, Sibling.pm line 3
   3.      Parent, Child.pm line 4
OUT
    [ << 'OUT', qw(-d:TraceUse -MM1 -e1) ],
Modules used from -e:
   1.  M1, -e line 0 [main]
   2.    M2, M1.pm line 3
   3.      M3, M2.pm line 3
OUT
    [ << 'OUT', qw(-d:TraceUse -MM4 -e1) ],
Modules used from -e:
   1.  M4, -e line 0 [main]
   2.    M5, M4.pm line 3
   3.      M6, M5.pm line 9 [M5::in]
OUT
    [ << 'OUT', qw(-d:TraceUse -MM1 -e), 'require M4' ],
Modules used from -e:
   1.  M1, -e line 0 [main]
   2.    M2, M1.pm line 3
   3.      M3, M2.pm line 3
   4.  M4, -e line 1 [main]
   5.    M5, M4.pm line 3
   6.      M6, M5.pm line 9 [M5::in]
OUT
    [ << 'OUT', qw(-d:TraceUse -e), 'require M4; use M1' ],
Modules used from -e:
   1.  M1, -e line 1 [main]
   2.    M2, M1.pm line 3
   3.      M3, M2.pm line 3
   4.  M4, -e line 1 [main]
   5.    M5, M4.pm line 3
   6.      M6, M5.pm line 9 [M5::in]
OUT
    [ << 'OUT', qw(-d:TraceUse -MM4 -MM1 -e M5->load) ],
Modules used from -e:
   1.  M4, -e line 0 [main]
   2.    M5, M4.pm line 3
   3.      M6, M5.pm line 9 [M5::in]
   7.      M7, M5.pm line 4
   4.  M1, -e line 0 [main]
   5.    M2, M1.pm line 3
   6.      M3, M2.pm line 3
OUT
    [ << 'OUT', qw(-d:TraceUse -e), 'eval { use M1 }' ],
Modules used from -e:
   1.  M1, -e line 1 [main]
   2.    M2, M1.pm line 3
   3.      M3, M2.pm line 3
OUT
    [ << 'OUT', '-d:TraceUse', "-Mlib=$tlib2", '-MM8', '-e1' ],
Modules used from -e:
   0.  lib, -e line 0 [main]
Modules used, but not reported:
  M8.pm
OUT
    [ << 'OUT', '-d:TraceUse', "-Mlib=$tlib2", '-MM1', '-MM8', '-e1' ],
Modules used from -e:
   0.  lib, -e line 0 [main]
   0.  M1, -e line 0 [main]
   0.    M2, M1.pm line 3
   0.      M3, M2.pm line 3
   0.  M8, -e line 0 [main]
OUT
    [ << 'OUT', '-d:TraceUse', "-Mlib=$tlib2", '-MM7', '-MM8', '-e1' ],
Modules used from -e:
   0.  lib, -e line 0 [main]
   0.  M7, -e line 0 [main]
   0.  M8, -e line 0 [main]
OUT
    [ << 'OUT', qw(-d:TraceUse -e), 'eval { require M10 }' ],
Modules used from -e:
   1.  M10, -e line 1 [main] (FAILED)
OUT
    [   << 'OUT', qw(-d:TraceUse -e), "eval { require M10 };\npackage M11;\neval { require M10 }" ],
Modules used from -e:
   1.  M10, -e line 1 [main] (FAILED)
   2.  M10, -e line 3 [M11] (FAILED)
OUT
    [   << 'OUT', '-d:TraceUse', '-MM7', "-Mlib=$tlib2", '-MM1', '-MM8', '-e1' ],
Modules used from -e:
   0.  M7, -e line 0 [main]
   0.  lib, -e line 0 [main]
   0.  M1, -e line 0 [main]
   0.    M2, M1.pm line 3
   0.      M3, M2.pm line 3
   0.  M8, -e line 0 [main]
OUT
    [   << 'OUT', '-d:TraceUse', "-I$tlib2", qw( -MM4 -MM1 -MM8 -MM10 -e M5->load) ],
Modules used from -e:
   1.  M4, -e line 0 [main]
   2.    M5, M4.pm line 3
   3.      M6, M5.pm line 9 [M5::in]
  11.      M7, M5.pm line 4
   4.  M1, -e line 0 [main]
   5.    M2, M1.pm line 3
   6.      M3, M2.pm line 3
   7.  M8, -e line 0 [main]
   8.  M10, -e line 0 [main]
   9.    M11, M10.pm line 3 [M8]
  10.    M12, M10.pm line 4 [M8]
OUT
);

# -MDevel::TraceUse usually produces the same output as -d:TraceUse
for ( 0 .. $#tests ) {
    push( @tests, [ @{ $tests[$_] } ] );
    $tests[-1][1] = '-MDevel::TraceUse';
}

# but there are some exceptions
push @tests, (
    [ << 'OUT', qw(-d:TraceUse -e), 'eval "use M1"' ],
Modules used from -e:
   1.  M1, -e line 1 (eval 1) [main]
   2.    M2, M1.pm line 3
   3.      M3, M2.pm line 3
OUT
    [ << 'OUT', qw(-MDevel::TraceUse -e), 'eval "use M1"' ],
Modules used from -e:
   1.  M1, (eval 1) [main]
   2.    M2, M1.pm line 3
   3.      M3, M2.pm line 3
OUT
    [ << 'OUT', qw(-d:TraceUse -MM9 -e1) ],
Modules used from -e:
   1.  M9, -e line 0 [main]
   2.    M6, M9.pm line 3 (eval 1)
OUT
    [ << 'OUT', qw(-MDevel::TraceUse -MM9 -e1) ],
Modules used from -e:
   1.  M9, -e line 0 [main]
   2.  M6, (eval 1) [M9]
OUT
);

plan tests => scalar @tests;

for my $test (@tests) {
    my ( $errput, @cmd ) = @$test;

    # run the test subcommand
    local ( *IN, *OUT, *ERR );
    my $pid = open3( \*IN, \*OUT, \*ERR, $^X, '-Iblib/lib', "-I$tlib", @cmd );
    my @errput = map { s/[\015\012]*$//; $_ } <ERR>;
    waitpid( $pid, 0 );

    # we want to ignore modules loaded by those libraries
    my $nums = 1;
    for my $lib (qw( lib sitecustomize.pl )) {
        if ( grep /\. +.*\Q$lib\E,/, @errput ) {
            @errput = normalize( $lib, @errput );
            $nums = 0;
        }
    }

    # take sitecustomize.pl into account in our expected errput
    ( $nums, $errput ) = add_sitecustomize( $nums, $errput, @cmd )
        if $Config{usesitecustomize};

    # compare the results
    ( my $mesg = "Trace for: perl @cmd" ) =~ s/\n/\\n/g;
    my @expected = map { s/[\015\012]*$//; $_ } split /^/, $errput;
    @expected = map { s/^(\s*\d+)\./%%%%./; $_ } @expected if !$nums;

    is_deeply( \@errput, \@expected, $mesg )
        or diag map ( {"$_\n"} '--- Got ---', @errput ),
        "--- Expected ---\n$errput";
}

# removes unexpected modules loaded by somewhat expected ones
# and normalize the errput so we can ignore them
sub normalize {
    my ( $lib, @lines ) = @_;
    my $loaded_by = 0;
    my $tab;
    for (@lines) {
        s/^(\s*\d+)\./%%%%./;
        if (/\.( +)\Q$lib\E,/) {
            $loaded_by = 1;
            $tab       = $1 . '  ';
            next;
        }
        if ($loaded_by) {
            if   (/^%%%%\.$tab/) { $_         = 'deleted' }
            else                 { $loaded_by = 0 }
        }
    }
    return grep { $_ ne 'deleted' } @lines;
}

my $diag;

sub add_sitecustomize {
    my ( $nums, $errput, @cmd ) = @_;
    my $sitecustomize_path
        = File::Spec->catfile( $Config{sitelib}, 'sitecustomize.pl' );
    my $sitecustomize = do {
        my @parts = File::Spec->splitpath($sitecustomize_path);
        splice @parts, 1, File::Spec->splitdir( $parts[1] );
        join '/', @parts;
    };

    # provide some info to the tester
    if ( !$diag++ ) {
        diag "This perl has sitecustomize.pl enabled, ",
            -e $sitecustomize_path
            ? "and the file exists"
            : "but the file does not exist";
    }

    # the output depends on the existence of sitecustomize.pl
    if ( -e $sitecustomize_path ) {

        # Loaded so first it's not caught by our @INC hook:
        #  Modules used, but not reported:
        #    /home/book/local/5.8.9/site/lib/sitecustomize.pl
        $errput =~ s/Modules used, but not reported:.*?^(.*)//gsm;
        my @not_reported = ( "  $sitecustomize\n", $1 ? split /^/, $1 : () );
        $errput .= "Modules used, but not reported:\n" . join '',
            sort @not_reported;
    }
    elsif ( grep { $_ eq '-d:TraceUse' } @cmd ) {

        # Loaded first, but FAIL. The debugger will tell us.
        #  Modules used from -e:
        #     1.  C:/perl/site/lib/sitecustomize.pl, -e line 0 [main] (FAILED)
        $errput =~ s{Modules used from.*?^}
                    {$&   0.  $sitecustomize, -e line 0 [main] (FAILED)\n}sm;
        $nums = 0;
    }

    # updated values
    return ( $nums, $errput );
}

