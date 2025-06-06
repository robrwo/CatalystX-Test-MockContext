package CatalystX::Test::MockContext;

use v5.14;
use warnings;

use Plack::Test;
use Class::Load ();

our $VERSION = '0.000004';

#ABSTRACT: Conveniently create $c objects for testing

=head1 SYNOPSIS

  use HTTP::Request::Common;
  use CatalystX::Test::MockContext;

  my $m = mock_context('MyApp');
  my $c = $m->(GET '/');

=cut

use Sub::Exporter -setup => {
  exports => [qw(mock_context)],
  groups => { default => [qw(mock_context)] }
};

=export mock_context

 my $sub = mock_context('MyApp');

This function returns a closure that takes an L<HTTP::Request> object and returns a
L<Catalyst> context object for that request.

=cut

sub mock_context {
  my ($class) = @_;
  Class::Load::load_class($class);
  sub {
    my ($req) = @_;
    my $c;
    my $app = sub {
        my $env = shift;

        # legacy implementation handles stash creation via MyApp->prepare

        $c = $class->prepare( env => $env, response_cb => sub { } );
        return [ 200, [ 'Content-type' => 'text/plain' ], ['Created mock OK'] ];
    };

    # handle stash-as-middleware implementation from v5.90070
    if (eval { $Catalyst::VERSION } >= 5.90070) {
        Class::Load::load_class('Catalyst::Middleware::Stash');
        $app = Catalyst::Middleware::Stash->wrap($app);
    }

    test_psgi app => $app,
    client => sub {
      my $cb = shift;
      $cb->($req);
    };
    return $c;
  }
}

=head1 SUPPORT FOR OLDER PERL VERSIONS

This module requires Perl v5.14 or later.

Future releases may only support Perl versions released in the last ten (10) years.

=head1 append:BUGS

=head2 Reporting Security Vulnerabilities

Security issues should not be reported on the bugtracker website.  Please see F<SECURITY.md> for instructions how to
report security vulnerabilities.

=head1 append:AUTHOR

Currently maintained by Robert Rothenberg <rrwo@cpan.org>

=cut

1;
