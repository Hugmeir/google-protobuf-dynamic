package GPD::Build;

use strict;
use warnings;
use Config;
use parent 'Module::Build::WithXSpp';

use Alien::Protobuf3_1_0;
use Alien::libupb_legacy;
use Text::ParseWords qw( shellwords );
use Getopt::Long qw( :config pass_through );

# yes, doing this in a module is ugly; OTOH it's a private module
GetOptions(
    'g'         => \my $DEBUG,
);

sub new {
    my $class = shift;
    my $debug_flag = $DEBUG ? ' -g' : '';
    my $self = $class->SUPER::new(
        @_,
        extra_typemap_modules => {
            'ExtUtils::Typemaps::STL::String' => '0',
        },
        extra_linker_flags => [grep /\Q$Config{lib_ext}\E\z/, map shellwords($_), Alien::libupb_legacy->libs_static, Alien::Protobuf3_1_0->libs_static],
        extra_compiler_flags => [$debug_flag, Alien::libupb_legacy->cflags, Alien::Protobuf3_1_0->cflags, Alien::Protobuf3_1_0->cxxflags, "-DPERL_NO_GET_CONTEXT"],
        script_files => [qw(scripts/protoc-gen-perl-gpd)],
    );

    # if we ar statically linking against libprotobuf/libupb, then the
    #   -L/dir -lprotobuf
    # flags need to come before the objects being linked:
    $self->config(lddlflags => join(" ", $Config{lddlflags}, Alien::libupb_legacy->libs, Alien::Protobuf3_1_0->libs_static));

    # we are linking against C++ libraries (libprotobuf, upb), and possibly
    # *statically* linking against them -- so we must use g++/clang++ etc to
    # link, not gcc/clang, otherwise the link will fail:
    $self->config(ld => $self->config('cc'));

    return $self;
}

1;
