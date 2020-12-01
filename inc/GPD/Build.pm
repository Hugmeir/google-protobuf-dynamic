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

    my @upb_libs = shellwords(Alien::libupb_legacy->libs_static);
    my @pb_libs  = shellwords(Alien::Protobuf3_1_0->libs_static);

    my @extra_linker_flags;
    my @extra_lddl_flags;
    foreach my $part ( @upb_libs, @pb_libs ) {
        if ( $part =~ m<\Q$Config{lib_ext}\E\z> ) {
            # libprotobuf.a, goes at the end of the linker invocation
            push @extra_linker_flags, $part;
        }
        else {
            # anything else, e.g. -lz, goes before the objects being linked
            push @extra_lddl_flags, $part;
        }

        if ( $part =~ /\B-L(\S+)/ ) {
            my $library_path = $1;
            push @extra_lddl_flags, '-Wl,-rpath=' . $library_path;
        }
    }
    my $self = $class->SUPER::new(
        @_,
        extra_typemap_modules => {
            'ExtUtils::Typemaps::STL::String' => '0',
        },
        extra_linker_flags   => \@extra_linker_flags,
        extra_compiler_flags => [
            $debug_flag,
            Alien::libupb_legacy->cflags,
            Alien::Protobuf3_1_0->cflags,
            Alien::Protobuf3_1_0->cxxflags,
            "-DPERL_NO_GET_CONTEXT",
            # libprotobuf REQUIRES C11; ->cxxflags above should be giving us
            # this, but it's not smart enough yet.
            '-std=c++11',
        ],
        script_files => [qw(scripts/protoc-gen-perl-gpd)],
    );

    # if we ar statically linking against libprotobuf/libupb, then the
    #   -L/dir -lprotobuf
    # flags need to come before the objects being linked:
    $self->config(lddlflags => join(" ", $Config{lddlflags}, @extra_lddl_flags));

    # we are linking against C++ libraries (libprotobuf, upb), and possibly
    # *statically* linking against them -- so we must use g++/clang++ etc to
    # link, not gcc/clang, otherwise the link will fail:
    $self->config(ld => $self->config('cc'));

    return $self;
}

1;
