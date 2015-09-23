if ($param_liiga =~ /sm_liiga/) {
    @vuodet = ("2014", "2015");
} else {
    @vuodet = ("2014", "2015");
}

@jakso = ("Jakso PO", "Jakso 5", "Jakso 4", "Jakso 3", "Jakso 2", "Jakso 1", "Jaksot 1-2", "Jaksot 1-3", "Jaksot 1-4", "Jaksot 1-5", "Jaksot 1-PO");

if (!defined $param_joukkueen_hinta)   { $param_joukkueen_hinta = "2000.0"; }
if (!defined $param_ottelut)           { $param_ottelut = 0; }
if (!defined $param_remove_players)    { $param_remove_players = ""; }
if (!defined $param_kokoonpanot)       { $param_kokoonpanot = ""; }
if (!defined $param_vuosi) {
    if ($param_liiga eq "sm_liiga") {
        $param_vuosi = 2015;
    } else {
        $param_vuosi = 2015;
    }
}
if (!defined $param_sub)               { $param_sub = ""; }
if (!defined $param_graafi)            { $param_graafi = "LPP ennuste"; }
if (!defined $param_liiga)             { $param_liiga = "sm_liiga"; }
if (!defined $param_joukkue)           { $param_joukkue = "Joukkue"; }
if (!defined $param_read_players_from) {
    if ($param_liiga =~ /nhl/) {
        $param_read_players_from = "Jakso 2";
    } else {
        $param_read_players_from = "Jakso 3";
    }
}

# Pitaa muokata viela
my $player_list = "$param_vuosi/player_list_period3.txt";

if ($param_liiga =~ /sm_liiga/) {
    if ($param_vuosi == 2014) {
        $jaljella_olevat_joukkueet = "Blues, HIFK, HPK, Ilves, JYP, KalPa, Karpat, Lukko, Pelicans, SaiPa, Sport, Tappara, TPS, Assat";
    } else {
        $jaljella_olevat_joukkueet = "Blues, HIFK, HPK, Ilves, Jokerit, JYP, KalPa, Karpat, Lukko, Pelicans, SaiPa, Tappara, TPS, Assat";
    }
} else {
    if ($param_vuosi == 2014) {
        $jaljella_olevat_joukkueet = "Anaheim, Arizona, Boston, Buffalo, Calgary, Carolina, Chicago, Colorado, Columbus, Dallas, Detroit, Edmonton, Florida, Los Angeles, Minnesota, Montreal, Nashville, New Jersey, NY Islanders, NY Rangers, Ottawa, Philadelphia, Pittsburgh, San Jose, St. Louis, Tampa Bay, Toronto, Vancouver, Washington, Winnipeg";
    } else {
        $jaljella_olevat_joukkueet = "Anaheim, Boston, Buffalo, Calgary, Carolina, Chicago, Colorado, Columbus, Dallas, Detroit, Edmonton, Florida, Los Angeles, Minnesota, Montreal, Nashville, New Jersey, NY Islanders, NY Rangers, Ottawa, Philadelphia, Phoenix, Pittsburgh, San Jose, St. Louis, Tampa Bay, Toronto, Vancouver, Washington, Winnipeg";
    }
}
