#!/usr/bin/perl -w
use 5.008;
use strict;
use ExtUtils::MakeMaker;
use Cwd;
use File::Spec;

# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Rsvg/Makefile.PL,v 1.4 2004/02/14 15:40:10 kaffeetisch Exp $

our %build_reqs = (
  'perl-ExtUtils-Depends'   => '0.20',
  'perl-ExtUtils-PkgConfig' => '1.03',
  'perl-Glib'               => '1.01',
  'perl-Gtk2'               => '1.01',
  'Rsvg'                    => '2.0.0',
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
    PREREQ_PM    => {
      "Gtk2"                => $build_reqs{'perl-Gtk2'},
      "Glib"                => $build_reqs{'perl-Glib'},
      "ExtUtils::Depends"   => $build_reqs{'perl-ExtUtils-Depends'},
      "ExtUtils::PkgConfig" => $build_reqs{'perl-ExtUtils-PkgConfig'},
    },
  );
  exit 1; # not reached
}

my %rsvg_pkgcfg = ExtUtils::PkgConfig->find("librsvg-2.0 >= $build_reqs{Rsvg}");

###############################################################################

mkdir 'build', 0777;

chomp(my $rsvg_includes = `pkg-config --variable includedir librsvg-2.0`);
my @rsvg_headers = glob($rsvg_includes . "/librsvg-2/librsvg/*.h");

system(q(glib-mkenums --fhead "#ifndef __RSVG2PERL_GTYPES_H__\n" ) .
                    q(--fhead "#define __RSVG2PERL_GTYPES_H__ 1\n\n" ) .
                    q(--fhead "#include <glib-object.h>\n\n" ) .
                    q(--fhead "G_BEGIN_DECLS\n\n" ) .
                    q(--eprod "#define RSVG2PERL_TYPE_@ENUMSHORT@ rsvg2perl_@enum_name@_get_type()\n" ) .
                    q(--eprod "GType rsvg2perl_@enum_name@_get_type (void);\n" ) .
                    q(--ftail "G_END_DECLS\n\n" ) .
                    q(--ftail "#endif /* __RSVG2PERL_GTYPES_H__ */\n" ) .
                    "@rsvg_headers > build/rsvg2perl-gtypes.h");

system(q(glib-mkenums --fhead "#include <librsvg/rsvg.h>\n" ) .
                    q(--vhead "static const G@Type@Value _rsvg2perl_@enum_name@_values[] = {" ) .
                    q(--vprod "  { @VALUENAME@, \"@VALUENAME@\", \"@valuenick@\" }," ) .
                    q(--vtail "  { 0, NULL, NULL }\n};\n\n" ) .
                    q(--vtail "GType\nrsvg2perl_@enum_name@_get_type (void)\n{\n" ) .
                    q(--vtail "  static GType type = 0;\n\n" ) .
                    q(--vtail "  if (!type)\n" ) .
                    q(--vtail "    type = g_@type@_register_static (\"@EnumName@\", _rsvg2perl_@enum_name@_values);\n\n" ) .
                    q(--vtail "  return type;\n}\n\n" ) .
                    "@rsvg_headers > build/rsvg2perl-gtypes.c");

###############################################################################

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

my $rsvg = ExtUtils::Depends->new ('Gnome2::Rsvg', 'Gtk2');
$rsvg->set_inc ($rsvg_pkgcfg{cflags});
$rsvg->set_libs ($rsvg_pkgcfg{libs});
$rsvg->add_xs (@xs_files);
$rsvg->add_c ("rsvg2perl.c", "build/rsvg2perl-gtypes.c");
$rsvg->add_pm ('Rsvg.pm' => '$(INST_LIBDIR)/Rsvg.pm');
$rsvg->add_typemaps (map {File::Spec->catfile(cwd(), $_)} 'build/rsvg2perl.typemap');

$rsvg->install (qw(rsvg2perl.h
                   build/rsvg2perl-autogen.h
                   build/rsvg2perl-version.h
                   build/rsvg2perl-gtypes.h));
$rsvg->save_config ('build/IFiles.pm');

WriteMakefile(
  NAME            => 'Gnome2::Rsvg',
  VERSION_FROM    => 'Rsvg.pm', # finds $VERSION
  ABSTRACT_FROM   => 'Rsvg.pm', # retrieve abstract from module
  XSPROTOARG      => '-noprototypes',
  MAN3PODS        => \%pod_files,
  $rsvg->get_makefile_vars,
);

###############################################################################

sub MY::postamble {
  return Glib::MakeHelper->postamble_clean ()
       . Glib::MakeHelper->postamble_docs_full (
		DEPENDS => $rsvg,
		COPYRIGHT_FROM => 'copyright.pod'
         )
       . Glib::MakeHelper->postamble_rpms (
		'GNOME_RSVG' => $build_reqs{'Rsvg'},
		'PERL_EXTUTILS_DEPENDS' => 
			$build_reqs{'perl-ExtUtils-Depends'},
		'PERL_EXTUTILS_PKGCONFIG' => 
			$build_reqs{'perl-ExtUtils-PkgConfig'},
		'PERL_GLIB' => $build_reqs{'perl-Glib'},
		'PERL_GTK' => $build_reqs{'perl-Gtk2'},
	);
}
