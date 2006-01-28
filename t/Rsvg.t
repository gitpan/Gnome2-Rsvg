#!/usr/bin/perl -w
use strict;
use Test::More tests => 177;
use Gnome2::Rsvg;

my $number = qr/^\d+$/;

my $size_callback = sub {
  my ($width, $height) = @_;

  my $been_here = 0 if 0;
  unless ($been_here) {
    $been_here = 1;
    like($width, $number);
    like($height, $number);
  }

  return ($width * 2,
          $height * 2);
};

my $svg = "t/window.svg";
my $svg_gz = "t/window.svg.gz";

###############################################################################

my $handle = Gnome2::Rsvg::Handle -> new();
isa_ok($handle, "Gnome2::Rsvg::Handle");

$handle -> set_size_callback($size_callback);

SKIP: {
  skip("couldn't open test image", 164)
    unless (open(SVG, $svg));

  while (<SVG>) {
    ok($handle -> write($_));
  }

  close(SVG);

  ok($handle -> close());

  my $pixbuf = $handle -> get_pixbuf();
  isa_ok($pixbuf, "Gtk2::Gdk::Pixbuf");

  like($pixbuf -> get_width(), $number);
  like($pixbuf -> get_height(), $number);
}

SKIP: {
  skip("get_title and get_desc are new in 2.4", 2)
    unless (Gnome2::Rsvg -> CHECK_VERSION(2, 4, 0));

  is($handle -> get_title(), "Urgs");
  is($handle -> get_desc(), "Urgs");
}

###############################################################################

use Cwd qw(cwd);
my $uri = cwd() . "/" . $svg;

# Bug in librsvg: no relative paths?

foreach (Gnome2::Rsvg -> pixbuf_from_file($uri),
         Gnome2::Rsvg -> pixbuf_from_file_at_zoom($uri, 1.5, 1.5),
         Gnome2::Rsvg -> pixbuf_from_file_at_size($uri, 23, 42),
         Gnome2::Rsvg -> pixbuf_from_file_at_max_size($uri, 23, 42),
         Gnome2::Rsvg -> pixbuf_from_file_at_zoom_with_max($uri, 1.5, 1.5, 23, 42)) {
  isa_ok($_, "Gtk2::Gdk::Pixbuf");
}

###############################################################################

SKIP: {
  skip("set_default_dpi and set_dpi are new in 2.8", 0)
    unless (Gnome2::Rsvg -> CHECK_VERSION(2, 8, 0));

  Gnome2::Rsvg -> set_default_dpi(96);
  $handle -> set_dpi(96);
}

SKIP: {
  skip("[sg]et_base_uri and get_metadata are new in 2.10", 2)
    unless (Gnome2::Rsvg -> CHECK_VERSION(2, 10, 0));

  $handle -> set_base_uri("file:///tmp/window.svg");
  is($handle -> get_base_uri(), "file:///tmp/window.svg");

  is($handle -> get_metadata(), "Urgs");
}
