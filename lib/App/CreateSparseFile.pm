package App::CreateSparseFile;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use SHARYANTO::File::Util qw(file_exists);
use SHARYANTO::Text::Prompt qw(confirm);

our %SPEC;

$SPEC{create_sparse_file} = {
    v => 1.1,
    summary => 'Create sparse file',
    description => <<'_',

Sparse file is a file with a predefined size (sometimes large) but does not yet
allocate all its (blank) data on disk. Sparse file is a feature of filesystem.

I usually create sparse file when I want to create a large disk image but do not
want to preallocate its data yet. Creating a sparse file should be virtually
instantaneous.

_
    args => {
        name => {
            schema => ['str*'],
            req => 1,
            pos => 0,
        },
        size => {
            summary => 'Size (e.g. 10K, 22.5M)',
            schema => ['str*'],
            cmdline_aliases => { s => {} },
            req => 1,
            pos => 1,
        },
        interactive => {
            summary => 'Whether or not the program should be interactive',
            schema => 'bool',
            default => 1,
            description => <<'_',

If set to false then will not prompt interactively and usually will proceed
(unless for dangerous stuffs, in which case will bail immediately.

_
        },
        override => {
            summary => 'Whether to override existing file',
            schema => 'bool',
            default => 0,
            description => <<'_',

If se to true then will override existing file without warning. The default is
to prompt, or bail (if not interactive).

_
        },
    },
    examples => [
        {
            argv => [qw/file.bin 30G/],
            summary => 'Create a sparse file called file.bin with size of 30GB',
        },
    ],
};
sub create_sparse_file {
    my %args = @_;

    my $interactive = $args{interactive} // 1;

    # TODO: use Parse::Number::WithPrefix::EN
    my $size = $args{size} // 0;
    if ($size =~ s/([A-Za-z])[Bb]?\z//) {
        my $prefix = $1;
        if ($prefix =~ /[Kk]/) {
            $size *= 1024;
        } elsif ($prefix =~ /[Mm]/) {
            $size *= 1024**2;
        } elsif ($prefix =~ /[Gg]/) {
            $size *= 1024**3;
        } elsif ($prefix =~ /[Tt]/) {
            $size *= 1024**4;
        }
    }
    return [400, "Invalid size, please specify num or num[KMGT]"]
        unless $size =~ /\A\d+(\.\d+)?\z/;

    my $fname = $args{name};

    if (file_exists $fname) {
        if ($interactive) {
            return [200, "Cancelled"]
                unless confirm "Confirm override existing file (y/n)?";
        } else {
            return [409, "File already exists"] unless $args{override};
        }
        unlink $fname or return [400, "Can't unlink $fname: $!"];
    } else {
        if ($interactive) {
            return [200, "Cancelled"]
                unless confirm "Confirm create '$fname' with size $size (y/n)?";
        }
    }

    open my($fh), ">", $fname or return [500, "Can't create $fname: $!"];
    if ($size > 0) {
        seek $fh, $size-1, 0;
        print $fh "\0";
    }
    [200, "Done"];
}

1;
# ABSTRACT: Create sparse file

=head1 SYNOPSIS

See L<create-sparse-file>.

=cut
