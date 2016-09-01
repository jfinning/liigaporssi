#!/usr/bin/perl -w

use strict;
require "lp_cron.pl";

my @subs = ("nhl_sarjataulukko", "nhl_kokoonpanot", "sm_sarjataulukko", "sm_ottelu_id", "sm_kokoonpanot", "sm_kokoonpanot_kaikki");

foreach my $sub (@subs) {
	print "Trying to run sub $sub ... ";
	my %return = eval "$sub()";
	if ($return{'fail'}) {
		print "FAIL\n";
		print "    $return{'message'}\n";
		if ($sub eq "sm_kokoonpanot") {
			push @subs, "sm_kokoonpanot_kaikki";
		}
	} else {
		print "OK\n";
	}
}
