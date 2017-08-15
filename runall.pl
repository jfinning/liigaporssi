#!/usr/bin/perl -w

use strict;
require "lp_cron.pl";

my @subs = ("nhl_sarjataulukko", "nhl_kokoonpanot", "nhl_ottelulista", "sm_sarjataulukko", "sm_ottelulista", "sm_kokoonpanot");

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
			if ($sub eq "sm_ottelulista") {
				push @subs, "sm_ottelu_id";
			}
		}
}
