# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Rsvg/Rsvg.pm,v 1.5 2005/02/24 17:54:31 kaffeetisch Exp $

package Gnome2::Rsvg;

use 5.008;
use strict;
use warnings;

use Glib;
use Gtk2;

require DynaLoader;

our @ISA = qw(DynaLoader);
our $VERSION = '0.04';

sub dl_load_flags { $^O eq 'darwin' ? 0x00 : 0x01 }

Gnome2::Rsvg -> bootstrap($VERSION);

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Gnome2::Rsvg - Perl interface to the RSVG library

=head1 SYNOPSIS

  use Gnome2::Rsvg;

  my $svg = "path/to/image.svg";

  # The easy way.
  my $pixbuf = Gnome2::Rsvg -> pixbuf_from_file($svg);

  # The harder way.
  my $handle = Gnome2::Rsvg::Handle -> new();

  open(SVG, $svg) or die("Opening '$svg': $!");

  while (<SVG>) {
    $handle -> write($_) or die("Could not parse '$svg'");
  }

  close(SVG);

  $handle -> close() or die("Could not parse '$svg'");

  $pixbuf = $handle -> get_pixbuf();

=head1 ABSTRACT

This module allows a Perl developer to use the Scalable Vector Graphics library
(librsvg for short).

=head1 SEE ALSO

L<Gnome2::Rsvg::index>(3pm), L<Gtk2>(3pm), L<Gtk2::api>(3pm) and
L<http://librsvg.sourceforge.net/docs/html/index.html>

=head1 AUTHOR

Torsten Schoenfeld E<lt>kaffeetisch@web.deE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003 by the gtk2-perl team

=cut
