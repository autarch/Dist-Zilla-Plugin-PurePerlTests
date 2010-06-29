package Dist::Zilla::Plugin::PurePerlTests;

use strict;
use warnings;

use Dist::Zilla::File::InMemory;

use Moose;
use Moose::Autobox;

with 'Dist::Zilla::Role::FileGatherer';

has env_var => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub gather_files {
    my $self = shift;

    for my $file ( grep { $_->name() =~ m<\At/.+\.t\z> }
        $self->zilla()->files()->flatten() ) {

        $self->_copy_file($file);
    }
}

sub _copy_file {
    my $self = shift;
    my $file = shift;

    ( my $name = $file->name() ) =~ s{/([^/]+)$}{/author-pp-$1};

    my $content = $file->content();

    return if $content =~ /^\#\s*no\s+pp\s+test\s*$/m;

    my $env_var = $self->env_var();

    $content = <<"EOF";
use Test::More;

BEGIN {
    unless ( \$ENV{AUTHOR_TESTING} ) {
        plan skip_all => 'these tests are for testing by the author';
    }

    \$ENV{$env_var} = 1;
}

$content
EOF

    $self->log( 'rewriting ' . $file->name() . " to $name" );

    my $pp_file = Dist::Zilla::File::InMemory->new(
        name    => $name,
        content => $content,
    );

    $self->add_file($pp_file);
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Run all your tests twice, once with XS code and once with pure Perl

=head1 SYNOPSIS

In your F<dist.ini>:

  [PurePerlTests]
  env_var = MY_MODULE_PURE_PERL

=head1 DESCRIPTION

This plugin is for modules which ship with a dual XS/pure Perl implementation.

The plugin makes a copy of all your tests when doing author testing (via
C<dzil test>). The copy will set an environment value that you specify in a
C<BEGIN> block. You can use this to force your code to not load the XS
implementation.

=head1 CONFIGURATION

This plugin takes one configuration key, "env_var", which is required.

=head1 SKIPPING TESTS

If you don't want to run the a given test file in pure Perl mode, you can put
a comment like this in your test:

  # no pp test

This must be on a line by itself. This plugin will skip any tests which
contain this comment.


