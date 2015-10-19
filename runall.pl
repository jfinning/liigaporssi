#!/usr/bin/perl -w

use strict;
require "lp_cron.pl";

print "Update sm_sarjataulukko\n";
sm_sarjataulukko();

print "Trying to update sm_kokoonpanot...";
my $success = sm_kokoonpanot();
if (!$success) {
	print "Failed\n";
	print "Update sm_kokoonpanot_kaikki\n";
	sm_kokoonpanot_kaikki();
} else { print "OK\n"; }

print "Update sm_ottelu_id\n";
sm_ottelu_id();

print "Update nhl_sarjataulukko\n";
nhl_sarjataulukko();

print "Update nhl_kokoonpanot\n";
nhl_kokoonpanot();
