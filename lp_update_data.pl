#!E:\Ohjelmat\perl64\bin\perl.exe -w

use strict;
use CGI::Carp qw(fatalsToBrowser);
use CGI qw(:standard);
use CGI::Ajax;
use HTML::Parser;
require "lp_settings.pm";
require "lp_common_functions.pl";
require "lp_cron.pl";

my %liiga_data;
my @liigat = get_liigat();

my $cgi = new CGI;
my $sub = $cgi->param('sub');
my $update_type = $cgi->param('update_type');

sub get_variables() {
	foreach my $liiga (@liigat) {
		print "liiga $liiga";
		if (!defined $liiga_data{$liiga}{vuosi}) {
			$liiga_data{$liiga}{vuosi} = get_default_vuosi($liiga);
			print ", vuosi $liiga_data{$liiga}{vuosi}";
		}
		if (!defined $liiga_data{$liiga}{jakso}) {
			$liiga_data{$liiga}{jakso} = get_default_jakso($liiga);
			print ", jakso $liiga_data{$liiga}{jakso}";
		}
		print "<br>";
	}
}

sub update_given_data () {
	update_data($update_type);
}

sub update_data(@) {
	my @subs = @_;

	foreach my $sub (@subs) {
		print "Trying to run sub $sub ... ";
		my %return = eval "$sub()";
		if ($return{'fail'}) {
			print "FAIL<br>\n";
			print "    $return{'message'}<br>\n";
			if ($sub eq "sm_kokoonpanot") {
				push @subs, "sm_kokoonpanot_kaikki";
			}
		} else {
			print "OK<br>\n";
			if ($sub eq "sm_ottelulista") {
				push @subs, "sm_ottelu_id";
			}
		}
	}
}

print $cgi->header('text/plain;charset=UTF-8'); 
eval "$sub()";