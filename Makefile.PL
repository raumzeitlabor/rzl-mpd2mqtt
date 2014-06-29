use 5.006;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name     'RZL-MPD2MQTT';
all_from 'lib/RZL/MPD2MQTT.pm';
author   q{Simon Elsbrock <simon@iodev.org>};
license  'bsd';

perl_version 5.006;

tests_recursive('t');

resources (
   license    => 'http://www.opensource.org/licenses/BSD-3-Clause',
   repository => 'https://github.com/raumzeitlabor/rzl-mpd2mqtt.git',
   bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=RZL-MPD2MQTT',
);

configure_requires (
   'Module::Install' => 0,
);

build_requires (
   'Test::More' => 0,
);

requires (
    'JSON::XS' => 0,
    'YAML::Syck' => 0,
	'AnyEvent::MQTT' => 0,
    'AnyEvent::Socket' => 0,
    'Sys::Syslog' => 0,
);

install_script 'rzl-mpd2mqtt';

postamble <<'END_OF_MAKEFILE';
install:: extra_install
pure_install:: extra_install
install_vendor:: extra_install

extra_install:
	install -dm 755 $(DESTDIR)/etc
	install -m 640 rzl-mpd2mqtt.yml.ex $(DESTDIR)/etc/rzl-mpd2mqtt.yml
END_OF_MAKEFILE

WriteAll;
