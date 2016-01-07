package t::lib::Test;

use strict;
use warnings;
use parent 'Test::Builder::Module';

use Test::More;
use Test::Differences;
use Test::Exception;

use Google::ProtocolBuffers::Dynamic;
use Config;

our @EXPORT = (
    @Test::More::EXPORT,
    @Test::Differences::EXPORT,
    @Test::Exception::EXPORT,
    qw(
          maybe_bigint
    )
);

sub import {
    unshift @INC, 't/lib';

    strict->import;
    warnings->import;

    goto &Test::Builder::Module::import;
}

sub maybe_bigint {
    return $_[0] if $Config{ivsize} >= 8;

    require Math::BigInt;
    my $bi = Math::BigInt->new($_[0]);

    return $bi > -2147483648 && $bi < 2147483647 ? 0 + $_[0] : $bi;
}

1;