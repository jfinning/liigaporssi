#!E:\Ohjelmat\perl64\bin\perl.exe -w
#/usr/bin/perl -w

use strict;
use CGI::Carp qw(fatalsToBrowser);
use CGI qw(:standard);
use FindBin;
use lib $FindBin::Bin;

BEGIN {
    # https://www.perlmonks.org/?node_id=1191946;displaytype=print;replies=1
    # look for JSON::XS, and if not available, fall
    # back to JSON::PP to avoid requiring non-core modules

    my $json_ok = eval {
        require JSON::XS;
        JSON::XS->import;
        1;
    };
    if (! $json_ok){
        require JSON::PP;
        JSON::PP->import;
    }
}

require "modules/lp_settings.pm";
require "modules/lp_common_functions.pl";
require "modules/lp_update_check_rights.pl";
require "lp_cron.pl";

my %liiga_data;
my @liigat = get_liigat();

my $cgi = new CGI;
my $sub = $cgi->param('sub');
my $update_type = $cgi->param('update_type');
my $password = $cgi->param('password');
my $username = $cgi->param('username');
my %return;

sub get_settings() {
	foreach my $liiga (@liigat) {
		$liiga_data{$liiga}{liiga} = $liiga;
		if (!defined $liiga_data{$liiga}{vuosi}) {
			$liiga_data{$liiga}{vuosi} = get_default_vuosi($liiga);
		}
		if (!defined $liiga_data{$liiga}{jakso}) {
			$liiga_data{$liiga}{jakso} = get_default_jakso($liiga);
		}
	}

	return %liiga_data;
}

sub update_given_data () {
	update_data($update_type);
}

sub update_data(@) {
	my @subs = @_;

	foreach my $sub (@subs) {
		%return = eval "$sub()";
		if ($return{'fail'}) {
			if ($sub eq "sm_kokoonpanot") {
				push @subs, "sm_kokoonpanot_kaikki";
			}
		} else {
			if ($sub eq "sm_ottelulista") {
				push @subs, "sm_ottelu_id";
			}
		}
	}
	
	return %return;
}

sub check_user_rights {
	return check_rights(($username, $password));
}

print $cgi->header('text/plain;charset=UTF-8'); 
my %result = eval "$sub()";

my $json = encode_json \%result;
print $json;