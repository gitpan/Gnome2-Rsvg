#!/usr/bin/perl -w
use 5.008;
use strict;
use ExtUtils::MakeMaker;
use Cwd;
use File::Spec;

# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Rsvg/Makefile.PL,v 1.9 2006/12/30 19:07:38 kaffeetisch Exp $

our %build_reqs = (
  'perl-ExtUtils-Depends'   => '0.20',
  'perl-ExtUtils-PkgConfig' => '1.03',
  'perl-Glib'               => '1.02',
  'perl-Gtk2'               => '1.02',
  'perl-Cairo'              => '1.00', # if librsvg >= 2.14.0
  'librsvg'                 => '2.12.0',
);

our %pm_reqs = (
  'Gtk2'                => $build_reqs{'perl-Gtk2'},
  'Glib'                => $build_reqs{'perl-Glib'},
  'ExtUtils::Depends'   => $build_reqs{'perl-ExtUtils-Depends'},
  'ExtUtils::PkgConfig' => $build_reqs{'perl-ExtUtils-PkgConfig'},
);

unless (eval "use ExtUtils::Depends $build_reqs{'perl-ExtUtils-Depends'};"
           . "use ExtUtils::PkgConfig $build_reqs{'perl-ExtUtils-PkgConfig'};"
           . "use Glib '$build_reqs{'perl-Glib'}';"
           . "use Gtk2 '$build_reqs{'perl-Gtk2'}';"
           . "use Glib::MakeHelper;"
	   . "use Gtk2::CodeGen;"
           . "1") {
  warn "$@\n";
  WriteMakefile(
    PREREQ_FATAL => 1,
    PREREQ_PM    => \%pm_reqs,
  );
  exit 1; # not reached
}

my %rsvg_pkgcfg = ExtUtils::PkgConfig->find("librsvg-2.0 >= $build_reqs{librsvg}");

###############################################################################

my $need_cairo = 0;
my @rsvg_version = split /\./, $rsvg_pkgcfg{modversion};
if ($rsvg_version[0] > 2 || ($rsvg_version[0] == 2 && $rsvg_version[1] >= 14)) {
  $need_cairo = 1;
  $pm_reqs{Cairo} = $build_reqs{'perl-Cairo'};
  unless (eval "use Cairo '$build_reqs{'perl-Cairo'}'; 1;") {
    warn "$@\n";
    WriteMakefile(
      PREREQ_FATAL => 1,
      PREREQ_PM    => \%pm_reqs,
    );
    exit 1; # not reached
  }
}

###############################################################################

mkdir 'build', 0777;

our @xs_files = <xs/*.xs>;
our %pod_files = (
  'Rsvg.pm' => '$(INST_MAN3DIR)/Gnome2::Rsvg.$(MAN3EXT)',
  Glib::MakeHelper->do_pod_files (@xs_files),
);

Gtk2::CodeGen->parse_maps ('rsvg2perl');
Gtk2::CodeGen->write_boot (ignore => qr/^Gnome2::Rsvg$/);

ExtUtils::PkgConfig->write_version_macros (
  "build/rsvg2perl-version.h",
  "librsvg-2.0" => "LIBRSVG",
);

###############################################################################

my @deps = $need_cairo ? qw(Gtk2 Cairo) : qw(Gtk2);
my $rsvg = ExtUtils::Depends->new ('Gnome2::Rsvg', @deps);
$rsvg->set_inc ($rsvg_pkgcfg{cflags});
$rsvg->set_libs ($rsvg_pkgcfg{libs});
$rsvg->add_xs (@xs_files);
$rsvg->add_pm ('Rsvg.pm' => '$(INST_LIBDIR)/Rsvg.pm');
$rsvg->add_typemaps (map { File::Spec->catfile (cwd(), $_) }
                       'rsvg.typemap',
                       'build/rsvg2perl.typemap');

$rsvg->install (qw(rsvg2perl.h
                   build/rsvg2perl-autogen.h
                   build/rsvg2perl-version.h
                   doctypes));
$rsvg->save_config ('build/IFiles.pm');

WriteMakefile(
  NAME            => 'Gnome2::Rsvg',
  VERSION_FROM    => 'Rsvg.pm', # finds $VERSION
  ABSTRACT_FROM   => 'Rsvg.pm', # retrieve abstract from module
  XSPROTOARG      => '-noprototypes',
  MAN3PODS        => \%pod_files,
  PREREQ_PM       => \%pm_reqs,
  $rsvg->get_makefile_vars,
);

###############################################################################

sub MY::postamble {
  return Glib::MakeHelper->postamble_clean ()
       . Glib::MakeHelper->postamble_docs_full (
		DEPENDS => $rsvg,
		DOCTYPES => 'doctypes',
		COPYRIGHT_FROM => 'copyright.pod'
         )
       . Glib::MakeHelper->postamble_rpms (
		'GNOME_RSVG' => $build_reqs{'librsvg'},
		'PERL_EXTUTILS_DEPENDS' =>
			$build_reqs{'perl-ExtUtils-Depends'},
		'PERL_EXTUTILS_PKGCONFIG' =>
			$build_reqs{'perl-ExtUtils-PkgConfig'},
		'PERL_GLIB' => $build_reqs{'perl-Glib'},
		'PERL_GTK' => $build_reqs{'perl-Gtk2'},
	);
}
