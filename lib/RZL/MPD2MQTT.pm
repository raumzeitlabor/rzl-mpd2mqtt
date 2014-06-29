package RZL::MPD2MQTT;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Data::Dump;

use JSON::XS;
use Sys::Syslog;
use YAML::Syck;
use AnyEvent::MQTT;
use AnyEvent::Socket;

$|++;

=head1 NAME

RZL::MPD2MQTT - The great new RZL::MPD2MQTT!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

my $cfg;
if (-e 'rzl-mpd2mqtt.yml') {
    $cfg = LoadFile('rzl-mpd2mqtt.yml');
} elsif (-e '/etc/rzl-mpd2mqtt.yml') {
    $cfg = LoadFile('/etc/rzl-mpd2mqtt.yml');
} else {
    die "Could not load ./rzl-mpd2mqtt.yml or /etc/rzl-mpd2mqtt.yml";
}

if (!exists($cfg->{MPD}) || !exists($cfg->{MQTT})) {
    die "Configuration sections incomplete: need 'MPD' and 'MQTT'";
}

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use RZL::MPD2MQTT;

    my $foo = RZL::MPD2MQTT->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub run {
    my $mqtt = AnyEvent::MQTT->new(
        host => $cfg->{MQTT}->{host},
        timeout => $cfg->{MQTT}->{timeout},
        keep_alive_timer => $cfg->{MQTT}->{keepalive},
        clean_session => $cfg->{MQTT}->{cleansession},
        client_id => $cfg->{MQTT}->{clientid},
        message_log_callback => sub {
            syslog('debug', join (',', @_));
        },
    );

    my $cv = AE::cv;
    my ($oldstate, $oldsongstate, $w, $pubcv) = ("", "");

    tcp_connect $cfg->{MPD}->{host}, 6600, sub {
        my ($fh) = @_ or die "unable to connect: $!";
        print "connected\n";
 
        my $handle;
        $handle = new AnyEvent::Handle
           fh     => $fh,
           on_error => sub {
              AE::log error => $_[2];
              $_[0]->destroy;
           },
           on_eof => sub {
              $handle->destroy; # destroy handle
              AE::log info => "Done.";
           };

        # skip the first line (mpd version info)
        $handle->push_read (line => sub {});

        $w = AnyEvent->timer(
            interval => 1,
            cb => sub {
                $handle->push_read (regex => qr<OK\n>, sub {
                    my ($handle, $line) = @_;
                    my %state = $line =~ /([^:]+):\s*([^\n]+)\n/gx;

                    if (defined $state{state}) {
                        my $newstate = $state{state};

                        if ($newstate ne $oldstate) {
                            $oldstate = $newstate;
                            $mqtt->publish(
                                topic => '/service/mpd/state',
                                message => '"'.$state{state}.'"',
                                retain => 1
                            );
                        }

                        $handle->push_write("status\n");

                    } else {

                        my $newsongstate = $line;
                        delete $state{qw/Time Last-Modified/};

                        if ($newsongstate ne $oldsongstate) {
                            $oldsongstate = $line;
                            $mqtt->publish(
                                topic => '/service/mpd/song',
                                message => encode_json(\%state),
                                retain => 1
                            );
                        }

                        $handle->push_write("currentsong\n");
                    }
                });
            }
        );
        
        $handle->push_write("status\n");
        $handle->push_write("currentsong\n");
    };

    $cv->recv;
}

=head1 AUTHOR

Simon Elsbrock, C<< <simon at iodev.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rzl-mpd2mqtt at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RZL-MPD2MQTT>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RZL::MPD2MQTT


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RZL-MPD2MQTT>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RZL-MPD2MQTT>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RZL-MPD2MQTT>

=item * Search CPAN

L<http://search.cpan.org/dist/RZL-MPD2MQTT/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Simon Elsbrock.

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

* Neither the name of Simon Elsbrock's Organization
nor the names of its contributors may be used to endorse or promote
products derived from this software without specific prior written
permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of RZL::MPD2MQTT
