#!/usr/bin/perl -w
use strict;
use Test::More tests => 183;
use Gnome2::Rsvg;

my $number = qr/^\d+$/;

my $size_callback = sub {
  my ($width, $height) = @_;

  like($width, $number);
  like($height, $number);

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

  ok(defined($handle -> get_title()));
  ok(defined($handle -> get_desc()));
}

###############################################################################

foreach (Gnome2::Rsvg -> pixbuf_from_file($svg),
         Gnome2::Rsvg -> pixbuf_from_file_at_zoom($svg, 1.5, 1.5),
         Gnome2::Rsvg -> pixbuf_from_file_at_size($svg, 23, 42),
         Gnome2::Rsvg -> pixbuf_from_file_at_max_size($svg, 23, 42),
         Gnome2::Rsvg -> pixbuf_from_file_at_zoom_with_max($svg, 1.5, 1.5, 23, 42)) {
  isa_ok($_, "Gtk2::Gdk::Pixbuf");
}

###############################################################################

SKIP: {
  skip("set_default_dpi, set_dpi, and new_gz are new in 2.2.0", 6)
    unless (Gnome2::Rsvg -> CHECK_VERSION(2, 2, 0));

  Gnome2::Rsvg -> set_default_dpi(96);
  $handle -> set_dpi(96);

  my $handle_gz = Gnome2::Rsvg::Handle -> new_gz();
  isa_ok($handle_gz, "Gnome2::Rsvg::Handle");

  SKIP: {
    skip("couldn't open test image", 5)
      unless (open(SVG, $svg_gz));

    undef $/;
    ok($handle_gz -> write(<SVG>));

    close(SVG);

    ok($handle_gz -> close());

    my $pixbuf_gz = $handle_gz -> get_pixbuf();
    isa_ok($pixbuf_gz, "Gtk2::Gdk::Pixbuf");

    like($pixbuf_gz -> get_width(), $number);
    like($pixbuf_gz -> get_height(), $number);
  }
}

###############################################################################

SKIP: {
  skip("*_ex are new in 2.2.2", 5)
    unless (Gnome2::Rsvg -> CHECK_VERSION(2, 2, 2));

  $handle = Gnome2::Rsvg::Handle -> new();
  isa_ok($handle -> pixbuf_from_file_ex($svg), "Gtk2::Gdk::Pixbuf");

  $handle = Gnome2::Rsvg::Handle -> new();
  isa_ok($handle -> pixbuf_from_file_at_zoom_ex($svg, 1.5, 1.5), "Gtk2::Gdk::Pixbuf");

  $handle = Gnome2::Rsvg::Handle -> new();
  isa_ok($handle -> pixbuf_from_file_at_size_ex($svg, 23, 42), "Gtk2::Gdk::Pixbuf");

  $handle = Gnome2::Rsvg::Handle -> new();
  isa_ok($handle -> pixbuf_from_file_at_max_size_ex($svg, 23, 42), "Gtk2::Gdk::Pixbuf");

  $handle = Gnome2::Rsvg::Handle -> new();
  isa_ok($handle -> pixbuf_from_file_at_zoom_with_max_ex($svg, 1.5, 1.5, 23, 42), "Gtk2::Gdk::Pixbuf");
}

###############################################################################

SKIP: {
  skip("set_default_dpi_x_y and set_dpi_x_y are new in 2.8", 0)
    unless (Gnome2::Rsvg -> CHECK_VERSION(2, 7, 5)); # FIXME: 2.8

  Gnome2::Rsvg -> set_default_dpi_x_y(96, 96);
  $handle -> set_dpi_x_y(96, 96);
}
