package Plack::Session::State::Cookie;
use strict;
use warnings;

our $VERSION   = '0.09_03';
our $AUTHORITY = 'cpan:STEVAN';

use parent 'Plack::Session::State';
use Plack::Request;
use Plack::Response;

use Plack::Util::Accessor qw[
    path
    domain
    expires
    secure
    httponly
];

sub get_session_id {
    my ($self, $env) = @_;
    Plack::Request->new($env)->cookies->{$self->session_key};
}

sub merge_options {
    my($self, %options) = @_;

    delete $options{id};

    $options{path}     = $self->path || '/' if !exists $options{path};
    $options{domain}   = $self->domain      if !exists $options{domain} && defined $self->domain;
    $options{secure}   = $self->secure      if !exists $options{secure} && defined $self->secure;
    $options{httponly} = $self->httponly    if !exists $options{httponly} && defined $self->httponly;


    if (!exists $options{expires} && defined $self->expires) {
        $options{expires} = time + $self->expires;
    }

    return %options;
}

sub expire_session_id {
    my ($self, $id, $res, $options) = @_;
    my %opts = $self->merge_options(%$options, expires => time);
    $self->_set_cookie($id, $res, %opts);
}

sub finalize {
    my ($self, $id, $res, $options) = @_;
    my %opts = $self->merge_options(%$options);
    $self->_set_cookie($id, $res, %opts);
}

sub _set_cookie {
    my($self, $id, $res, %options) = @_;

    # TODO: Do not use Plack::Response
    my $response = Plack::Response->new(@$res);
    $response->cookies->{ $self->session_key } = +{
        value => $id,
        %options,
    };

    my $final_r = $response->finalize;
    $res->[1] = $final_r->[1]; # headers
}

1;

__END__

=pod

=head1 NAME

Plack::Session::State::Cookie - Basic cookie-based session state

=head1 SYNOPSIS

  use Plack::Builder;
  use Plack::Middleware::Session;

  my $app = sub {
      return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello Foo' ] ];
  };

  builder {
      enable 'Session'; # Cookie is the default state
      $app;
  };

=head1 DESCRIPTION

This is a subclass of L<Plack::Session::State> and implements it's
full interface. This is the default state used in
L<Plack::Middleware::Session>.

=head1 METHODS

=over 4

=item B<new ( %params )>

The C<%params> can include I<path>, I<domain>, I<expires> and
I<secure> options, as well as all the options accepted by
L<Plack::Session::Store>.

=item B<path>

Path of the cookie, this defaults to "/";

=item B<domain>

Domain of the cookie, if nothing is supplied then it will not
be included in the cookie.

=item B<expires>

Expiration time of the cookie in seconds, if nothing is supplied then
it will not be included in the cookie, which means the session expires
per browser session.

=item B<secure>

Secure flag for the cookie, if nothing is supplied then it will not
be included in the cookie.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009, 2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


