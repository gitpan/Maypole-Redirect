package Maypole::Redirect;
use strict;
use base qw'Apache::MVC Class::Accessor';
use Class::DBI::FromCGI;
use Apache::Constants qw(:common M_GET HTTP_METHOD_NOT_ALLOWED);
use Carp qw(croak cluck);
use Data::Dumper;
use vars qw($VERSION);
$VERSION = '0.01';

=head1 NAME

Maypole::Redirect - add HTTP redirect capability to Maypole

=head1 SYNOPSIS

  use base 'Maypole::Redirect';

  # ... later in your code:

  sub User::go_to_google :Exported {
    my ($self,$r) = @_;
    $r->location( 'http://www.google.com/' );
  };

  sub User::display_image :Exported {
    my ($self,$r) = @_;
    $r->filename( $self->filename );
  };

=head1 WARNING

I release this as a quick hack just to get some code out.
This code has ugly problems with Apache::File, so it doesn't use
the functionality provided by it. This is extreme alpha quality!

The code lacks tests, the code lacks finesse, the code lacks almost
everything. Use at your own risk!

Also, this code tries to fix some things I feel are ugly with Maypole,
namely the lack of proper accessor methods - so this code also lacks
the style to properly discuss things out with Simon until he adopts
my superior view.

=cut

__PACKAGE__->mk_accessors(qw( location filename content_type ));

=head2 C<< $app->filename FILENAME >>

If you set the filename, the file will be sent as the output,
and all necessary headers will be generated. This method
tries to use L<Apache::File> if available.

=head2 C<< $app->location LOCATION >>

By setting the location, you issue a redirect to C<LOCATION>.
This has a lower priority than a request for a directly served
file as set via C<filename>.

=head2 C<< $app->content_type CT >>

An accessor method to get and set the C<Content-Type> header
for the output.

=head2 C<< $app->log LEVEL, MESSAGE >>

This implements a very crude method of logging and tracing
progress through the application. The message gets written
to the HTTP error log if C<debug> is set higher or equal
to C<$level>.

=cut

sub log {
  my ($self,$level,@message) = @_;
  if ($self->debug >= $level) {
    my $message = "@message";
    $message =~ s!^!($level) !gm;
    warn $message;
  };
};

=head2 C<< $app->send_output >>

This sends the output. Normally this method is called from
within the Maypole workflow and you don't need to bother
with it. It is here where all the magic happens.

=cut

sub send_output {
  my ($self) = shift;
  my $r = $self->{ar};

  if ($self->filename) {
    my $filename = $self->filename;

    # Some sanity checks :
    if ($r->method_number != M_GET) {
      $self->log( 2, "$filename: Wrong method\n" );
      return HTTP_METHOD_NOT_ALLOWED
    };

    unless (-r $filename) {
      $self->error("file permissions deny server access: '$filename'");
      return FORBIDDEN;
    };

    $r->content_type( $self->content_type );
    $r->headers_out->set('Content-Length' => -s $filename);
    $r->headers_out->set('Cache-Control' => 'public, max-age='.3600*24 );

    # Try sending via Apache::File
    eval {
      die "Fix me - Apache::File doesn't work";
      Apache::File->require;

      $r->set_last_modified((stat $filename)[9]);
      $r->update_mtime($filename);
      $r->set_etag;

      if((my $rc = $r->meets_conditions) != OK) {
        $r->status($rc);
        $r->send_http_header;
        $self->log( 4, "$filename: Already cached ($rc)\n" );
        return OK;
      }
      $self->log( 4, "Continuing instead of 304" );

      $r->send_http_header;
      unless ($r->header_only) {
        my $f = Apache::File->new( $filename );
        $r->send_fd($f) or die "Couldn't send '$filename' : $!";
      } else {
        $self->log( 4, "HEAD only request" );
      };
      return OK;
    };

    # If we get here, most likely we don't have Apache::File
    # so we need to do a manual send:
    $self->log( 1, "Apache::File: $@")
      if $@;
    local $/;
    local *F;
    open F, "<", $filename;
    $self->{output} = <F>;

  } elsif ($self->location) {
    $r->headers_out->set('Location' => $self->location );
    $r->status(302);
    $self->{output} = "";
  };
  return $self->SUPER::send_output(@_);
};

1;

__END__

=head1 AUTHOR

Max Maischein, E<lt>corion@cpan.orgE<gt>

=head1 SEE ALSO

L<Maypole>, L<Apache::Request>, L<Apache::File>.

=cut

