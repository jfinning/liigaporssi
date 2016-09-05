#!/usr/bin/perl -w

use strict;

my %return_value = (
	'fail' => 1
);

sub check_rights($$) {
	my ($username, $password) = @_;

	if ($username eq "Taalasmaa" && $password eq "Laitela") {
		$return_value{'fail'} = 0;
	}

	return %return_value;
}