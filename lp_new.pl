#!/usr/bin/perl -w
#E:\Ohjelmat\perl64\bin\perl.exe -w

use strict;
use CGI::Carp qw(fatalsToBrowser);
use CGI qw(:standard);
use HTML::Parser;
use JSON::XS;
#use JSON;
require "modules/lp_settings.pm";
require "modules/lp_common_functions.pl";

my $cgi = new CGI;

my %result;
my %kotipelit;
my %vieraspelit;
my %kaikkipelit;
my %taulukko;
my %vastus;
my @all_day_list;
my @selected_day_list;
my @weekdays;
my %pelipaivat;
my %joukkue_lyhenne;
my $max_pelatut_pelit = 0;
my $max_teams = get_max_teams();
my $timing = 0; #Tama on koodin nopeuden mittaukseen

my $pelaaja = {};

my $o_maalivahti = "Kaikki M";
my $o_puolustaja1 = "Kaikki P1";
my $o_puolustaja2 = "Kaikki P2";
my $o_hyokkaaja1 = "Kaikki H1";
my $o_hyokkaaja2 = "Kaikki H2";
my $o_hyokkaaja3 = "Kaikki H3";

my $maalivahti = "";
my $puolustaja1 = "";
my $puolustaja2 = "";
my $hyokkaaja1 = "";
my $hyokkaaja2 = "";
my $hyokkaaja3 = "";

my @maalivahdit_kaikki = ();
my @puolustajat_kaikki = ();
my @hyokkaajat_kaikki = ();

my $start                   = $cgi->param('start_day');
my $end                     = $cgi->param('end_day');
my $team_from               = $cgi->param('team_from');
my $param_sub               = $cgi->param('sub');
my $param_ottelut           = $cgi->param('ottelut');
my $param_arvo              = $cgi->param('arvo');
my $param_lpp               = $cgi->param('lpp');
my $param_joukkue           = $cgi->param('joukkue');
my $param_remove_players    = $cgi->param('remove_players');
my $param_kokoonpanot       = $cgi->param('kokoonpanot');
my $param_selected_teams    = $cgi->param('selected_teams');
my $param_read_players_from = $cgi->param('read_players_from');
my $param_joukkueen_hinta   = $cgi->param('joukkueen_hinta');
my $param_vuosi             = $cgi->param('vuosi');
my $param_liiga             = $cgi->param('liiga');
my $param_game_nro          = $cgi->param('game_nro');
if (!defined $param_joukkueen_hinta)   { $param_joukkueen_hinta = get_default_joukkueen_hinta(); }
if (!defined $param_ottelut)           { $param_ottelut = get_default_ottelut(); }
if (!defined $param_remove_players)    { $param_remove_players = get_default_remove_players(); }
if (!defined $param_kokoonpanot)       { $param_kokoonpanot = get_default_kokoonpanot(); }
if (!defined $param_liiga)             { $param_liiga = get_default_liiga(); }
if (!defined $param_vuosi)             { $param_vuosi = get_default_vuosi($param_liiga); }
if (!defined $param_sub)               { $param_sub = get_default_sub(); }
if (!defined $param_joukkue)           { $param_joukkue = get_default_joukkue(); }
if (!defined $param_read_players_from) { $param_read_players_from = get_default_jakso($param_liiga); }

my ($pelit, $sarjataulukko);
sub alustus {
    %joukkue_lyhenne = get_joukkueiden_lyhenteet($param_liiga);

    $o_maalivahti  = $cgi->param('o_maalivahti') if defined $cgi->param('o_maalivahti');
    $o_puolustaja1 = $cgi->param('o_puolustaja1') if defined $cgi->param('o_puolustaja1');
    $o_puolustaja2 = $cgi->param('o_puolustaja2') if defined $cgi->param('o_puolustaja2');
    $o_hyokkaaja1  = $cgi->param('o_hyokkaaja1') if defined $cgi->param('o_hyokkaaja1');
    $o_hyokkaaja2  = $cgi->param('o_hyokkaaja2') if defined $cgi->param('o_hyokkaaja2');
    $o_hyokkaaja3  = $cgi->param('o_hyokkaaja3') if defined $cgi->param('o_hyokkaaja3');

    if ($o_maalivahti =~ /^(.*?)\s*,/) { $o_maalivahti = $1; }
    if ($o_puolustaja1 =~ /^(.*?)\s*,/) { $o_puolustaja1 = $1; }
    if ($o_puolustaja2 =~ /^(.*?)\s*,/) { $o_puolustaja2 = $1; }
    if ($o_hyokkaaja1 =~ /^(.*?)\s*,/) { $o_hyokkaaja1 = $1; }
    if ($o_hyokkaaja2 =~ /^(.*?)\s*,/) { $o_hyokkaaja2 = $1; }
    if ($o_hyokkaaja3 =~ /^(.*?)\s*,/) { $o_hyokkaaja3 = $1; }

    $pelit = get_ottelulista_filename($param_liiga);
    $sarjataulukko = get_sarjataulukko_filename($param_liiga);
    
    # Nama tehdaan loopissa olevien ehtojen takia
    if ($o_puolustaja2 =~ /Kaikki/ && $o_puolustaja1 !~ /Kaikki/) {
        $o_puolustaja2 = $o_puolustaja1;
        $o_puolustaja1 = "Kaikki P1";
    }
    if ($o_hyokkaaja2 =~ /Kaikki/ && $o_hyokkaaja1 !~ /Kaikki/) {
        $o_hyokkaaja2 = $o_hyokkaaja1;
        $o_hyokkaaja1 = "Kaikki H1";
    }
    if ($o_hyokkaaja3 =~ /Kaikki/) {
        $o_hyokkaaja3 = $o_hyokkaaja1;
        $o_hyokkaaja1 = "Kaikki H1";
    }
    if ($o_hyokkaaja3 =~ /Kaikki/) {
        $o_hyokkaaja3 = $o_hyokkaaja2;
        $o_hyokkaaja2 = "Kaikki H2";
    }

    open TAULUKKO, "$sarjataulukko" or die "Cant open $sarjataulukko\n"; 
    while (<TAULUKKO>) {
        s/\s*$//;

        if ((/(\d+)\.\s*(.*?)\s*(\d+)\s*(\d+)\s*/ && $param_liiga eq "sm_liiga") || (/(\d+)\.\s*(.*?)\s*(\d+)\s*.*?\s*(\d+)\s*(\d\.\d\d)\s*$/ && $param_liiga eq "nhl")) {
            $taulukko{$2}{sija} = $1;
            $taulukko{$2}{pelit} = $3;
            $taulukko{$2}{pisteet} = $4;
        }
    }
    close (TAULUKKO);

    my $start_found = 0;
    my $end_found = 0;
    my $last_day_found = 0;
    my $pelipaiva;
    my $weekday;
    my $game_id_found = 0;
    open PELIT, "$pelit" or die "Cant open $pelit\n"; 
    while (<PELIT>) {
        s/\s*$//;

        if (/(\d\d\.\d\d\.)/) {
            push (@all_day_list, $1);
            if (! defined $start) { $start = $1; }
        }

        if (/\s*(\w+)\s+\d\d\.\d\d\./) {
            $weekday = $1;
        }
    
        if (defined $start && /$start/) { $start_found = 1; }
        if (! $start_found) { next; }
        if ($end_found) { next; }

        if ($last_day_found && /\d\d\.\d\d\./) {
            $end_found = 1;
            next;
        }

        if (/(\d\d\.\d\d\.)/) {
            push (@selected_day_list, $1);
            push (@weekdays, $weekday);
            $pelipaiva = $1;
        }

        if (defined $end && /$end/) {
            $last_day_found = 1;
        }

        if (/\s*(\D*?)\s*-\s*(.*?)\s*,\s*(\d+)\s*$/ || /\s*(\D*?)\s*-\s*(.*?)\s*$/) {
            $kotipelit{$1}++;
            $vieraspelit{$2}++;
            $kaikkipelit{$1}++;
            $kaikkipelit{$2}++;
			
			foreach ($1, $2) {
			    if (! defined $kaikkipelit{$_}) { $kaikkipelit{$_} = 0; }
			    if (! defined $kotipelit{$_})   { $kotipelit{$_} = 0; }
			    if (! defined $vieraspelit{$_}) { $vieraspelit{$_} = 0; }
			    if (! defined $vastus{$_}{top}) { $vastus{$_}{top} = 0; }
			    if (! defined $vastus{$_}{mid}) { $vastus{$_}{mid} = 0; }
			    if (! defined $vastus{$_}{low}) { $vastus{$_}{low} = 0; }
			}

            $pelipaivat{$1}{$pelipaiva}{kotipeli} = $2;
            $pelipaivat{$2}{$pelipaiva}{vieraspeli} = $1;

            if (defined $3) {
                $pelipaivat{$1}{$pelipaiva}{kokoonpano} = $3;
                $pelipaivat{$2}{$pelipaiva}{kokoonpano} = $3;
                $game_id_found = 1;
            }

            if ($taulukko{$1}{sija} <= 5) {
                $vastus{$2}{top}++;
            } elsif ($taulukko{$1}{sija} <= 10) {
                $vastus{$2}{mid}++;
            } else {
                $vastus{$2}{low}++;
            }

            if ($taulukko{$2}{sija} <= 5) {
                $vastus{$1}{top}++;
            } elsif ($taulukko{$2}{sija} <= 10) {
                $vastus{$1}{mid}++;
            } else { 
                $vastus{$1}{low}++;
            }
        }
    }
    close (PELIT);

    if (! defined $end) {
        $end = $all_day_list[-1];
    }

    if (! defined $team_from || ! defined $kaikkipelit{$team_from}) {
        foreach (sort keys %kaikkipelit) {
            $team_from = $_;
	        last;
        }
    }
}

sub muuttujien_alustusta ($) {
    my $temp = shift;
    
    if ($temp =~ /paikka/) {
        my @paikka = (
            [ "$o_maalivahti", "Kaikki M", \@maalivahdit_kaikki, "M", "o_maalivahti", "$maalivahti" ],
            [ "$o_puolustaja1", "Kaikki P1", \@puolustajat_kaikki, "P1", "o_puolustaja1", "$puolustaja1" ],
            [ "$o_puolustaja2", "Kaikki P2", \@puolustajat_kaikki, "P2", "o_puolustaja2", "$puolustaja2" ],
            [ "$o_hyokkaaja1", "Kaikki H1", \@hyokkaajat_kaikki, "H1", "o_hyokkaaja1", "$hyokkaaja1" ],
            [ "$o_hyokkaaja2", "Kaikki H2", \@hyokkaajat_kaikki, "H2", "o_hyokkaaja2", "$hyokkaaja2" ],
            [ "$o_hyokkaaja3", "Kaikki H3", \@hyokkaajat_kaikki, "H3", "o_hyokkaaja3", "$hyokkaaja3" ],
        );
        return @paikka;
    }
}

sub selectedTeams {
	if (!defined $param_selected_teams || $param_selected_teams =~ /^\s*$/) {
        foreach (sort keys %taulukko) {
            $param_selected_teams .= "$_, ";
        }
        $param_selected_teams =~ s/,\s*$//;
    }

	return $param_selected_teams;
}

sub hashValueAscendingNum {
   $kaikkipelit{$b} <=> $kaikkipelit{$a} || $kotipelit{$b} <=> $kotipelit{$a} || $vastus{$b}{low} <=> $vastus{$a}{low} || $vastus{$b}{mid} <=> $vastus{$a}{mid} || $a cmp $b;
}

sub gameDays {
    my $html;
    # lasketaan onko 3 (tai enemman) pelia tai lepoa putkeen
    my %peliputki;
    my $paiva = "";
    my $amount;
    my $alku;
    foreach my $joukkue (sort hashValueAscendingNum keys %kaikkipelit) {
        $paiva = "";
        my @paivat = ();
        foreach my $day (@selected_day_list) {
            if (! defined $pelipaivat{$joukkue}{$day}) {
                if ($paiva eq "") { $paiva = "lepo"; }
                if ($paiva eq "lepo") {
                    push (@paivat, $day);
                } else {
                    if ($#paivat >= 2) {
                        foreach (@paivat) {
                            $peliputki{$joukkue}{$_} = "peli";
                        }
                    }
                    @paivat = "$day";
                }
                $paiva = "lepo";
            } else {
                if ($paiva eq "") { $paiva = "lepo"; }
                if ($paiva eq "peli") {
                    push (@paivat, $day);
                } else {
                    if ($#paivat >= 2) {
                        foreach (@paivat) {
                            $peliputki{$joukkue}{$_} = "lepo";
                        }
                    }
                    @paivat = "$day";
                }
                $paiva = "peli";
            }
        }
        if ($#paivat >= 2) {
            foreach (@paivat) {
                $peliputki{$joukkue}{$_} = $paiva;
            }
        }
    }

    $html .= "<table border='1' class='w3-text-black w3-striped w3-white'>\n";
    $html .= "<tr class='w3-black w3-center'>\n";
    
    # Tulosta pelipäivät
    $html .= "<th>Joukkue</th>\n";
    my $count = 0;
    foreach (@selected_day_list) {
        $html .= "<th>$weekdays[$count]<br>\n$_</th>\n";
        $count++;
    }

    # Tulosta joukkueet ja pelaako
    foreach my $joukkue (sort hashValueAscendingNum keys %kaikkipelit) {
        $html .= "<tr>\n";
        $html .= "<th class='w3-black'>$joukkue</th>\n";
        foreach (@selected_day_list) {
            if (! defined $pelipaivat{$joukkue}{$_}) {
                if (defined $peliputki{$joukkue}{$_} && $peliputki{$joukkue}{$_} eq "lepo") {
                    $html .= "<td class='w3-text-red w3-center' title='3 tai useampi vapaata putkeen'><b>x</b></td>\n";
                } else {
                    $html .= "<td class='w3-center'>-</td>\n";
                }
            } elsif (defined $pelipaivat{$joukkue}{$_}{kotipeli}) {
                my $kotipeli = $pelipaivat{$joukkue}{$_}{kotipeli};
                if (defined $joukkue_lyhenne{$pelipaivat{$joukkue}{$_}{kotipeli}}) {
                    $kotipeli =  $joukkue_lyhenne{$pelipaivat{$joukkue}{$_}{kotipeli}};
                }
                if (defined $pelipaivat{$joukkue}{$_}{'kokoonpano'}) {
					$kotipeli = "<A HREF='#' onclick=\"Kokoonpanot('$joukkue', '$pelipaivat{$joukkue}{$_}{kokoonpano}');showLinkDiv('Kokoonpanot');markClickedTab('Kokoonpanot')\">$kotipeli</A>";
                }
                if (defined $peliputki{$joukkue}{$_} && $peliputki{$joukkue}{$_} eq "peli") {
                    $html .= "<td class='w3-text-teal w3-center' title='3 tai useampi peli&#228; putkeen'><b>$kotipeli</b></td>\n";
                } else {
                    $html .= "<td class='w3-center'><b>$kotipeli</b></td>\n";
                }
            } elsif (defined $pelipaivat{$joukkue}{$_}{vieraspeli}) {
                my $vieraspeli = $pelipaivat{$joukkue}{$_}{vieraspeli};
                if (defined $joukkue_lyhenne{$pelipaivat{$joukkue}{$_}{vieraspeli}}) {
                    $vieraspeli =  $joukkue_lyhenne{$pelipaivat{$joukkue}{$_}{vieraspeli}};
                }
                if (defined $pelipaivat{$joukkue}{$_}{'kokoonpano'}) {
					$vieraspeli = "<A HREF='#' onclick=\"Kokoonpanot('$vieraspeli', '$pelipaivat{$joukkue}{$_}{kokoonpano}');showLinkDiv('Kokoonpanot');markClickedTab('Kokoonpanot')\">$vieraspeli</A>";
                }
                if (defined $peliputki{$joukkue}{$_} && $peliputki{$joukkue}{$_} eq "peli") {
                    $html .= "<td class='w3-text-teal w3-center' title='3 tai useampi peli&#228; putkeen'>$vieraspeli</td>\n";
                } else {
                    $html .= "<td class='w3-center'>$vieraspeli</td>\n";
                }
            }
        }
        $html .= "</tr>\n";
    }

    $html .= "</tr>\n";
    $html .= "</table>\n";

    return $html;
}

sub teamCompareTable {
    my $html;
    $html .= "<table border='1' class='w3-text-black w3-striped w3-white'>\n";
    foreach (sort hashValueAscendingNum keys %kaikkipelit) {
        $html .= "<tr>\n";
        $html .= "<td title=\"$kaikkipelit{$_} peli&#228;\">$_</td>\n";
        $html .= "<td>\n";
        if (!defined $kotipelit{$_}) { $kotipelit{$_} = 0; }
        for (my $i = 0; $i < $kotipelit{$_}; $i++) {
            $html .= "<p title=\"$kotipelit{$_} kotipeli&#228;\" style='background: green; width: 9px; height: 8px; float:left; margin:0;'>\n";
            $html .= "<p title=\"$kotipelit{$_} kotipeli&#228;\" style='background: white; width: 2px; height: 8px; float:left; margin:0;'>\n";
        }
        if (!defined $vieraspelit{$_}) { $vieraspelit{$_} = 0; }
        for (my $i = 0; $i < $vieraspelit{$_}; $i++) {
            $html .= "<p title=\"$vieraspelit{$_} vieraspeli&#228;\" style='background: white; width: 2px; height: 8px; float:left; margin:0;'>\n" if $i ne 0;
            $html .= "<p title=\"$vieraspelit{$_} vieraspeli&#228;\" style='background: red; width: 9px; height: 8px; float:left; margin:0;'>\n";
        }
        $html .= "</td>\n";

        # skipataan valioliigalla, koska tablessa joukkueet eri nimilla kuin ottelulistassa
        if ($param_liiga eq "valio") {
            $html .= "</tr>\n";
            next;
        }
	
        $html .= "<td style='width : 8px;'></td>\n";

        $html .= "<td>\n";
        if (!defined $vastus{$_}{low}) { $vastus{$_}{low} = 0; }
        for (my $i = 0; $i < $vastus{$_}{low}; $i++) {
             $html .= "<p title=\"$vastus{$_}{low} vastustaja(a) sijoilta 11-15\" style='background: green; width: 9px; height: 8px; float:left; margin:0;'>\n";
             $html .= "<p title=\"$vastus{$_}{low} vastustaja(a) sijoilta 11-15\" style='background: white; width: 2px; height: 8px; float:left; margin:0;'>\n";
        }
        if (!defined $vastus{$_}{mid}) { $vastus{$_}{mid} = 0; }
        for (my $i = 0; $i < $vastus{$_}{mid}; $i++) {
            $html .= "<p title=\"$vastus{$_}{mid} vastustaja(a) sijoilta 6-10\" style='background: yellow; width: 9px; height: 8px; float:left; margin:0;'>\n";
            $html .= "<p title=\"$vastus{$_}{mid} vastustaja(a) sijoilta 6-10\" style='background: white; width: 2px; height: 8px; float:left; margin:0;'>\n";
        }
        if (!defined $vastus{$_}{top}) { $vastus{$_}{top} = 0; }
        for (my $i = 0; $i < $vastus{$_}{top}; $i++) {
            $html .= "<p title=\"$vastus{$_}{top} vastustaja(a) sijoilta 1-5\" style='background: red; width: 9px; height: 8px; float:left; margin:0;'>\n";
            $html .= "<p title=\"$vastus{$_}{top} vastustaja(a) sijoilta 1-5\" style='background: white; width: 2px; height: 8px; float:left; margin:0;'>\n";
        }
        $html .= "</td>\n";
        $html .= "</tr>\n";
    }
    $html .= "</table>\n";
    
    return $html;
}

sub optimalChangeDay {
    my $html;
    
    my $topic_print = 1;
    my $from_count = 0;

    foreach my $team_to (sort hashValueAscendingNum keys %kaikkipelit) {
        my @day_to_change;
        my $max_difference = 0;
    
        my $to_count = 0;
        my $games_after_change_count = 0;
        my $continue_count = 0;

        if ($team_from eq $team_to) { next ;}
        $from_count = 0;
        foreach (@selected_day_list) {
            if (defined $pelipaivat{$team_from}{$_}) {
                $from_count++;
            }
            if (defined $pelipaivat{$team_to}{$_}) {
                $to_count++;
                $games_after_change_count++;
            }
            if ($from_count - $to_count == $max_difference) {
                $continue_count++;
                if ($continue_count == 1) {
                    push (@day_to_change, $_);
                } elsif ($continue_count == 2) {
                    push (@day_to_change, "-$_");
                } elsif ($continue_count > 2) {
                    $day_to_change[$#day_to_change] = "-$_";
                }
            } else { $continue_count = 0; }
            if ($from_count - $to_count > $max_difference) {
                $max_difference = $from_count - $to_count;
                @day_to_change = "$_";
                $games_after_change_count = $from_count;
                $continue_count = 1;
            }
        }
    
        if ($topic_print) {
            $topic_print = 0;

            $html .= "<table border='1' class='w3-text-black w3-striped w3-white'>\n";
            $html .= "<tr class='w3-black'>\n";
    
            # Tulosta otsikot
            $html .= "<th>Joukkue</th>\n";
            $html .= "<th>Pelit</th>\n";
            $html .= "<th>Yht.</th>\n";
            $html .= "<th>Ohje</th>\n";
            $html .= "<th>P&#228;iv&#228;t</th>\n";
        }
    
        $html .= "<tr>\n";
        $html .= "<td>$team_to</td>\n";
        $html .= "<td class='w3-center'>$to_count</td>\n";

        if ($to_count > $games_after_change_count) {
            $html .= "<td class='w3-center'>$to_count</td>\n";
            $html .= "<td>Vaihto ennen seuraavan p&#228;iv&#228;n peli&#228;</td>\n";
            $html .= "<td>$day_to_change[0]</td>\n";
        } else {
            $html .= "<td>$games_after_change_count</td>\n";
            $html .= "<td>Vaihto jonain seuraavista p&#228;ivist&#228; (pelien j&#228;lkeen)</td>\n";
            $html .= "<td>@day_to_change</td>\n";
        }
        $html .= "</tr>\n";
    }
    $html .= "</tr>\n";
    $html .= "</table>\n";
    $html .= selectTeamsForm($from_count);

	return $html;
}

sub yearOptionMenu {
	my $html;
	my @vuodet = get_vuodet($param_liiga);
	foreach (@vuodet) {
		if ($_ == $param_vuosi) {
			$html .= "<option selected>$_</option>\n";
		} else {
			$html .= "<option>$_</option>\n";
		}
	}

	return $html;
}

sub periodOptionMenu {
    my $html;
	my @jakso = get_jakso();
    foreach (@jakso) {
        if ($_ eq $param_read_players_from) {
            $html .= "<option selected>$_</option>\n";
        } else {
            $html .= "<option>$_</option>\n";
        }
    }

    return $html;
}

sub playerList {
	read_player_lists();
    my @otsikko = ("Nimi", "Pelipaikka", "Joukkue", "Pe", "Ma", "Sy", "Pi", "La", "Arvo", "LPP", "LPP/Peli", "Hinta/Laatu", "Ennuste", "Ennuste");
	my $html = "<table border='1' id='playertable' class='w3-text-black w3-striped w3-white'>\n";
    foreach ("thead", "tfoot") {
        $html .= "<$_>\n";
        $html .= "<tr class='w3-black'>\n";
		foreach (@otsikko) {
			$html .= "<th>$_</th>\n";
		}
        $html .= "</tr>\n";
        $html .= "</$_>\n";
    }

    foreach my $nimi (keys %{$pelaaja}) {
        $html .= "<tr>\n";
        $html .= "<td>$nimi</td>\n";
        $html .= "<td>$pelaaja->{$nimi}->{pelipaikka}</td>\n";
        $html .= "<td>$pelaaja->{$nimi}->{joukkue}</td>\n";
        $html .= "<td>$pelaaja->{$nimi}->{ottelut}</td>\n";
        $html .= "<td>$pelaaja->{$nimi}->{maalit}</td>\n";
        $html .= "<td>$pelaaja->{$nimi}->{syotot}</td>\n";
        $html .= "<td>$pelaaja->{$nimi}->{pisteet}</td>\n";
        $html .= "<td>$pelaaja->{$nimi}->{laukaukset}</td>\n";
        $html .= "<td>$pelaaja->{$nimi}->{arvo}</td>\n";
        $html .= "<td class='w3-center'>$pelaaja->{$nimi}->{lpp}</td>\n";
        $html .= "<td class='w3-center'>";
        $html .= sprintf("%.2f", $pelaaja->{$nimi}->{pisteet_per_peli});
        $html .= "</td>\n";
        $html .= "<td class='w3-center'>";
        $html .= sprintf("%.2f", $pelaaja->{$nimi}->{pisteet_per_euro});
        $html .= "</td>\n";
        $html .= "<td>";
        $html .= "$pelaaja->{$nimi}->{ennuste_pisteet}";
        $html .= "</td>\n";
        $html .= "<td>\n";
        my $width = $pelaaja->{$nimi}->{ennuste_pisteet} / 2;
        if ($width < 0) {
            $width = abs($width);
            $html .= "<p style=\"background: red; width: ${width}px; height: 8px; margin:0;\">\n";
        } else {
            $html .= "<p style=\"background: green; width: ${width}px; height: 8px; margin:0;\">\n";
        }
        $html .= "</td>\n";
        $html .= "</tr>\n";
    }
    $html .= "</table>\n";
    
    return $html;
}

sub read_player_lists {
    my $addition = "";
    if ($param_liiga =~ /nhl/) {
        $addition = "_nhl";
    }
    my %pelaaja = ();

    if ($param_read_players_from =~ /1|1-/) {
        %pelaaja = read_player_list("$param_vuosi/player_list_period1${addition}.txt", %pelaaja);
    }
    if ($param_read_players_from =~ /2|1-PO|1-5|1-4|1-3|1-2/) {
        %pelaaja = read_player_list("$param_vuosi/player_list_period2${addition}.txt", %pelaaja);
    }
    if ($param_read_players_from =~ /3|1-PO|1-5|1-4|1-3/) {
        %pelaaja = read_player_list("$param_vuosi/player_list_period3${addition}.txt", %pelaaja);
    }
    if ($param_read_players_from =~ /4|1-PO|1-5|1-4/) {
        %pelaaja = read_player_list("$param_vuosi/player_list_period4${addition}.txt", %pelaaja);
    }
    if ($param_read_players_from =~ /5|1-PO|1-5/) {
        %pelaaja = read_player_list("$param_vuosi/player_list_period5${addition}.txt", %pelaaja);
    }
    if ( $param_read_players_from =~ /PO/) {
        %pelaaja = read_player_list("$param_vuosi/player_list_playoff${addition}.txt", %pelaaja);
    }
    
    $pelaaja = \%pelaaja;
}

sub read_player_list ($$) {
    my $players_file = shift;
    my %pelaaja = @_;
    my ($joukkue, $pelipaikka);
    my @topics;
    
    open FILE, "$players_file" or die "Cant open $players_file\n"; 
    while (<FILE>) {
	    if (/^#/) { next; }

        s/\s*$//;

	    if (/(Maalivahti)/ || /(Puolustaja)/ || /(Hyokkaaja)/) {
            $pelipaikka = $1;
        
            @topics = split(/\s+/, $_);
            $topics[0] = "Nimi";
	        next;
	    }

        if (/^\s*(\D+)\s*$/) {
            $joukkue = $1;
	        next;
        }
	
#    Maalivahdit O M S P V H TP TO PM NP JM OR IS1 IS2 IS3 LPP/O LPP Arvo
#    Puolustajat O M S P AVM AVS VM TM JA L B ALV + - JM OR IS1 IS2 IS3 LPP/O LPP Arvo

        my %player;

        # Korvaa arvo oikeaan muotoon
        s/(\d\d\d) (\d)\d\d/$1.$2/;
    
        my $nimi;
        # Vältetään nimen splittaus osiin
        if (/^\s*(.*?)\s*(\d+)\s*/) {
            my $nimi_orig = $1;
            $nimi = $1;
            $nimi =~ s/\s+/_/g;
            s/$nimi_orig/$nimi/;
        }

        my @player_data = split(/\s+/, $_);
        $nimi = $player_data[0];
        $nimi =~ s/_/ /g;
        $player_data[0] = $nimi;

        # Lisää data pelaajalle taulukkoon tyyliin: Nimi = Seppo, O = 14 jne
        my $count = 0;
        foreach (@player_data) {
            $player{$topics[$count]} = $_;
            $count++;
        }
        
        my $LPP = 0;
        $LPP = $player{LPP} if defined $player{LPP};
        $LPP = $player{HGMP} if defined $player{HGMP};
	
        if (!defined $pelaaja{$nimi}{ottelut}) { $pelaaja{$nimi}{ottelut} = $player{O} } else { $pelaaja{$nimi}{ottelut} += $player{O}; }
        if (!defined $pelaaja{$nimi}{maalit}) { $pelaaja{$nimi}{maalit} = $player{M} } else { $pelaaja{$nimi}{maalit} += $player{M}; }
        if (!defined $pelaaja{$nimi}{syotot}) { $pelaaja{$nimi}{syotot} = $player{S} } else { $pelaaja{$nimi}{syotot} += $player{S}; }
        $pelaaja{$nimi}{pisteet} = $pelaaja{$nimi}{maalit} + $pelaaja{$nimi}{syotot};
        if ($pelipaikka ne "Maalivahti") {
            $pelaaja{$nimi}{laukaukset} += $player{L};
        } else {
            $pelaaja{$nimi}{laukaukset} = 0;
			if (!defined $pelaaja{$nimi}{paastetyt}) { $pelaaja{$nimi}{paastetyt} = $player{TO} } else { $pelaaja{$nimi}{paastetyt} += $player{TO}; }
        }
        if ($max_pelatut_pelit < $pelaaja{$nimi}{ottelut}) { $max_pelatut_pelit = $pelaaja{$nimi}{ottelut}; }
		$pelaaja{$nimi}{pelipaikka} = $pelipaikka;
		$pelaaja{$nimi}{jaahyt} += $player{JM};
		$pelaaja{$nimi}{lpp} += $LPP;
		$pelaaja{$nimi}{arvo} = $player{Arvo};
		$pelaaja{$nimi}{joukkue} = $joukkue;
        if ($pelaaja{$nimi}{ottelut} ne "0") {
            $pelaaja{$nimi}{pisteet_per_peli} = $pelaaja{$nimi}{lpp} / $pelaaja{$nimi}{ottelut}
        } else {
            $pelaaja{$nimi}{pisteet_per_peli} = 0;
        }
        $pelaaja{$nimi}{pisteet_per_euro} = $pelaaja{$nimi}{pisteet_per_peli} / ($pelaaja{$nimi}{arvo} / 100);
        $pelaaja{$nimi}{ennuste_pisteet} = int($pelaaja{$nimi}{pisteet_per_peli} * $kaikkipelit{$joukkue});
    }
    close (FILE);
    
    return %pelaaja;
}

sub maxPelatutPelit {
    my $html;
    my @ottelut_taulukko = (0 .. $max_pelatut_pelit);
    foreach (@ottelut_taulukko) {
        $html .= "<option>$_</option>\n";
    }

    return $html;
}

sub optimiJoukkue {
    if (! %{$pelaaja}) {
		read_player_lists();
	}

    my $html;
    my $optimi_pisteet = 0;
    my $optimi_hinta = 0;
    my $hinta;
    my $pisteet;

    my @maalivahdit_karsitut;
    my @puolustajat_karsitut;
    my @hyokkaajat_karsitut;
    
    my @top1_maalivahdit = (-50, -50, -50, -50, -50, -50, -50, -50, -50, -50);
    my @top2_puolustajat = (-50, -50, -50, -50, -50, -50, -50, -50, -50, -50);
    my @top3_hyokkaajat = (-50, -50, -50, -50, -50, -50, -50, -50, -50, -50);
    
    foreach (sort {$pelaaja->{$a}->{arvo} <=> $pelaaja->{$b}->{arvo} || $pelaaja->{$a}->{ennuste_pisteet} <=> $pelaaja->{$b}->{ennuste_pisteet}} keys %{$pelaaja}) {
        if ($pelaaja->{$_}->{pelipaikka} =~ /Maalivahti/) {
            push (@maalivahdit_kaikki, "$_, $pelaaja->{$_}->{arvo} tE, Ennuste $pelaaja->{$_}->{ennuste_pisteet}");
            if ($pelaaja->{$_}->{ottelut} < $param_ottelut) { next; }
            if ($pelaaja->{$_}->{ennuste_pisteet} <= 0) { next; }
            if ($param_remove_players =~ /$_/) { next; }
            if ($param_selected_teams !~ $pelaaja->{$_}->{joukkue}) { next; }
            if (/$o_maalivahti/) { next; }
            if (defined $param_arvo && $pelaaja->{$_}->{arvo} > $param_arvo) { next; }
            if ($pelaaja->{$_}->{ennuste_pisteet} > $top1_maalivahdit[0]) {
                $top1_maalivahdit[0] = $pelaaja->{$_}->{ennuste_pisteet};
                @top1_maalivahdit = sort {$a <=> $b} @top1_maalivahdit;
            } else { next; }
                push (@maalivahdit_karsitut, $_);
        }
        if ($pelaaja->{$_}->{pelipaikka} =~ /Puolustaja/) {
            push (@puolustajat_kaikki, "$_, $pelaaja->{$_}->{arvo} tE, Ennuste $pelaaja->{$_}->{ennuste_pisteet}");
            if ($pelaaja->{$_}->{ottelut} < $param_ottelut) { next; }
            if ($pelaaja->{$_}->{ennuste_pisteet} <= 0) { next; }
            if ($param_remove_players =~ /$_/) { next; }
            if ($param_selected_teams !~ $pelaaja->{$_}->{joukkue}) { next; }
            if (/$o_puolustaja1/ || /$o_puolustaja2/) { next; }
            if (defined $param_arvo && $pelaaja->{$_}->{arvo} > $param_arvo) { next; }
            if ($pelaaja->{$_}->{ennuste_pisteet} > $top2_puolustajat[0]) {
                $top2_puolustajat[0] = $pelaaja->{$_}->{ennuste_pisteet};
                @top2_puolustajat = sort {$a <=> $b} @top2_puolustajat;
            } else { next; }
            push (@puolustajat_karsitut, $_);
        }
        if ($pelaaja->{$_}->{pelipaikka} =~ /Hyokkaaja/) {
            push (@hyokkaajat_kaikki, "$_, $pelaaja->{$_}->{arvo} tE, Ennuste $pelaaja->{$_}->{ennuste_pisteet}");
            if ($pelaaja->{$_}->{ottelut} < $param_ottelut) { next; }
            if ($pelaaja->{$_}->{ennuste_pisteet} <= 0) { next; }
            if ($param_remove_players =~ /$_/) { next; }
            if ($param_selected_teams !~ $pelaaja->{$_}->{joukkue}) { next; }
            if (/$o_hyokkaaja1/ || /$o_hyokkaaja2/ || /$o_hyokkaaja3/) { next; }
            if (defined $param_arvo && $pelaaja->{$_}->{arvo} > $param_arvo) { next; }
            if ($pelaaja->{$_}->{ennuste_pisteet} > $top3_hyokkaajat[0]) {
                $top3_hyokkaajat[0] = $pelaaja->{$_}->{ennuste_pisteet};
                @top3_hyokkaajat = sort {$a <=> $b} @top3_hyokkaajat;
            } else { next; }
            push (@hyokkaajat_karsitut, $_);
        }
    }
    
    my @paikka = muuttujien_alustusta("paikka");
    foreach (@paikka) {
        if ($_->[0] =~ /Kaikki/) {
            $pelaaja->{$_->[0]}->{ennuste_pisteet} = -20;
        } else {
            $pelaaja->{$_->[0]}->{ennuste_pisteet} = $pelaaja->{$_->[0]}->{ennuste_pisteet};
        }
    }    

    my $t_maalivahti = $maalivahti = $o_maalivahti;
    my $t_puolustaja1 = $puolustaja1 = $o_puolustaja1;
    my $t_puolustaja2 = $puolustaja2 = $o_puolustaja2;
    my $t_hyokkaaja1 = $hyokkaaja1 = $o_hyokkaaja1;
    my $t_hyokkaaja2 = $hyokkaaja2 = $o_hyokkaaja2;
    my $t_hyokkaaja3 = $hyokkaaja3 = $o_hyokkaaja3;

    my %top_teams;
    my %top_teams_puolustus_ref;
    my %top_teams_hyokkays_ref;
    my $top_score_team2 = 0;

    my ($elapsed, $current);
    my $t_count = 0;
    
    my $loops;
    if (defined $param_joukkueen_hinta) {
        $loops = create_loops();
    }
    eval $loops;
    $html .= "$@<br>\n" if $@;

    foreach my $pelaajat (sort {$top_teams{3}{$b}{pisteet} <=> $top_teams{3}{$a}{pisteet}} keys %{$top_teams{3}}) {
        my @players = split(/\s*,\s*/, $pelaajat);
        ($o_maalivahti, $o_puolustaja1, $o_puolustaja2, $o_hyokkaaja1, $o_hyokkaaja2, $o_hyokkaaja3) = ($players[0], $players[1], $players[2], $players[3], $players[4], $players[5]);
        last;
    }

    $maalivahti = $t_maalivahti;
    $puolustaja1 = $t_puolustaja1;
    $puolustaja2 = $t_puolustaja2;
    $hyokkaaja1 = $t_hyokkaaja1;
    $hyokkaaja2 = $t_hyokkaaja2;
    $hyokkaaja3 = $t_hyokkaaja3;

    @maalivahdit_kaikki = sort (@maalivahdit_kaikki);
    @puolustajat_kaikki = sort (@puolustajat_kaikki);
    @hyokkaajat_kaikki = sort (@hyokkaajat_kaikki);

    $html .= "<div style='overflow:auto;'>\n";
	$html .= "<table border='1' class='w3-text-black w3-striped w3-white' style='width: 100%'>\n";
    $html .= "<tr class='w3-black'>\n";
    
    my @otsikko = ("P", "Kiinnitetty pelaaja", "Nimi", "Joukkue", "Pelit", "Tulevat", "Arvo");
    foreach (@otsikko) {
        $html .= "<th class='w3-center'>$_</th>\n";
    }
	$html .= "<th colspan='2'>LPP ennuste</th>\n";
    $html .= "</tr>\n";

    my $count = 0;
    @paikka = muuttujien_alustusta("paikka");
    foreach my $paikka (@paikka) {
        $html .= "<tr>\n";
        $html .= "<td>$paikka->[3]: </td>\n";
        $html .= "<td>";
        $html .= "<select style='width:100%' id='$paikka->[4]' onchange=\"Optimijoukkue('optimiJoukkue')\">\n";
        $html .= "<option>$paikka->[1]</option>\n";
        foreach (@{$paikka->[2]}) {
            if (/$paikka->[5]/) {
                $html .= "<option selected>$_</option>\n";
            } else {
                $html .= "<option>$_</option>\n";
            }
        }
        $html .= "</select>\n";
        $html .= "</td>\n";
        $html .= "<td>$paikka->[0]</td>\n";
        $html .= "<td>$pelaaja->{$paikka->[0]}->{joukkue}</td>\n";
        $html .= "<td class='w3-center'>$pelaaja->{$paikka->[0]}->{ottelut}</td>\n";
        $html .= "<td class='w3-center'>$kaikkipelit{$pelaaja->{$paikka->[0]}->{joukkue}}</td>\n";
        $html .= "<td>$pelaaja->{$paikka->[0]}->{arvo}</td>\n";
        $html .= "<td class='w3-center'>$pelaaja->{$paikka->[0]}->{ennuste_pisteet}</td>\n";
	
        $optimi_hinta += $pelaaja->{$paikka->[0]}->{arvo};
        $optimi_pisteet += $pelaaja->{$paikka->[0]}->{ennuste_pisteet};
	
        $html .= "<td>\n";
        my $width = $pelaaja->{$paikka->[0]}->{ennuste_pisteet} / 2;
        if ($width < 0) {
            $width = abs($width);
            $html .= "<p style=\"background: red; width: ${width}px; height: 8px; margin:0;\">\n";
        } else {
            $html .= "<p style=\"background: green; width: ${width}px; height: 8px; margin:0;\">\n";
        }
        $html .= "</td>\n";

        $html .= "</tr>\n";
        $count++;
    }
    $html .= "</table>\n";
	$html .= "</div>\n";

    $html .= "<br>Pisteet: $optimi_pisteet, hinta: $optimi_hinta<br><br>\n";

    $html .= "Alla laskennan parhaat joukkueet.<br>\n";
    $html .= "<div style='overflow:auto;'>\n";
    $html .= "<table border='1' class='w3-text-black w3-striped w3-white' style='width: 100%'>\n";
    $html .= "<tr class='w3-black'>\n";
    @otsikko = ("Sija", "M", "P1", "P2", "H1", "H2", "H3", "Pisteet", "Hinta");
    foreach (@otsikko) {
        $html .= "<th>$_</th>\n";
    }
    $html .= "</tr>\n";

    my $team_count = 0;
    foreach my $pelaajat (sort {$top_teams{3}{$b}{pisteet} <=> $top_teams{3}{$a}{pisteet}} keys %{$top_teams{3}}) {
        $html .= "<tr>\n";
        $team_count++;
        my @players = split(/,/, $pelaajat);
        $html .= "<td>$team_count</td>\n";
        $html .= "<td>$players[0]</td>\n";
        $html .= "<td>$players[1]</td>\n";
        $html .= "<td>$players[2]</td>\n";
        $html .= "<td>$players[3]</td>\n";
        $html .= "<td>$players[4]</td>\n";
        $html .= "<td>$players[5]</td>\n";
        $html .= "<td class='w3-center'>$top_teams{3}{$pelaajat}{pisteet}</td>\n";
        $html .= "<td>$top_teams{3}{$pelaajat}{hinta}</td>\n";
        $html .= "</tr>\n";
        if ($team_count == $max_teams) { last; }
    }
    $html .= "</table>\n";
	$html .= "</div>\n";
    $html .= "</center>\n";

    return $html;
}

sub kokoonpanotGames () {
    my $html = "<b>$weekdays[0] $start</b><br>\n";

    # Tulosta joukkueet ja pelaako
    foreach my $joukkue (sort hashValueAscendingNum keys %kaikkipelit) {
        $_ = $start;
        if (defined $pelipaivat{$joukkue}{$_}{kotipeli}) {
			if (defined $pelipaivat{$joukkue}{$_}{kokoonpano}) {
				$html .= "<A class='w3-text-red' HREF='#' onclick=\"Kokoonpanot('$joukkue', '$pelipaivat{$joukkue}{$_}{kokoonpano}')\">$joukkue - $pelipaivat{$joukkue}{$_}{kotipeli}</A><br>\n";
			} else {
				$html .= "$joukkue - $pelipaivat{$joukkue}{$_}{kotipeli}<br>\n";
			}
        }
    }

    return $html;
}

sub kokoonpanot () {
	read_player_lists();

	my $html;
	my %kokoonpanot;
	my $kentta = 0;
	my $pelaaja_nro = 0;
	my $koti_vieras = 0;
	my $koti = $param_joukkue;
	my $vieras = $pelipaivat{$param_joukkue}{$start}{kotipeli};
	my $pelaavat_pelaajat = "";

	my $data = fetch_page("http://liiga.fi/ottelut/2016-2017/runkosarja/$param_game_nro/kokoonpanot/");
	my $text;
	my $p = HTML::Parser->new(text_h => [ sub {$text .= shift}, 
				  'dtext']);
	$p->parse($data);
	my @text = split(/\n/, $text);
	foreach (@text) {
		if (/^\s*$/) { next; }

		$_ = modify_char($_);
		if (/Tuomarit/) { last; }

		if (/(\d+)\.\s*kentta/) {
			$kentta = $1;
			$pelaaja_nro = 0;
		}
		if (/Maalivahdit/) {
			$kentta = 5;
			$pelaaja_nro = 0;
		}
		if (/$koti/) {
			$koti_vieras = 1;
		}
		if (/$vieras/) {
			$koti_vieras = 2;
		}
		if (/^\s*(.*?),\s+(.*?)\s*$/ && $koti_vieras) {
			my $nimi = "$1 $2";
			$pelaaja_nro++;
		
			$kokoonpanot{$koti_vieras}{$kentta}{$pelaaja_nro} = $nimi;
		
			$pelaavat_pelaajat .= " $nimi ";
		}
	}

    # Jakso
    $html .= "Lue tilastot jaksosta:\n";
    $html .= "<select id='read_players_from' onchange='Kokoonpanot()'>\n";
    my @jakso = get_jakso();
    foreach my $current_arvo (@jakso) {
        if ($current_arvo eq $param_read_players_from) {
            $html .= "<option selected>$current_arvo</option>\n";
        } else {
            $html .= "<option>$current_arvo</option>\n";
        }
    }
    $html .= "</select><p>\n";
    $html .= "<table border='1' class='w3-text-black'>\n";
    $html .= "<tr class='w3-black'><th class='w3-center' colspan='10'>$koti<\/th><th class='w3-center' colspan='10'>$vieras</th></tr>\n";
    $html .= "<tr class='w3-black'>\n";
    for (my $i = 0; $i <= 1; $i++) {
        $html .= "<th><center>Nimi</center></th>\n";
        $html .= "<th><center>Pe</center></th>\n";
        $html .= "<th><center>Ma</center></th>\n";
        $html .= "<th><center>Sy</center></th>\n";
        $html .= "<th><center>Pi</center></th>\n";
        $html .= "<th><center>La</center></th>\n";
        $html .= "<th><center>Arvo</center></th>\n";
        $html .= "<th><center>LPP</center></th>\n";
        $html .= "<th colspan='2'><center>LPP ennuste</center></th>\n";
    }
    $html .= "</tr>\n";

    my $td = change_table_td();
    for ($kentta = 1; $kentta <= 5; $kentta++) {
        $td = change_table_td($td);
        for ($pelaaja_nro = 1; $pelaaja_nro <= 5; $pelaaja_nro++) {
            $html .= "<tr class='$td'>\n";
            for ($koti_vieras = 1; $koti_vieras <= 2; $koti_vieras++) {
                if (defined $kokoonpanot{$koti_vieras}{$kentta}{$pelaaja_nro}) {
                    my $nimi = $kokoonpanot{$koti_vieras}{$kentta}{$pelaaja_nro};
                    $html .= "<td>$nimi</td>\n";
                    $html .= "<td>$pelaaja->{$nimi}->{ottelut}</td>\n";
                    $html .= "<td>$pelaaja->{$nimi}->{maalit}</td>\n";
                    $html .= "<td>$pelaaja->{$nimi}->{syotot}</td>\n";
                    $html .= "<td>$pelaaja->{$nimi}->{pisteet}</td>\n";
                    $html .= "<td>$pelaaja->{$nimi}->{laukaukset}</td>\n";
                    $html .= "<td>$pelaaja->{$nimi}->{arvo}</td>\n";
                    $html .= "<td>$pelaaja->{$nimi}->{lpp}</td>\n";
                    $html .= "<td>$pelaaja->{$nimi}->{ennuste_pisteet}</td>\n";
                    $html .= "<td>\n";
                    my $width = $pelaaja->{$nimi}->{ennuste_pisteet} / 2;
                    if ($width < 0) {
                        $width = abs($width);
                        $html .= "<p style=\"background: red; width: ${width}px; height: 8px; margin:0;\">\n";
                    } else {
                        $html .= "<p style=\"background: green; width: ${width}px; height: 8px; margin:0;\">\n";
                    }
                    $html .= "</td>\n";
                } else {
                    for (my $i = 1; $i <= 10; $i++) { $html .= "<td>&#32;</td>\n"; }
                }
            }
            $html .= "</tr>\n";
        }
    }
    $html .= "<tr class='w3-black'><th class='w3-center' colspan='20'>Ei kokoonpanossa</th></tr>\n";

    my %ei_pelaavat;
    my ($k_h, $k_p, $k_m, $v_h, $v_p, $v_m);
    
    foreach my $nimi (sort {$pelaaja->{$b}->{ennuste_pisteet} <=> $pelaaja->{$a}->{ennuste_pisteet} || $pelaaja->{$a}->{arvo} <=> $pelaaja->{$b}->{arvo}} keys %{$pelaaja}) {
        if ($pelaavat_pelaajat !~ /$nimi/) {
            if ($pelaaja->{$nimi}->{joukkue} eq $koti) {
                if ($pelaaja->{$nimi}->{pelipaikka} =~ /Hyokkaaja/) { $k_h++; $ei_pelaavat{1}{1}{$k_h} = $nimi; }
                if ($pelaaja->{$nimi}->{pelipaikka} =~ /Puolustaja/) { $k_p++; $ei_pelaavat{1}{2}{$k_p} = $nimi; }
                if ($pelaaja->{$nimi}->{pelipaikka} =~ /Maalivahti/) { $k_m++; $ei_pelaavat{1}{3}{$k_m} = $nimi; }
            }
            if ($pelaaja->{$nimi}->{joukkue} eq $vieras) {
                if ($pelaaja->{$nimi}->{pelipaikka} =~ /Hyokkaaja/) { $v_h++; $ei_pelaavat{2}{1}{$v_h} = $nimi; }
                if ($pelaaja->{$nimi}->{pelipaikka} =~ /Puolustaja/) { $v_p++; $ei_pelaavat{2}{2}{$v_p} = $nimi; }
                if ($pelaaja->{$nimi}->{pelipaikka} =~ /Maalivahti/) { $v_m++; $ei_pelaavat{2}{3}{$v_m} = $nimi; }
            }
        }
    }
    
    if ($k_h < $v_h) { $k_h = $v_h; }
    if ($k_p < $v_p) { $k_p = $v_p; }
    if ($k_m < $v_m) { $k_m = $v_m; }

    for (my $pelipaikka = 1; $pelipaikka <= 3; $pelipaikka++) {
        $td = change_table_td($td);
        my $max_nro;
        if ($pelipaikka == 1) { $max_nro = $k_h; }
        if ($pelipaikka == 2) { $max_nro = $k_p; }
        if ($pelipaikka == 3) { $max_nro = $k_m; }
        for (my $pelaaja_nro = 1; $pelaaja_nro <= $max_nro; $pelaaja_nro++) {
            $html .= "<tr class='$td'>\n";
            for ($koti_vieras = 1; $koti_vieras <= 2; $koti_vieras++) {
                if (defined $ei_pelaavat{$koti_vieras}{$pelipaikka}{$pelaaja_nro}) {
                    my $nimi = $ei_pelaavat{$koti_vieras}{$pelipaikka}{$pelaaja_nro};
                    $html .= "<td>$nimi</td>\n";
                    $html .= "<td>$pelaaja->{$nimi}->{ottelut}</td>\n";
                    $html .= "<td>$pelaaja->{$nimi}->{maalit}</td>\n";
                    $html .= "<td>$pelaaja->{$nimi}->{syotot}</td>\n";
                    $html .= "<td>$pelaaja->{$nimi}->{pisteet}</td>\n";
                    $html .= "<td>$pelaaja->{$nimi}->{laukaukset}</td>\n";
                    $html .= "<td>$pelaaja->{$nimi}->{arvo}</td>\n";
                    $html .= "<td>$pelaaja->{$nimi}->{lpp}</td>\n";
                    $html .= "<td>$pelaaja->{$nimi}->{ennuste_pisteet}</td>\n";
                    $html .= "<td>\n";
                    my $width = $pelaaja->{$nimi}->{ennuste_pisteet} / 2;
                    if ($width < 0) {
                        $width = abs($width);
                        $html .= "<p style=\"background: red; width: ${width}px; height: 8px; margin:0;\">\n";
                    } else {
                        $html .= "<p style=\"background: green; width: ${width}px; height: 8px; margin:0;\">\n";
                    }
                    $html .= "</td>\n";
                } else {
                    for (my $i = 1; $i <= 10; $i++) { $html .= "<td>&#032;</td>\n"; }
                }
            }
            $html .= "</tr>\n";
        }
    }
    $html .= "</table>\n";

    return $html;
}

sub change_table_td {
    my $current_td = shift;

    if (!defined $current_td || $current_td eq "w3-white") {
        return "w3-light-grey";
    } elsif ($current_td eq "w3-light-grey") {
        return "w3-white";
    }
}

sub create_loops {
    my $loops = "";
    my $loops1 = "";
    my $loops2 = "";
    my @loop_count1;
    my @loop_count2;
    
    if ($o_maalivahti =~ /Kaikki/) {
        push (@loop_count1, "molke");
        $loops1 = '
    ($elapsed, $current) = calculate_interval(undef) if ($timing);
    $html .= "alku: $elapsed<br>\n" if ($timing);

	foreach $maalivahti (@maalivahdit_karsitut) {';
    }

    if ($o_puolustaja1 =~ /Kaikki/) {
        push (@loop_count1, "pakki1");
        $loops1 = "$loops1" . '

	for (my $p1_count = 0; $p1_count <= $#puolustajat_karsitut; $p1_count++) {
            $puolustaja1 = $puolustajat_karsitut[$p1_count];';
    }

    if ($o_puolustaja2 =~ /Kaikki/) {
        push (@loop_count1, "pakki2");
        $loops1 = "$loops1" . '

	for (my $p2_count = $p1_count + 1; $p2_count <= $#puolustajat_karsitut; $p2_count++) {
	    $puolustaja2 = $puolustajat_karsitut[$p2_count];';
    }

    $loops1 = "$loops1" . '

    $t_count++;
    $top_teams{temp1}{$t_count}{pelaajat} = $maalivahti . ", " . $puolustaja1. ", " .  $puolustaja2;
    $top_teams{temp1}{$t_count}{pisteet} = $pelaaja->{$maalivahti}->{ennuste_pisteet} + $pelaaja->{$puolustaja1}->{ennuste_pisteet} + $pelaaja->{$puolustaja2}->{ennuste_pisteet};
    $top_teams{temp1}{$t_count}{hinta} = $pelaaja->{$maalivahti}->{arvo} + $pelaaja->{$puolustaja1}->{arvo} + $pelaaja->{$puolustaja2}->{arvo};';

    foreach (@loop_count1) {
        $loops1 = "$loops1\n
        }";
    }
    
    $loops1 = "$loops1" . '
    ($elapsed, $current) = calculate_interval($current) if ($timing);
    $html .= "loop11 $elapsed<br>\n" if ($timing);

    my %pistekarsinta;
    foreach (keys %{$top_teams{temp1}}) {
	if ($pistekarsinta{$top_teams{temp1}{$_}{pisteet}}++ >= $max_teams) { next; }
        push(@{$top_teams_puolustus_ref{$top_teams{temp1}{$_}{pisteet}}}, [$top_teams{temp1}{$_}{pelaajat}, $top_teams{temp1}{$_}{hinta}]);
    }';

    if ($o_hyokkaaja1 =~ /Kaikki/) {
        push (@loop_count2, "hyokkaaja1");
        $loops2 = '
    ($elapsed, $current) = calculate_interval($current) if ($timing);
    $html .= "loop12 $elapsed<br>\n" if ($timing);

	for (my $h1_count = 0; $h1_count <= $#hyokkaajat_karsitut; $h1_count++) {
	    $hyokkaaja1 = $hyokkaajat_karsitut[$h1_count];';
    }

    if ($o_hyokkaaja2 =~ /Kaikki/) {
        push (@loop_count2, "hyokkaaja2");
        $loops2 = "$loops2" . '
	
	for (my $h2_count = $h1_count + 1; $h2_count <= $#hyokkaajat_karsitut; $h2_count++) {
	    $hyokkaaja2 = $hyokkaajat_karsitut[$h2_count];';
    }

    if ($o_hyokkaaja3 =~ /Kaikki/) {
        push (@loop_count2, "hyokkaaja3");
        $loops2 = "$loops2" . '
	
	for (my $h3_count = $h2_count + 1; $h3_count <= $#hyokkaajat_karsitut; $h3_count++) {
	    $hyokkaaja3 = $hyokkaajat_karsitut[$h3_count];';
    }
    
    $loops2 = "$loops2" . '

    $t_count++;
    $pisteet = $pelaaja->{$hyokkaaja1}->{ennuste_pisteet} + $pelaaja->{$hyokkaaja2}->{ennuste_pisteet} + $pelaaja->{$hyokkaaja3}->{ennuste_pisteet};
    $top_teams{temp2}{$t_count}{pelaajat} = $hyokkaaja1 .", " . $hyokkaaja2 .", " . $hyokkaaja3;
    $top_teams{temp2}{$t_count}{pisteet} = $pisteet;
    $top_teams{temp2}{$t_count}{hinta} = $pelaaja->{$hyokkaaja1}->{arvo} + $pelaaja->{$hyokkaaja2}->{arvo} + $pelaaja->{$hyokkaaja3}->{arvo};
    $top_score_team2 = $pisteet if ($top_score_team2 < $pisteet);';
    
    foreach (@loop_count2) {
        $loops2 = "$loops2\n
        }";
    }

    $loops2 = "$loops2" . '
    
    ($elapsed, $current) = calculate_interval($current) if ($timing);
    $html .= "loop21 $elapsed<br>\n" if ($timing);

    %pistekarsinta = ();
    foreach (keys %{$top_teams{temp2}}) {
	if ($pistekarsinta{$top_teams{temp2}{$_}{pisteet}}++ >= $max_teams) { next; }
        push(@{$top_teams_hyokkays_ref{$top_teams{temp2}{$_}{pisteet}}}, [$top_teams{temp2}{$_}{pelaajat}, $top_teams{temp2}{$_}{hinta}]);
    }
    ($elapsed, $current) = calculate_interval($current)  if ($timing);
    $html .= "loop22 $elapsed<br>\n"  if ($timing);
    ';

    $loops = "
    $loops1
    $loops2" . '

    my @top_points;
    foreach my $index (0 .. $max_teams - 1) { $top_points[$index] = -100; }
    foreach my $pisteet_p (sort {$b <=> $a} keys %top_teams_puolustus_ref) {
        if ($top_score_team2 + $pisteet_p < $top_points[0]) { last; }
        foreach my $table_p (@{$top_teams_puolustus_ref{$pisteet_p}}) {
	    my $count = 0;
            foreach my $pisteet_h (sort {$b <=> $a} keys %top_teams_hyokkays_ref) {
                if ($pisteet_p + $pisteet_h <= $top_points[0] ) { last; }
                foreach my $table_h (@{$top_teams_hyokkays_ref{$pisteet_h}}) {
	            my $hinta = $table_p->[1] + $table_h->[1];
	            if ($hinta > $param_joukkueen_hinta) { next; }

	            my $team = $table_p->[0] . ", " . $table_h->[0];
	            $top_teams{3}{$team}{pisteet} = $pisteet_p + $pisteet_h;
	            $top_teams{3}{$team}{hinta} = $hinta;

	            $top_points[0] = $top_teams{3}{$team}{pisteet};
	            @top_points = sort {$a <=> $b} @top_points;
	            $count++;
	            if ($count == $max_teams) { last; }
	        }
            }
        }
    }
    ($elapsed, $current) = calculate_interval($current) if ($timing);
    $html .= "loppu $elapsed<br>\n" if ($timing);
    ';
    
    return $loops;
}

sub selectTeamsForm {
    my $html;
    
    my $count = shift;
    $html .= "Vaihda pelaaja joukkueesta <select id='teamFrom' onchange=\"Ottelulista('optimalChangeDay');\">\n";
    foreach (sort keys %kaikkipelit) {
        if (/$team_from/) {
            $html .= "<option selected>$_</option>\n";
		} else {
			$html .= "<option>$_</option>\n";
		}
    }
    $html .= "</select> jolla on $count peli&#228;\n";
    
    return $html;
}

sub startDayOption {
    my $html;

    foreach (@all_day_list) {
        if (/$start/) {
            $html .= "<option selected>$_</option>\n";
        } else {
            $html .= "<option>$_</option>\n";
        }
        if (/$end/) { last; }
    }
    
    return $html;
}

sub endDayOption {
    my $start_found = 0;
    my $html;

    foreach (@all_day_list) {
        if ($_ =~ /$start/) { $start_found = 1; }
        if (!$start_found) { next; }
        if (/$end/) {
            $html .= "<option selected>$_</option>\n";
        } else {
            $html .= "<option>$_</option>\n";
        }
    }
    
    return $html;
}

alustus();
my @subs = split(/,/, $param_sub);
foreach my $sub (@subs) {
	$result{$sub} = eval "$sub()";
}

print $cgi->header('text/plain;charset=UTF-8');
my $json = encode_json \%result;
print $json;