use strict;

sub get_vuodet ($) {
    my @vuodet;
    my $liiga = shift;
    
    if ($liiga =~ /sm_liiga/) {
        @vuodet = ("2014", "2015", "2016", "2017", "2018");
    } else {
        @vuodet = ("2014", "2015", "2016", "2017");
    }
    
    return @vuodet;
}

sub get_jakso {
    return ("Jakso PO", "Jakso 5", "Jakso 4", "Jakso 3", "Jakso 2", "Jakso 1", "Jaksot 1-2", "Jaksot 1-3", "Jaksot 1-4", "Jaksot 1-5", "Jaksot 1-PO");
}

sub get_default_joukkueen_hinta { return "2000.0" };
sub get_default_ottelut { return 0 };
sub get_default_remove_players { return "" };
sub get_default_kokoonpanot { return "" };
sub get_default_liiga { return "sm_liiga" };
sub get_default_vuosi ($) {
    my $vuosi;
    my $liiga = shift;

    if ($liiga eq "sm_liiga") {
        $vuosi = 2018;
    } elsif ($liiga eq "nhl"){
        $vuosi = 2017;
	}

    return $vuosi;
}
sub get_liigat { return ("sm_liiga", "nhl"); }
sub get_default_sub { return "" };
sub get_default_graafi { return "LPP ennuste" };
sub get_default_joukkue { return "Joukkue" };
sub get_default_jakso ($) {
    my $jakso;
    my $liiga = shift;
    
    if ($liiga eq "sm_liiga") {
        $jakso = "Jakso 1";
    } elsif ($liiga eq "nhl"){
        $jakso = "Jakso PO";
    }
    
    return $jakso;
}

sub get_joukkue_list ($) {
    my $liiga = shift;
    my @joukkueet;

    if ($liiga =~ /sm_liiga/) {
        @joukkueet = ("HIFK", "HPK", "Ilves", "Jukurit", "JYP", "KalPa", "KooKoo", "Karpat", "Lukko", "Pelicans", "SaiPa", "Sport", "Tappara", "TPS", "Assat");
        #@joukkueet = ("HIFK", "Karpat", "Tappara", "TPS");
    } else {
        #@joukkueet = ("Anaheim", "Arizona", "Boston", "Buffalo", "Calgary", "Carolina", "Chicago", "Colorado", "Columbus", "Dallas", "Detroit", "Edmonton", "Florida", "Los Angeles", "Minnesota", "Montreal", "Nashville", "New Jersey", "NY Islanders", "NY Rangers", "Ottawa", "Philadelphia", "Pittsburgh", "San Jose", "St. Louis", "Tampa Bay", "Toronto", "Vancouver", "Vegas", "Washington", "Winnipeg");
        @joukkueet = ("Tampa Bay", "Vegas", "Washington", "Winnipeg");
    }
    
    return @joukkueet;    
}

sub get_joukkueiden_lyhenteet ($) {
    my $liiga = shift;
    my %joukkue_lyhenne = ();
    
    if ($liiga eq "nhl") {
        %joukkue_lyhenne = (
            "Anaheim"      => "ANA",
            "Arizona"      => "ARI",
            "Boston"       => "BOS",
            "Buffalo"      => "BUF",
            "Calgary"      => "CGY",
            "Carolina"     => "CAR",
            "Chicago"      => "CHI",
            "Colorado"     => "COL",
            "Columbus"     => "CLB",
            "Dallas"       => "DAL",
            "Detroit"      => "DET",
            "Edmonton"     => "EDM",
            "Florida"      => "FLA",
            "Los Angeles"  => "LOS",
            "Minnesota"    => "MIN",
            "Montreal"     => "MTL",
            "Nashville"    => "NSH",
            "New Jersey"   => "NJD",
            "NY Islanders" => "NYI",
            "NY Rangers"   => "NYR",
            "Ottawa"       => "OTT",
            "Philadelphia" => "PHI",
            "Phoenix"      => "PHO",
            "Pittsburgh"   => "PIT",
            "San Jose"     => "SJS",
            "St. Louis"    => "STL",
            "Tampa Bay"    => "TBL",
            "Toronto"      => "TOR",
            "Vancouver"    => "VAN",
            "Vegas"        => "VGK",
            "Washington"   => "WSH",
            "Winnipeg"     => "WPG"
        );
    }

    return %joukkue_lyhenne;
}

sub get_ottelulista_filename ($) {
    my $liiga = shift;
    
    return "team_stats/games_$liiga.txt";
}

sub get_sarjataulukko_filename ($) {
    my $liiga = shift;
    
    return "team_stats/table_$liiga.txt";
}

sub get_max_teams { return 10 };

sub get_ottelulista_link($) {
	my $liiga = shift;

	my $link = "https://www.liigaporssi.fi/sm-liiga/ottelupaiva";
	if ($liiga eq "nhl") {
		$link = "https://www.hockeygm.fi/nhl/ottelupaiva";
	}

	return $link;
}

sub modify_char ($) {
    my $text = shift;
    my $return = "";
    my @char = split(//, $text);
    foreach (@char) {
        my $c = ord($_);
        if ($c == 228) { $_ = "a"; }
        elsif ($c == 196) { $_ = "A"; }
        elsif ($c == 246) { $_ = "o"; }
        elsif ($c == 214) { $_ = "O"; }
        elsif ($c == 229) { $_ = "a"; }
        elsif ($c == 197) { $_ = "A"; }
        elsif ($c == 252) { $_ = "u"; }
        elsif ($c == 220) { $_ = "U"; }
        elsif ($c == 225) { $_ = "a"; }
        elsif ($c == 241) { $_ = "n"; }
        elsif ($c == 253) { $_ = "y"; }

		# Replace stars
		s/[^[:ascii:]]+/X/g;

        $return = "$return$_";
    }

    return $return;
}
1;