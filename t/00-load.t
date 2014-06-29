#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'RZL::MPD2MQTT' ) || print "Bail out!\n";
}

diag( "Testing RZL::MPD2MQTT $RZL::MPD2MQTT::VERSION, Perl $], $^X" );
