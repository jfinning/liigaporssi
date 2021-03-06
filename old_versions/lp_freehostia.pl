#!/usr/bin/perl -w

use strict;
use CGI::Carp qw(fatalsToBrowser);
use CGI qw(:standard);

my $cgi = new CGI;
my $script_name = $cgi->script_name;

my %kotipelit;
my %vieraspelit;
my %kaikkipelit;
my %taulukko;
my %vastus;
my @all_day_list;
my @selected_day_list;
my @weekdays;
my %pelipaivat;
my $max_pelatut_pelit = 0;

my %pelaaja;

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
my $param_sort              = $cgi->param('sort');
my $param_order             = $cgi->param('order');
my $param_ottelut           = $cgi->param('ottelut');
my $param_arvo              = $cgi->param('arvo');
my $param_lpp               = $cgi->param('lpp');
my $param_joukkue           = $cgi->param('joukkue');
my $param_pelipaikka        = $cgi->param('pelipaikka');
my $param_remove_players    = $cgi->param('remove_players');
my $param_read_players_from = $cgi->param('read_players_from');
my $param_joukkueen_hinta   = $cgi->param('joukkueen_hinta');
my $param_vuosi             = $cgi->param('vuosi');
my $param_graafi            = $cgi->param('graafi');
my $param_liiga             = $cgi->param('liiga');
if (!defined $param_joukkueen_hinta)   { $param_joukkueen_hinta = "2000.0"; }
if (!defined $param_ottelut)           { $param_ottelut = 0; }
if (!defined $param_remove_players)    { $param_remove_players = ""; }
if (!defined $param_vuosi)             { $param_vuosi = 2013; }
if (!defined $param_pelipaikka)        { $param_pelipaikka = "Pelaaja"; }
if (!defined $param_sub)               { $param_sub = ""; }
if (!defined $param_graafi)            { $param_graafi = "LPP ennuste"; }
if (!defined $param_liiga)             { $param_liiga = "sm_liiga"; }
if (!defined $param_read_players_from) {
    if ($param_liiga =~ /nhl/) {
        $param_read_players_from = "Jakso 1";
    } else {
        $param_read_players_from = "Jakso 1";
    }
}

$o_maalivahti      = $cgi->param('o_maalivahti') if defined $cgi->param('o_maalivahti');
$o_puolustaja1     = $cgi->param('o_puolustaja1') if defined $cgi->param('o_puolustaja1');
$o_puolustaja2     = $cgi->param('o_puolustaja2') if defined $cgi->param('o_puolustaja2');
$o_hyokkaaja1      = $cgi->param('o_hyokkaaja1') if defined $cgi->param('o_hyokkaaja1');
$o_hyokkaaja2      = $cgi->param('o_hyokkaaja2') if defined $cgi->param('o_hyokkaaja2');
$o_hyokkaaja3      = $cgi->param('o_hyokkaaja3') if defined $cgi->param('o_hyokkaaja3');

if ($o_maalivahti =~ /^(.*?)\s*,/) { $o_maalivahti = $1; }
if ($o_puolustaja1 =~ /^(.*?)\s*,/) { $o_puolustaja1 = $1; }
if ($o_puolustaja2 =~ /^(.*?)\s*,/) { $o_puolustaja2 = $1; }
if ($o_hyokkaaja1 =~ /^(.*?)\s*,/) { $o_hyokkaaja1 = $1; }
if ($o_hyokkaaja2 =~ /^(.*?)\s*,/) { $o_hyokkaaja2 = $1; }
if ($o_hyokkaaja3 =~ /^(.*?)\s*,/) { $o_hyokkaaja3 = $1; }

my ($pelit, $sarjataulukko, $playoff_joukkueet, $jaljella_olevat_joukkueet);
if ($param_liiga =~ /sm_liiga/) {
    $pelit = "games.txt";
    $sarjataulukko = "table.txt";
    $playoff_joukkueet         = "Blues, HIFK, HPK, Ilves, Jokerit, JYP, KalPa, Karpat, Lukko, Pelicans, SaiPa, Tappara, TPS, Assat";
    $jaljella_olevat_joukkueet = "Blues, HIFK, HPK, Ilves, Jokerit, JYP, KalPa, Karpat, Lukko, Pelicans, SaiPa, Tappara, TPS, Assat";
} else {
    $pelit = "games_nhl.txt";
    $sarjataulukko = "table_nhl.txt";
    $playoff_joukkueet         = "Anaheim, Boston, Buffalo, Calgary, Carolina, Chicago, Colorado, Columbus, Dallas, Detroit, Edmonton, Florida, Los Angeles, Minnesota, Montreal, Nashville, New Jersey, NY Islanders, NY Rangers, Ottawa, Philadelphia, Phoenix, Pittsburgh, San Jose, St. Louis, Tampa Bay, Toronto, Vancouver, Washington, Winnipeg";
    $jaljella_olevat_joukkueet = "Anaheim, Boston, Buffalo, Calgary, Carolina, Chicago, Colorado, Columbus, Dallas, Detroit, Edmonton, Florida, Los Angeles, Minnesota, Montreal, Nashville, New Jersey, NY Islanders, NY Rangers, Ottawa, Philadelphia, Phoenix, Pittsburgh, San Jose, St. Louis, Tampa Bay, Toronto, Vancouver, Washington, Winnipeg";
}

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

if (! defined $end) {
    if ($param_liiga =~ /sm_liiga/) {
        $end = "02.11.";
    } else {
        $end = "03.11.";
    }
}

open TAULUKKO, "$sarjataulukko" or die "Cant open $sarjataulukko\n"; 
while (<TAULUKKO>) {
    s/\s*$//;

    if ((/(\d+)\.\s*(.*?)\s*(\d+)\s*(\d+)\s*/ && $param_liiga eq "sm_liiga") || (/(\d+)\.\s*(.*?)\s*(\d+)\s*.*?\s*(\d+)\s*(\d\.\d\d)\s*$/ && $param_liiga eq "nhl")) {
	$taulukko{$2}{'sija'} = $1;
	$taulukko{$2}{'pelit'} = $3;
        $taulukko{$2}{'pisteet'} = $4;
    }
}
close (TAULUKKO);

my $start_found = 0;
my $end_found = 0;
my $last_day_found = 0;
my $pelipaiva;
my $weekday;
open PELIT, "$pelit" or die "Cant open $pelit\n"; 
while (<PELIT>) {
    s/\s*$//;

    if (/(\d\d\.\d\d\.)/) {
	push (@all_day_list, $1);
        if (! defined $start) { $start = $1; }
    }

    if ((/^\d+\.\t(.*?)\s*\d/ && $param_liiga eq "sm_liiga") || (/^\s*(.*?)\s*\d/ && $param_liiga eq "nhl")) {
        $weekday = $1;
    }
    
    if (/$start/) { $start_found = 1; }
    if (! $start_found) { next; }

    if ($end_found) { 
	next;
    }

    if ($last_day_found && /\d\d\.\d\d\./) {
        $end_found = 1;
	next;
    }

    if (/(\d\d\.\d\d\.)/) {
        push (@selected_day_list, $1);
        push (@weekdays, $weekday);
	$pelipaiva = $1;
    }

    if (/$end/) {
        $last_day_found = 1;
    }

    if ((/0\t(.*?)\s*-\s*(.*?)\s*$/ && $param_liiga eq "sm_liiga") || (/\s+(\D.*?)\s*-\s*(.*?)\s*$/ && $param_liiga eq "nhl")) {
        $kotipelit{$1}++;
        $vieraspelit{$2}++;
        $kaikkipelit{$1}++;
        $kaikkipelit{$2}++;
	
	$pelipaivat{$1}{$pelipaiva}{'kotipeli'} = $2;
	$pelipaivat{$2}{$pelipaiva}{'vieraspeli'} = $1;

	if ($taulukko{$1}{'sija'} <= 5) {
	    $vastus{$2}{'top'}++;
	} elsif ($taulukko{$1}{'sija'} <= 10) {
	    $vastus{$2}{'mid'}++;
	} else { 
	    $vastus{$2}{'low'}++;
	}

	if ($taulukko{$2}{'sija'} <= 5) {
	    $vastus{$1}{'top'}++;
	} elsif ($taulukko{$2}{'sija'} <= 10) {
	    $vastus{$1}{'mid'}++;
	} else { 
	    $vastus{$1}{'low'}++;
	}
    }
}
close (PELIT);

if (! defined $team_from) {
    foreach (sort keys %kaikkipelit) {
        $team_from = $_;
	last;
    }
}

update_menus();

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

    if ($temp =~ /vuodet/) {
        my @vuodet;
	if ($param_liiga =~ /sm_liiga/) {
	    @vuodet = ("2009", "2010", "2011", "2012", "2013");
	} else {
	    @vuodet = ("2010", "2011", "2012", "2013");
	}
	return @vuodet;
    }
    
    if ($temp =~ /jakso/) {
        my @jakso;
        if ($param_liiga =~ /sm_liiga/) {
            @jakso = ("PO", "Jakso 5", "Jakso 4", "Jakso 3", "Jakso 2", "Jakso 1", "Jaksot 1-2", "Jaksot 1-3", "Jaksot 1-4", "Jaksot 1-5", "Jaksot 1-PO");
	} else {
            @jakso = ("PO", "Jakso 5", "Jakso 4", "Jakso 3", "Jakso 2", "Jakso 1", "Jaksot 1-2", "Jaksot 1-3", "Jaksot 1-4", "Jaksot 1-5", "Jaksot 1-PO");
	}
	return @jakso;
    }
}

sub update_menus {
    print $cgi->header;
    
    print "<html>\n";
    print "<head>\n";
    print "<title>Liigaporssi pilalle tilastojen avulla - Sepeti</title>\n";
    
    my $css = `cat css/css.html`;
    
    print "$css\n";
    
    print "<script type=\"text/javascript\">\n";

    print "var _gaq = _gaq || [];\n";
    print "_gaq.push(['_setAccount', 'UA-26708167-1']);\n";
    print "_gaq.push(['_trackPageview']);\n";

    print "(function() {\n";
    print "    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;\n";
    print "    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';\n";
    print "    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);\n";
    print "})();\n";

    print "</script>\n";

    print "</head>\n";
    
    print "<center>\n";
    
    print "<div id=\"container\">\n";
    print "<ul id=\"nav\">\n";

    if ($param_liiga =~/sm_liiga/) {
        print "<li><A HREF=\"$script_name?sub=print_start_page&liiga=nhl\">NHL</A></li>\n";
    } else {
        print "<li><A HREF=\"$script_name?sub=print_start_page&liiga=sm_liiga\">SM-Liiga</A></li>\n";
    }
    print "<li><A HREF=\"$script_name?sub=print_start_page&liiga=$param_liiga\">Ottelulista</A></li>\n";
    print "<li><A HREF=\"$script_name?sub=player_list&sort=lpp_per_peli&liiga=$param_liiga\">Pelaajalista</A></li>\n";
    print "<li><A HREF=\"$script_name?sub=optimi_joukkue&liiga=$param_liiga\">Optimijoukkue</A></li>\n";
    print "<li><A HREF=\"$script_name?sub=print_current_table&liiga=$param_liiga\">Sarjataulukko</A></li>\n";
    print "<li><a href=\"mailto:jepponen\@gmail.com\">Mailia</a></li>";
 
    print "</ul>\n";
    print "</div>\n";
    
    print "<br><br>\n";
    
    if ($param_sub =~ /start_page|^\s*$/) {print_start_page()};
    if ($param_sub =~ /player_list/)      {print_player_list()};
    if ($param_sub =~ /current_table/)    {print_current_table()};
    if ($param_sub =~ /optimi_joukkue/)   {print_optimi_joukkue()};

    print "</center>\n";
    
    print $cgi->end_html;
}

sub print_optimi_joukkue {
    # Tama siksi, etta saadaan oikeat hinnat
    if ($param_vuosi =~ /2009|2010|2011|2012/) {
        read_player_list("2013/player_list_period1.txt");
    }

    read_player_lists();
    
    my $optimi_pisteet = -100;
    my $optimi_hinta;
    my %current_joukkue;
    my $hinta;
    my $pisteet;

    my @maalivahdit_karsitut;
    my @puolustajat_karsitut;
    my @hyokkaajat_karsitut;
    
    my $m_count = 0;
    my $p_count = 0;
    my $h_count = 0;
    
    my $m_ennuste_pisteet = -50;
    
    my @top2_puolustajat = (-50, -50);
    my @top3_hyokkaajat = (-50, -50, -50);
    
    foreach (sort {$pelaaja{$a}{"arvo"} <=> $pelaaja{$b}{"arvo"} || $pelaaja{$a}{"ennuste_pisteet"} <=> $pelaaja{$b}{"ennuste_pisteet"}} keys %pelaaja) {
	if ($playoff_joukkueet !~ $pelaaja{$_}{'joukkue'}) { next; }
	if ($pelaaja{$_}{'pelipaikka'} =~ /Maalivahti/) {
	    push (@maalivahdit_kaikki, "$_, $pelaaja{$_}{'arvo'} tE, Ennuste $pelaaja{$_}{'ennuste_pisteet'}");
	    if ($jaljella_olevat_joukkueet !~ $pelaaja{$_}{'joukkue'}) { next; }
	    if ($pelaaja{$_}{'ottelut'} < $param_ottelut) { next; }
	    if ($param_remove_players =~ /$_/) { next; }
	    if (/$o_maalivahti/) { next; }
	    if (defined $param_arvo && $pelaaja{$_}{'arvo'} > $param_arvo) { next; }
	    if ($m_count > 0 && $pelaaja{$_}{'ennuste_pisteet'} <= $m_ennuste_pisteet) { next; }
	    $m_ennuste_pisteet = $pelaaja{$_}{'ennuste_pisteet'};
	    push (@maalivahdit_karsitut, $_);
	    $m_count++;
	}
        if ($pelaaja{$_}{'pelipaikka'} =~ /Puolustaja/) {
	    push (@puolustajat_kaikki, "$_, $pelaaja{$_}{'arvo'} tE, Ennuste $pelaaja{$_}{'ennuste_pisteet'}");
	    if ($jaljella_olevat_joukkueet !~ $pelaaja{$_}{'joukkue'}) { next; }
	    if ($pelaaja{$_}{'ottelut'} < $param_ottelut) { next; }
	    if ($param_remove_players =~ /$_/) { next; }
	    if (/$o_puolustaja1/ || /$o_puolustaja2/) { next; }
	    if (defined $param_arvo && $pelaaja{$_}{'arvo'} > $param_arvo) { next; }
	    if ($pelaaja{$_}{'ennuste_pisteet'} > $top2_puolustajat[0] || $p_count < 1) {
	        $top2_puolustajat[0] = $pelaaja{$_}{'ennuste_pisteet'};
		@top2_puolustajat = sort {$a <=> $b} @top2_puolustajat;
	    } else { next; }
	    push (@puolustajat_karsitut, $_);
	    $p_count++;
	}
        if ($pelaaja{$_}{'pelipaikka'} =~ /Hyokkaaja/) {
	    push (@hyokkaajat_kaikki, "$_, $pelaaja{$_}{'arvo'} tE, Ennuste $pelaaja{$_}{'ennuste_pisteet'}");
	    if ($jaljella_olevat_joukkueet !~ $pelaaja{$_}{'joukkue'}) { next; }
	    if ($pelaaja{$_}{'ottelut'} < $param_ottelut) { next; }
	    if ($param_remove_players =~ /$_/) { next; }
	    if (/$o_hyokkaaja1/ || /$o_hyokkaaja2/ || /$o_hyokkaaja3/) { next; }
	    if (defined $param_arvo && $pelaaja{$_}{'arvo'} > $param_arvo) { next; }
	    if ($pelaaja{$_}{'ennuste_pisteet'} > $top3_hyokkaajat[0] || $h_count < 2) {
	        $top3_hyokkaajat[0] = $pelaaja{$_}{'ennuste_pisteet'};
		@top3_hyokkaajat = sort {$a <=> $b} @top3_hyokkaajat;
	    } else { next; }
	    push (@hyokkaajat_karsitut, $_);
	    $h_count++;
	}
    }
    
    my @paikka = muuttujien_alustusta("paikka");
    foreach (@paikka) {
	if ($_->[0] =~ /Kaikki/) {
            $pelaaja{$_->[0]}{'ennuste_pisteet'} = -20;
        } else {
            $pelaaja{$_->[0]}{'ennuste_pisteet'} = $pelaaja{$_->[0]}{'ennuste_pisteet'};
        }
    }    

    my $t_maalivahti = $maalivahti = $o_maalivahti;
    my $t_puolustaja1 = $puolustaja1 = $o_puolustaja1;
    my $t_puolustaja2 = $puolustaja2 = $o_puolustaja2;
    my $t_hyokkaaja1 = $hyokkaaja1 = $o_hyokkaaja1;
    my $t_hyokkaaja2 = $hyokkaaja2 = $o_hyokkaaja2;
    my $t_hyokkaaja3 = $hyokkaaja3 = $o_hyokkaaja3;

    my %top_teams;
    
    my $loops;
    if (defined $param_joukkueen_hinta) {
	$loops = create_loops();
    }

    print "<center>\n";
    print "T&#228;ll&#228; sivulla voit koota laskennallisia optimikokoonpanoja antamillasi ehdoilla.<br>\n";
    if ($param_liiga =~ /sm_liiga/) {
        print "Jos valitset vuoden 2012, lasketaan optimijoukkue tuon vuoden pisteiden mukaisesti. Pelaajat, jotka ovat jo poistuneet liigasta, j&#228;tet&#228;&#228;n huomiotta.<p>\n";
    } else {
        print "<p>\n";
    }

    eval $loops ;

    print start_form(-action => "$script_name");
    print "Joukkueen arvo tE\n";
    print "<input type='text' name='joukkueen_hinta' SIZE='6' MAXLENGTH='6'  VALUE=\"$param_joukkueen_hinta\"/>\n";

    print "Pelatut pelit v&#228;h.: <select name=\"ottelut\">\n";
    my @ottelut_taulukko = (0 .. $max_pelatut_pelit);
    foreach (@ottelut_taulukko) {
        if (defined $param_ottelut && $_ == $param_ottelut) {
            print "<option selected>$_<\/option>\n";
        } elsif (!defined $param_ottelut && $_ == 0) {
            print "<option selected>$_<\/option>\n";
        } else {
            print "<option>$_<\/option>\n";
        }
    }
    print "<\/select>\n";

    # Arvo
    print "Pelaajan arvo alle: \n";
    my @arvotaulukko = ("999", "500", "450", "400", "350", "300", "250");
    print "<select name=\"arvo\">\n";
    foreach my $current_arvo (@arvotaulukko) {
        if (defined $param_arvo && $current_arvo eq $param_arvo) {
	    print "<option selected>$current_arvo<\/option>\n";
	} else {
            print "<option>$current_arvo<\/option>\n";
	}
    }
    print "<\/select>\n";

    # Jakso
    print "<select name=\"read_players_from\">\n";
    my @jakso = muuttujien_alustusta("jakso");
    foreach my $current_arvo (@jakso) {
        if ($current_arvo eq $param_read_players_from) {
	    print "<option selected>$current_arvo<\/option>\n";
	} else {
            print "<option>$current_arvo<\/option>\n";
	}
    }
    print "<\/select>\n";

    # Vuosi
    print "<select name=\"vuosi\">\n";
    my @vuodet = muuttujien_alustusta("vuodet");
    foreach (@vuodet) {
        if ($_ == $param_vuosi) {
            print "<option selected>$_<\/option>\n";
	    $param_vuosi = $_;
        } else {
            print "<option>$_<\/option>\n";
        }
    }
    print "<\/select><br>\n";
    print "Valitse aikav&#228;li, jolle haluat optimikokoonpanon laskettavan: \n";
    select_days_form();
    print "<br>\n";

    print "<br>Kopioi t&#228;h&#228;n pelaajien nimi&#228;, jotka haluat skipata. Esim. loukkaantuneita pelaajia.<br>\n";
    print "<TEXTAREA NAME='remove_players' COLS=40 ROWS=5>\n";
    print "$param_remove_players";
    print "<\/TEXTAREA><br>\n";

    print "<br>\n";

    $maalivahti = $t_maalivahti;
    $puolustaja1 = $t_puolustaja1;
    $puolustaja2 = $t_puolustaja2;
    $hyokkaaja1 = $t_hyokkaaja1;
    $hyokkaaja2 = $t_hyokkaaja2;
    $hyokkaaja3 = $t_hyokkaaja3;

    @maalivahdit_kaikki = sort (@maalivahdit_kaikki);
    @puolustajat_kaikki = sort (@puolustajat_kaikki);
    @hyokkaajat_kaikki = sort (@hyokkaajat_kaikki);

    print "<table border=\"1\">\n";
    print "<tr>\n";
    
    my @otsikko = ("P", "Kiinnitetty pelaaja", "Nimi", "Joukkue", "Pelatut", "Tulevat", "Arvo", "LPP ennuste", "LPP ennustegraafi");
    foreach (@otsikko) {
        print "<th><center>$_</center></th>\n";
    }
    print "<\/tr>\n";

    my $count = 0;
    @paikka = muuttujien_alustusta("paikka");
    my $td = change_table_td();
    foreach my $paikka (@paikka) {
	$td = change_table_td($td);
	print "<tr>\n";
        print "<td class=\"$td\">$paikka->[3]: <\/td>\n";
	print "<td class=\"$td\">";
	print "<select name=\"$paikka->[4]\">\n";
        print "<option>$paikka->[1]<\/option>\n";
	foreach (@{$paikka->[2]}) {
            if (/$paikka->[5]/) {
                print "<option selected>$_<\/option>\n";
            } else {
                print "<option>$_<\/option>\n";
            }
        }
        print "<\/select>\n";
	print "<\/td>\n";
        print "<td class=\"$td\">$paikka->[0]<\/td>\n";
        print "<td class=\"$td\">$pelaaja{$paikka->[0]}{'joukkue'}<\/td>\n";
        print "<td class=\"$td\"><center>$pelaaja{$paikka->[0]}{'ottelut'}</center><\/td>\n";
        print "<td class=\"$td\"><center>$kaikkipelit{$pelaaja{$paikka->[0]}{'joukkue'}}</center><\/td>\n";
        print "<td class=\"$td\">$pelaaja{$paikka->[0]}{'arvo'}<\/td>\n";
        print "<td class=\"$td\"><center>$pelaaja{$paikka->[0]}{'ennuste_pisteet'}</center><\/td>\n";
	
	print "<td class=\"$td\">\n";
	my $width = $pelaaja{$paikka->[0]}{'ennuste_pisteet'} / 2;
	if ($width < 0) {
	    $width = abs($width);
	    print "<p style=\"background: red; width: ${width}px; height: 8px;\">\n";
	} else {
	    print "<p style=\"background: green; width: ${width}px; height: 8px;\">\n";
	}
	print "<\/td>\n";

        print "<\/tr>\n";
	$count++;
    }
    print "<\/table>\n";

    print "<br>Pisteet: $optimi_pisteet, hinta: $optimi_hinta<br><br>\n";

    print hidden(-name => 'liiga', -default => "$param_liiga");
    print hidden(-name => 'sub', -default => "optimi_joukkue");
    print submit('Update');
    print endform;

    print "Alla laskennan parhaat joukkueet.<br>\n";
    print "<table border=\"1\">\n";
    print "<tr>\n";
    @otsikko = ("Sija", "M", "P1", "P2", "H1", "H2", "H3", "Pisteet", "Hinta");
    foreach (@otsikko) {
        print "<th><center>$_</center></th>\n";
    }
    print "<\/tr>\n";

    my $team_count = 0;
    my $param_max_teams = 10;
    $td = change_table_td();
    foreach my $pelaajat (sort {$top_teams{3}{$b}{'pisteet'} <=> $top_teams{3}{$a}{'pisteet'}} keys %{$top_teams{3}}) {
        print "<tr>\n";
	$team_count++;
	$td = change_table_td($td);
	my @players = split(/,/, $pelaajat);
	print "<td class=\"$td\">$team_count<\/td>\n";
	print "<td class=\"$td\">$players[0]<\/td>\n";
	print "<td class=\"$td\">$players[1]<\/td>\n";
	print "<td class=\"$td\">$players[2]<\/td>\n";
	print "<td class=\"$td\">$players[3]<\/td>\n";
	print "<td class=\"$td\">$players[4]<\/td>\n";
	print "<td class=\"$td\">$players[5]<\/td>\n";
	print "<td class=\"$td\">$top_teams{3}{$pelaajat}{'pisteet'}<\/td>\n";
	print "<td class=\"$td\">$top_teams{3}{$pelaajat}{'hinta'}<\/td>\n";
	print "<\/tr>\n";
	if ($team_count == $param_max_teams) { last; }
    }
    print "<\/table>\n";

    print "<\/center>\n";
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

	foreach $maalivahti (@maalivahdit_karsitut) {
	    if ($pelaaja{$maalivahti}{"ennuste_pisteet"} <= $pelaaja{$o_maalivahti}{"ennuste_pisteet"}) { next; }';
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

    $hinta = $pelaaja{$maalivahti}{"arvo"} + $pelaaja{$puolustaja1}{"arvo"} + $pelaaja{$puolustaja2}{"arvo"};
    $pisteet = $pelaaja{$maalivahti}{"ennuste_pisteet"} + $pelaaja{$puolustaja1}{"ennuste_pisteet"} + $pelaaja{$puolustaja2}{"ennuste_pisteet"};
    $top_teams{temp1}{"$maalivahti, $puolustaja1, $puolustaja2"}{"pisteet"} = $pisteet;
    $top_teams{temp1}{"$maalivahti, $puolustaja1, $puolustaja2"}{"hinta"} = $hinta;';
    
    foreach (@loop_count1) {
        $loops1 = "$loops1\n
	}";
    }
    
    $loops1 = "$loops1" . '

    my $edellinen_hinta = 0;
    my $edellinen_pisteet = 0;
    foreach (sort {$top_teams{temp1}{$a}{"hinta"} <=> $top_teams{temp1}{$b}{"hinta"} || $top_teams{temp1}{$b}{"pisteet"} <=> $top_teams{temp1}{$a}{"pisteet"}} keys %{$top_teams{temp1}}) {
        #Jos nhl, niin tod.n�k joutuu enabloimaan alla olevan (ehk� iffill� nhl)
	#if ($edellinen_hinta == $top_teams{temp1}{$_}{"hinta"} && $edellinen_pisteet > $top_teams{temp1}{$_}{"pisteet"}) { next; }
        $top_teams{1}{$_} = $top_teams{temp1}{$_};
        $edellinen_hinta = $top_teams{temp1}{$_}{"hinta"};
        $edellinen_pisteet = $top_teams{temp1}{$_}{"pisteet"};
#	print "V1: $_, $edellinen_hinta, $edellinen_pisteet<br>\n";
    }';

    if ($o_hyokkaaja1 =~ /Kaikki/) {
        push (@loop_count2, "hyokkaaja1");
	$loops2 = '

	for (my $h1_count = 0; $h1_count <= $#hyokkaajat_karsitut; $h1_count++) {
	    $hyokkaaja1 = $hyokkaajat_karsitut[$h1_count];
	    if ($pelaaja{$hyokkaaja1}{"ennuste_pisteet"} <= $pelaaja{$o_hyokkaaja1}{"ennuste_pisteet"}) { next; }';
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

    $hinta = $pelaaja{$hyokkaaja1}{"arvo"} + $pelaaja{$hyokkaaja2}{"arvo"} + $pelaaja{$hyokkaaja3}{"arvo"};
    $pisteet = $pelaaja{$hyokkaaja1}{"ennuste_pisteet"} + $pelaaja{$hyokkaaja2}{"ennuste_pisteet"} + $pelaaja{$hyokkaaja3}{"ennuste_pisteet"};
    $top_teams{temp2}{"$hyokkaaja1, $hyokkaaja2, $hyokkaaja3"}{"pisteet"} = $pisteet;
    $top_teams{temp2}{"$hyokkaaja1, $hyokkaaja2, $hyokkaaja3"}{"hinta"} = $hinta;';
    
    foreach (@loop_count2) {
        $loops2 = "$loops2\n
	}";
    }

    $loops2 = "$loops2" . '
    
    $edellinen_hinta = 0;
    $edellinen_pisteet = 0;
    foreach (sort {$top_teams{temp2}{$a}{"hinta"} <=> $top_teams{temp2}{$b}{"hinta"} || $top_teams{temp2}{$b}{"pisteet"} <=> $top_teams{temp2}{$a}{"pisteet"}} keys %{$top_teams{temp2}}) {
        #Jos nhl, niin tod.n�k joutuu enabloimaan alla olevan (ehk� iffill� nhl)
        #if ($edellinen_hinta == $top_teams{temp2}{$_}{"hinta"} && $edellinen_pisteet > $top_teams{temp2}{$_}{"pisteet"}) { next; }
        $top_teams{2}{$_} = $top_teams{temp2}{$_};
        $edellinen_hinta = $top_teams{temp2}{$_}{"hinta"};
        $edellinen_pisteet = $top_teams{temp2}{$_}{"pisteet"};
#	print "V2: $_, $edellinen_hinta, $edellinen_pisteet<br>\n";
    }';

    $loops = "
    $loops1
    $loops2" . '
    
    my $top_score_team2;
    foreach my $team2 (sort {$top_teams{2}{$b}{"pisteet"} <=> $top_teams{2}{$a}{"pisteet"}} keys %{$top_teams{2}}) {
        $top_score_team2 = $top_teams{2}{$team2}{"pisteet"};
	last;
    }
    
    my $max_teams = 10;
    my @top_points;
    $edellinen_pisteet = 0;
    $edellinen_hinta = 5000;
    foreach my $index (0 .. $max_teams - 1) { $top_points[$index] = -100; }
    foreach my $team1 (sort {$top_teams{1}{$b}{"pisteet"} <=> $top_teams{1}{$a}{"pisteet"} || $top_teams{1}{$a}{"hinta"} <=> $top_teams{1}{$b}{"hinta"}} keys %{$top_teams{1}}) {
        if ($top_score_team2 + $top_teams{1}{$team1}{"pisteet"} < $top_points[0]) { last; }
	if ($edellinen_pisteet == $top_teams{1}{$team1}{"pisteet"}) { next; } # vaarana, ett� karsii liikaa
	if ($edellinen_hinta < $top_teams{1}{$team1}{"hinta"}) { next; }      # vaarana, ett� karsii liikaa
	$edellinen_pisteet = $top_teams{1}{$team1}{"pisteet"};
	$edellinen_hinta = $top_teams{1}{$team1}{"hinta"};
	my $count = 0;
	foreach my $team2 (sort {$top_teams{2}{$b}{"pisteet"} <=> $top_teams{2}{$a}{"pisteet"} || $top_teams{2}{$a}{"hinta"} <=> $top_teams{2}{$b}{"hinta"}} keys %{$top_teams{2}}) {
            my $hinta = $top_teams{1}{$team1}{"hinta"} + $top_teams{2}{$team2}{"hinta"};
	    if ($hinta > $param_joukkueen_hinta) { next; }
	    my $team = "$team1, $team2";
	    $top_teams{3}{"$team"}{"pisteet"} = $top_teams{1}{$team1}{"pisteet"} + $top_teams{2}{$team2}{"pisteet"};
	    $top_teams{3}{"$team"}{"hinta"} = $hinta;
	    
	    if ($top_teams{3}{"$team"}{"pisteet"} < $top_points[0] ) { last; }
	    $top_points[0] = $top_teams{3}{"$team"}{"pisteet"};
	    @top_points = sort {$a <=> $b} @top_points;
	    
	    if ($top_teams{3}{"$team"}{"pisteet"} > $optimi_pisteet) {
	        $optimi_pisteet = $top_teams{3}{"$team"}{"pisteet"};
	        $optimi_hinta = $top_teams{3}{"$team"}{"hinta"};
	    
	        my @players = split(/\s*,\s*/, $team);
	        ($o_maalivahti, $o_puolustaja1, $o_puolustaja2, $o_hyokkaaja1, $o_hyokkaaja2, $o_hyokkaaja3) = ($players[0], $players[1], $players[2], $players[3], $players[4], $players[5]);
	    }
	    $count++;
	    if ($count == $max_teams) { last; }
        }
    }';
    
    return $loops;
}

sub print_player_list {
    read_player_lists();

    my $nimi;

    print "<center>\n";
    
    # Valikot taulukon karsimiseen
    my $condition = "";
    my $param_list = "";
    print start_form(-action => "$script_name");

    # Vuosi
    print "<select name=\"vuosi\">\n";
    my @vuodet = muuttujien_alustusta("vuodet");
    foreach (@vuodet) {
        if ($_ == $param_vuosi) {
            print "<option selected>$_<\/option>\n";
	    $param_vuosi = $_;
        } else {
            print "<option>$_<\/option>\n";
        }
    }
    print "<\/select>\n";

    #Jakso
    print "<select name=\"read_players_from\">\n";
    my @jakso = muuttujien_alustusta("jakso");
    foreach my $current_arvo (@jakso) {
        if ($current_arvo eq $param_read_players_from) {
	    print "<option selected>$current_arvo<\/option>\n";
	    $param_list = "${param_list}&read_players_from=$current_arvo";
	} else {
            print "<option>$current_arvo<\/option>\n";
	}
    }
    print "<\/select>\n";

    # Joukkue
    my @tmp_joukkueet = sort keys %taulukko;
    if (!defined $param_joukkue || $param_joukkue =~ /^\s*$/) { $param_joukkue = "Joukkue"; }
    my @joukkueet = ("Joukkue");
    push (@joukkueet, @tmp_joukkueet);
    print "<select name=\"joukkue\">\n";
    foreach my $joukkue (@joukkueet) {
        if ($joukkue eq $param_joukkue) {
	    print "<option selected>$joukkue<\/option>\n";
	    if ($joukkue =~ /Jaljella olevat/) {
	        $condition = "if (\$jaljella_olevat_joukkueet !~ /\$pelaaja{\$nimi}{\"joukkue\"}/) { next; }";
	    } elsif ($joukkue !~ /Joukkue/) {
	        $condition = "if (\$pelaaja{\$nimi}{\"joukkue\"} !~ /$param_joukkue/) { next; }";
	    }
	    $param_list = "${param_list}&joukkue=$joukkue";
	} else {
            print "<option>$joukkue<\/option>\n";
	}
    }
    print "<\/select>\n";

    # Pelipaikka
    print "<select name=\"pelipaikka\">\n";
    if ($param_pelipaikka =~ /Pelaaja/) {
        print "<option selected>Pelaaja<\/option>\n";
    } else {
        print "<option>Pelaaja<\/option>\n";
    }
    if ($param_pelipaikka =~ /Hyokkaaja/) {
        print "<option selected>Hyokkaaja<\/option>\n";
	$condition = "$condition\n if (\$pelaaja{\$nimi}{\"pelipaikka\"} !~ /Hyokkaaja/) { next; }";
	$param_list = "${param_list}&pelipaikka=Hyokkaaja";
    } else {
        print "<option>Hyokkaaja<\/option>\n";
    }
    if ($param_pelipaikka =~ /Puolustaja/) {
        print "<option selected>Puolustaja<\/option>\n";
	$condition = "$condition\n if (\$pelaaja{\$nimi}{\"pelipaikka\"} !~ /Puolustaja/) { next; }";
	$param_list = "${param_list}&pelipaikka=Puolustaja";
    } else {
        print "<option>Puolustaja<\/option>\n";
    }
    if ($param_pelipaikka =~ /Maalivahti/) {
        print "<option selected>Maalivahti<\/option>\n";
	$condition = "$condition\n if (\$pelaaja{\$nimi}{\"pelipaikka\"} !~ /Maalivahti/) { next; }";
	$param_list = "${param_list}&pelipaikka=Maalivahti";
    } else {
        print "<option>Maalivahti<\/option>\n";
    }
    print "<\/select>\n";

    # Ottelut vahintaan
    print "Ottelut v&#228;h.: <select name=\"ottelut\">\n";
    my @ottelut_taulukko = (0 .. $max_pelatut_pelit);
    foreach (@ottelut_taulukko) {
        if (defined $param_ottelut && $_ == $param_ottelut) {
            print "<option selected>$_<\/option>\n";
	    $condition = "$condition\n if (\$pelaaja{\$nimi}{\"ottelut\"} < $_) { next; }";
	    $param_list = "${param_list}&ottelut=$_";
        } elsif (!defined $param_ottelut && $_ == 0) {
            print "<option selected>$_<\/option>\n";
	    $condition = "$condition\n if (\$pelaaja{\$nimi}{\"ottelut\"} < $_) { next; }";
	    $param_list = "${param_list}&ottelut=$_";
        } else {
            print "<option>$_<\/option>\n";
        }
    }
    print "<\/select>\n";

    # Arvo
    my @arvotaulukko = ("0-X", "200-249", "250-299", "300-349", "350-399", "400-449", "450-499", "500-X", "Alle 200", "Alle 250", "Alle 300", "Alle 350", "Alle 400", "Alle 450", "Alle 500");
    print "<select name=\"arvo\">\n";
    foreach my $current_arvo (@arvotaulukko) {
        if (defined $param_arvo && $current_arvo eq $param_arvo) {
	    print "<option selected>$current_arvo<\/option>\n";
	    if ($current_arvo =~ /(\d+)-(\d+)/) {
	        $condition = "$condition\n if (\$pelaaja{\$nimi}{\"arvo\"} < $1 || \$pelaaja{\$nimi}{\"arvo\"} > $2) { next; }";
	    } elsif ($current_arvo =~ /(\d+)-X/) {
	        $condition = "$condition\n if (\$pelaaja{\$nimi}{\"arvo\"} < $1) { next; }";
	    } elsif ($current_arvo =~ /Alle\s*(\d+)/) {
	        $condition = "$condition\n if (\$pelaaja{\$nimi}{\"arvo\"} > $1) { next; }";
	    }
	    $param_list = "${param_list}&arvo=$current_arvo";
	} else {
            print "<option>$current_arvo<\/option>\n";
	}
    }
    print "<\/select>\n";

    # Graafi
    print "Graafi: <select name=\"graafi\">\n";
    my @graafit = ("LPP ennuste", "Arvo");
    foreach (@graafit) {
        if (/$param_graafi/) {
            print "<option selected>$_<\/option>\n";
	    $param_graafi = $_;
	    $param_list = "${param_list}&graafi=$_";
        } else {
            print "<option>$_<\/option>\n";
        }
    }
    print "<\/select>\n";
    
    print hidden(-name => 'liiga', -default => "$param_liiga");
    print hidden(-name => 'sub', -default => "player_list");
    print hidden(-name => 'sort', -default => "$param_sort");
    if (defined $param_order) {
        print hidden(-name => 'order', -default => "ascending");
    }
    print submit('Update');
    print endform;
    
    print "<table border=\"1\">\n";
    print "<tr>\n";

    $param_list = "${param_list}&vuosi=$param_vuosi&liiga=$param_liiga";
    
    print "<th><center>Sija</center></th>\n";
    if ($param_sort =~ /nimi/ && !defined $param_order) {
        print "<th class=\"asc\"><center><A HREF=\"$script_name?sub=player_list&sort=nimi&order=ascending$param_list\">Nimi</A></center></th>\n";
    } elsif ($param_sort =~ /nimi/) {
        print "<th class=\"des\"><center><A HREF=\"$script_name?sub=player_list&sort=nimi$param_list\">Nimi</A></center></th>\n";
    } else {
        print "<th><center><A HREF=\"$script_name?sub=player_list&sort=nimi$param_list\">Nimi</A></center></th>\n";
    }
    print "<th><center>Pelipaikka</center></th>\n";
    print "<th><center>Joukkue</center></th>\n";
    if ($param_sort =~ /ottelut/ && !defined $param_order) {
        print "<th class=\"des\" title=\"Pelit\"><center><A HREF=\"$script_name?sub=player_list&sort=ottelut&order=ascending$param_list\">Pe</A></center></th>\n";
    } elsif ($param_sort =~ /ottelut/) {
        print "<th class=\"asc\" title=\"Pelit\"><center><A HREF=\"$script_name?sub=player_list&sort=ottelut$param_list\">Pe</A></center></th>\n";
    } else {
        print "<th title=\"Pelit\"><center><A HREF=\"$script_name?sub=player_list&sort=ottelut$param_list\">Pe</A></center></th>\n";
    }


    if ($param_sort =~ /maalit/ && !defined $param_order) {
        print "<th class=\"des\" title=\"Maalit\"><center><A HREF=\"$script_name?sub=player_list&sort=maalit&order=ascending$param_list\">Ma</A></center></th>\n";
    } elsif ($param_sort =~ /maalit/) {
        print "<th class=\"asc\" title=\"Maalit\"><center><A HREF=\"$script_name?sub=player_list&sort=maalit$param_list\">Ma</A></center></th>\n";
    } else {
        print "<th title=\"Maalit\"><center><A HREF=\"$script_name?sub=player_list&sort=maalit$param_list\">Ma</A></center></th>\n";
    }
    if ($param_sort =~ /syotot/ && !defined $param_order) {
        print "<th class=\"des\" title=\"Syotot\"><center><A HREF=\"$script_name?sub=player_list&sort=syotot&order=ascending$param_list\">Sy</A></center></th>\n";
    } elsif ($param_sort =~ /syotot/) {
        print "<th class=\"asc\" title=\"Syotot\"><center><A HREF=\"$script_name?sub=player_list&sort=syotot$param_list\">Sy</A></center></th>\n";
    } else {
        print "<th title=\"Syotot\"><center><A HREF=\"$script_name?sub=player_list&sort=syotot$param_list\">Sy</A></center></th>\n";
    }
    if ($param_sort =~ /pisteet/ && !defined $param_order) {
        print "<th class=\"des\" title=\"Pisteet\"><center><A HREF=\"$script_name?sub=player_list&sort=pisteet&order=ascending$param_list\">Pi</A></center></th>\n";
    } elsif ($param_sort =~ /pisteet/) {
        print "<th class=\"asc\" title=\"Pisteet\"><center><A HREF=\"$script_name?sub=player_list&sort=pisteet$param_list\">Pi</A></center></th>\n";
    } else {
        print "<th title=\"Pisteet\"><center><A HREF=\"$script_name?sub=player_list&sort=pisteet$param_list\">Pi</A></center></th>\n";
    }
    if ($param_sort =~ /laukaukset/ && !defined $param_order) {
        print "<th class=\"des\" title=\"Laukaukset\"><center><A HREF=\"$script_name?sub=player_list&sort=laukaukset&order=ascending$param_list\">La</A></center></th>\n";
    } elsif ($param_sort =~ /laukaukset/) {
        print "<th class=\"asc\" title=\"Laukaukset\"><center><A HREF=\"$script_name?sub=player_list&sort=laukaukset$param_list\">La</A></center></th>\n";
    } else {
        print "<th title=\"Laukaukset\"><center><A HREF=\"$script_name?sub=player_list&sort=laukaukset$param_list\">La</A></center></th>\n";
    }


    if ($param_sort =~ /arvo/ && !defined $param_order) {
        print "<th class=\"des\"><center><A HREF=\"$script_name?sub=player_list&sort=arvo&order=ascending$param_list\">Arvo</A></center></th>\n";
    } elsif ($param_sort =~ /arvo/) {
        print "<th class=\"asc\"><center><A HREF=\"$script_name?sub=player_list&sort=arvo$param_list\">Arvo</A></center></th>\n";
    } else {
        print "<th><center><A HREF=\"$script_name?sub=player_list&sort=arvo$param_list\">Arvo</A></center></th>\n";
    }
    if ($param_sort eq "lpp" && !defined $param_order) {
        print "<th class=\"des\"><center><b><A HREF=\"$script_name?sub=player_list&sort=lpp&order=ascending$param_list\">LPP</A></center></th>\n";
    } elsif ($param_sort eq "lpp") {
        print "<th class=\"asc\"><center><b><A HREF=\"$script_name?sub=player_list&sort=lpp$param_list\">LPP</A></center></th>\n";
    } else {
        print "<th><center><b><A HREF=\"$script_name?sub=player_list&sort=lpp$param_list\">LPP</A></center></th>\n";
    }
    if ($param_sort eq "lpp_per_peli" && !defined $param_order) {
        print "<th class=\"des\"><center><A HREF=\"$script_name?sub=player_list&sort=lpp_per_peli&order=ascending$param_list\">LPP / Peli</A></center></th>\n";
    } elsif ($param_sort eq "lpp_per_peli") {
        print "<th class=\"asc\"><center><A HREF=\"$script_name?sub=player_list&sort=lpp_per_peli$param_list\">LPP / Peli</A></center></th>\n";
    } else {
        print "<th><center><A HREF=\"$script_name?sub=player_list&sort=lpp_per_peli$param_list\">LPP / Peli</A></center></th>\n";
    }
    if ($param_sort =~ /euroa_per_lpp_per_peli/ && !defined $param_order) {
        print "<th class=\"des\" title=\"(LPP \/ Peli) \/ Hinta (100tE)\"><center><A HREF=\"$script_name?sub=player_list&sort=euroa_per_lpp_per_peli&order=ascending$param_list\">Hinta/Laatu</A></center></th>\n";
    } elsif ($param_sort =~ /euroa_per_lpp_per_peli/) {
        print "<th class=\"asc\" title=\"(LPP \/ Peli) \/ Hinta (100tE)\"><center><A HREF=\"$script_name?sub=player_list&sort=euroa_per_lpp_per_peli$param_list\">Hinta/Laatu</A></center></th>\n";
    } else {
        print "<th title=\"(LPP \/ Peli) \/ Hinta (100tE)\"><center><A HREF=\"$script_name?sub=player_list&sort=euroa_per_lpp_per_peli$param_list\">Hinta/Laatu</A></center></th>\n";
    }
    if ($param_sort =~ /ennuste/ && !defined $param_order) {
        print "<th class=\"des\" title=\"LPP ennuste, joukkueen ottelumaara huomioitu\"><center><A HREF=\"$script_name?sub=player_list&sort=ennuste&order=ascending$param_list\">Ennuste</A></center></th>\n";
    } elsif ($param_sort =~ /ennuste/) {
        print "<th class=\"asc\" title=\"LPP ennuste, joukkueen ottelumaara huomioitu\"><center><A HREF=\"$script_name?sub=player_list&sort=ennuste$param_list\">Ennuste</A></center></th>\n";
    } else {
        print "<th title=\"LPP ennuste, joukkueen ottelumaara huomioitu\"><center><A HREF=\"$script_name?sub=player_list&sort=ennuste$param_list\">Ennuste</A></center></th>\n";
    }
    print "<th><center>$param_graafi</center></th>\n";
    print "</center></th>\n";
    
    print "<\/tr>\n";

    print endform;
    
    my $td = change_table_td();
    my $count = 0;
    my $sort_order = "sort_list";
    if (defined $param_order) { $sort_order = "sort_list_ascending"; }


    foreach $nimi (sort $sort_order keys %pelaaja) {
	eval($condition);
        $td = change_table_td($td);
	$count++;
	print "<tr>\n";
	print "<td class=\"$td\">$count<\/td>\n";
	print "<td class=\"$td\">$nimi<\/td>\n";
	print "<td class=\"$td\">$pelaaja{$nimi}{'pelipaikka'}<\/td>\n";
	print "<td class=\"$td\">$pelaaja{$nimi}{'joukkue'}<\/td>\n";
	print "<td class=\"$td\">$pelaaja{$nimi}{'ottelut'}<\/td>\n";
	print "<td class=\"$td\">$pelaaja{$nimi}{'maalit'}<\/td>\n";
	print "<td class=\"$td\">$pelaaja{$nimi}{'syotot'}<\/td>\n";
	print "<td class=\"$td\">$pelaaja{$nimi}{'pisteet'}<\/td>\n";
	print "<td class=\"$td\">$pelaaja{$nimi}{'laukaukset'}<\/td>\n";
	print "<td class=\"$td\">$pelaaja{$nimi}{'arvo'}<\/td>\n";
	print "<td class=\"$td\"><center>$pelaaja{$nimi}{'lpp'}</center><\/td>\n";
	print "<td class=\"$td\"><center>";
	printf("%.3f", $pelaaja{$nimi}{'pisteet_per_peli'});
	print "</center><\/td>\n";
	print "<td class=\"$td\"><center>";
	printf("%.3f", $pelaaja{$nimi}{'pisteet_per_euro'});
	print "</center><\/td>\n";
	print "<td class=\"$td\">";
	print "$pelaaja{$nimi}{'ennuste_pisteet'}";
        print "<\/td>\n";
	print "<td class=\"$td\">\n";
	my $width;
	if ($param_graafi =~ /LPP ennuste/) {
	    $width = $pelaaja{$nimi}{'ennuste_pisteet'} / 2;
	} elsif ($param_graafi =~ /Arvo/) {
	    $width = $pelaaja{$nimi}{'arvo'} / 3;
	}
	if ($width < 0) {
	    $width = abs($width);
	    print "<p style=\"background: red; width: ${width}px; height: 8px;\">\n";
	} else {
	    print "<p style=\"background: green; width: ${width}px; height: 8px;\">\n";
	}
	print "<\/td>\n";

	print "<\/tr>\n";
    }
    
    print "<\/table>\n";

    print "<\/center>\n";
}

sub read_player_lists {
    my $addition = "";
    if ($param_liiga =~ /nhl/) {
	$addition = "_nhl";
    }

    if ($param_read_players_from =~ /1|1-/) {
	read_player_list("$param_vuosi/player_list_period1${addition}.txt");
    }
    if ($param_read_players_from =~ /2|1-/) {
	read_player_list("$param_vuosi/player_list_period2${addition}.txt");
    }
    if ($param_read_players_from =~ /3|1-PO|1-5|1-4|1-3/) {
	read_player_list("$param_vuosi/player_list_period3${addition}.txt");
    }
    if ($param_read_players_from =~ /4|1-PO|1-5|1-4/) {
	read_player_list("$param_vuosi/player_list_period4${addition}.txt");
    }
    if ($param_read_players_from =~ /5|1-PO|1-5/) {
	read_player_list("$param_vuosi/player_list_period5${addition}.txt");
    }
    if ( $param_read_players_from =~ /PO/) {
        read_player_list("$param_vuosi/player_list_playoff${addition}.txt");
    }
}

sub sort_list {
    if (! defined $param_sort) { return 0; }
    if ($param_sort =~ /arvo/) {
	{$pelaaja{$b}{"arvo"} <=> $pelaaja{$a}{"arvo"} || $pelaaja{$b}{"ennuste_pisteet"} <=> $pelaaja{$a}{"ennuste_pisteet"}};
    } elsif ($param_sort =~ /euroa_per_lpp_per_peli/) {
	{$pelaaja{$b}{"pisteet_per_euro"} <=> $pelaaja{$a}{"pisteet_per_euro"} || $pelaaja{$b}{"ennuste_pisteet"} <=> $pelaaja{$a}{"ennuste_pisteet"}};
    } elsif ($param_sort =~ /nimi/) {
	{$b cmp $a};
    } elsif ($param_sort =~ /joukkue/) {
    } elsif ($param_sort =~ /ottelut/) {
	{$pelaaja{$b}{"ottelut"} <=> $pelaaja{$a}{"ottelut"} || $pelaaja{$b}{"ennuste_pisteet"} <=> $pelaaja{$a}{"ennuste_pisteet"}};

    } elsif ($param_sort =~ /maalit/) {
	{$pelaaja{$b}{"maalit"} <=> $pelaaja{$a}{"maalit"} || $pelaaja{$b}{"pisteet"} <=> $pelaaja{$a}{"pisteet"} || $pelaaja{$b}{"ennuste_pisteet"} <=> $pelaaja{$a}{"ennuste_pisteet"}};
    } elsif ($param_sort =~ /syotot/) {
	{$pelaaja{$b}{"syotot"} <=> $pelaaja{$a}{"syotot"} || $pelaaja{$b}{"pisteet"} <=> $pelaaja{$a}{"pisteet"} || $pelaaja{$b}{"ennuste_pisteet"} <=> $pelaaja{$a}{"ennuste_pisteet"}};
    } elsif ($param_sort =~ /pisteet/) {
	{$pelaaja{$b}{"pisteet"} <=> $pelaaja{$a}{"pisteet"} || $pelaaja{$b}{"ennuste_pisteet"} <=> $pelaaja{$a}{"ennuste_pisteet"} || $pelaaja{$b}{"ennuste_pisteet"} <=> $pelaaja{$a}{"ennuste_pisteet"}};
    } elsif ($param_sort =~ /laukaukset/) {
	{$pelaaja{$b}{"laukaukset"} <=> $pelaaja{$a}{"laukaukset"} || $pelaaja{$b}{"ennuste_pisteet"} <=> $pelaaja{$a}{"ennuste_pisteet"}};

    } elsif ($param_sort =~ /lpp_per_peli/) {
	{$pelaaja{$b}{"pisteet_per_peli"} <=> $pelaaja{$a}{"pisteet_per_peli"} || $pelaaja{$b}{"ennuste_pisteet"} <=> $pelaaja{$a}{"ennuste_pisteet"}};
    } elsif ($param_sort =~ /lpp/) {
	{$pelaaja{$b}{"lpp"} <=> $pelaaja{$a}{"lpp"} || $pelaaja{$b}{"ennuste_pisteet"} <=> $pelaaja{$a}{"ennuste_pisteet"}};
    } elsif ($param_sort =~ /ennuste/) {
	{$pelaaja{$b}{"ennuste_pisteet"} <=> $pelaaja{$a}{"ennuste_pisteet"} || $pelaaja{$a}{"arvo"} <=> $pelaaja{$b}{"arvo"}};
    }
}

sub sort_list_ascending {
    if ($param_sort =~ /arvo/) {
	{$pelaaja{$a}{"arvo"} <=> $pelaaja{$b}{"arvo"} || $pelaaja{$b}{"ennuste_pisteet"} <=> $pelaaja{$a}{"ennuste_pisteet"}};
    } elsif ($param_sort =~ /euroa_per_lpp_per_peli/) {
	{$pelaaja{$a}{"pisteet_per_euro"} <=> $pelaaja{$b}{"pisteet_per_euro"} || $pelaaja{$b}{"ennuste_pisteet"} <=> $pelaaja{$a}{"ennuste_pisteet"}};
    } elsif ($param_sort =~ /nimi/) {
	{$a cmp $b};
    } elsif ($param_sort =~ /joukkue/) {
    } elsif ($param_sort =~ /ottelut/) {
	{$pelaaja{$a}{"ottelut"} <=> $pelaaja{$b}{"ottelut"} || $pelaaja{$b}{"ennuste_pisteet"} <=> $pelaaja{$a}{"ennuste_pisteet"}};

    } elsif ($param_sort =~ /maalit/) {
	{$pelaaja{$a}{"maalit"} <=> $pelaaja{$b}{"maalit"} || $pelaaja{$a}{"pisteet"} <=> $pelaaja{$b}{"pisteet"} || $pelaaja{$b}{"ennuste_pisteet"} <=> $pelaaja{$a}{"ennuste_pisteet"}};
    } elsif ($param_sort =~ /syotot/) {
	{$pelaaja{$a}{"syotot"} <=> $pelaaja{$b}{"syotot"} || $pelaaja{$a}{"pisteet"} <=> $pelaaja{$b}{"pisteet"} || $pelaaja{$b}{"ennuste_pisteet"} <=> $pelaaja{$a}{"ennuste_pisteet"}};
    } elsif ($param_sort =~ /pisteet/) {
	{$pelaaja{$a}{"pisteet"} <=> $pelaaja{$b}{"pisteet"} || $pelaaja{$a}{"ennuste_pisteet"} <=> $pelaaja{$b}{"ennuste_pisteet"}};
    } elsif ($param_sort =~ /laukaukset/) {
	{$pelaaja{$a}{"laukaukset"} <=> $pelaaja{$b}{"laukaukset"} || $pelaaja{$a}{"ennuste_pisteet"} <=> $pelaaja{$b}{"ennuste_pisteet"}};

    } elsif ($param_sort =~ /lpp_per_peli/) {
	{$pelaaja{$a}{"pisteet_per_peli"} <=> $pelaaja{$b}{"pisteet_per_peli"} || $pelaaja{$b}{"ennuste_pisteet"} <=> $pelaaja{$a}{"ennuste_pisteet"}};
    } elsif ($param_sort =~ /lpp/) {
	{$pelaaja{$a}{"lpp"} <=> $pelaaja{$b}{"lpp"} || $pelaaja{$b}{"ennuste_pisteet"} <=> $pelaaja{$a}{"ennuste_pisteet"}};
    } elsif ($param_sort =~ /ennuste/) {
	{$pelaaja{$a}{"ennuste_pisteet"} <=> $pelaaja{$b}{"ennuste_pisteet"} || $pelaaja{$a}{"arvo"} <=> $pelaaja{$b}{"arvo"}};
    }
}

sub print_start_page {
    print "<center>\n";
    
    print_game_days();

    print start_form(-action => "$script_name");
    select_days_form();
    print hidden(-name => 'liiga', -default => "$param_liiga");
    print hidden(-name => 'team_from', -default => "$team_from");
    print hidden(-name => 'sub', -default => "start_page");
    print submit('Update');
    print endform;

    print_team_compare_table();
    calculate_optimal_change_day();
    
    print "<\/center>\n";
}

sub select_days_form {
    print "Start <select name=\"start_day\">\n";
    foreach (@all_day_list) {
	if (/$start/) {
	    print "<option selected>$_</option>\n";
	} else {
	    print "<option>$_</option>\n";
	}
    }
    print "</select>\n";

    print "End <select name=\"end_day\">\n";
    foreach (@all_day_list) {
	if (/$end/) {
	    print "<option selected>$_</option>\n";
	} else {
	    print "<option>$_</option>\n";
	}
    }
    print "</select>\n";
}

sub select_teams_form {
    my $count = shift;
    print "Vaihda pelaaja joukkueesta <select name=\"team_from\">\n";
    foreach (sort keys %kaikkipelit) {
	if (/$team_from/) {
	    print "<option selected>$_</option>\n";
	} else {
	    print "<option>$_</option>\n";
	}
    }
    print "</select> pelej&#228; $count\n";
}

sub print_team_compare_table {
    my $td = change_table_td();
    print "<table border=\"1\">\n";
    foreach (sort hashValueAscendingNum keys %kaikkipelit) {
        $td = change_table_td($td);
	print "<tr>\n";
	print "<td title=\"$kaikkipelit{$_} peli&#228;\" class=\"$td\">$_<\/td>\n";
        print "<td class=\"$td\">\n";
	if (!defined $kotipelit{$_}) { $kotipelit{$_} = 0; }
	for (my $i = 0; $i < $kotipelit{$_}; $i++) {
	    print "<p title=\"$kotipelit{$_} kotipeli&#228;\" style=\"background: green; width: 9px; height: 8px; float:left; margin:0;\">\n";
	    print "<p title=\"$kotipelit{$_} kotipeli&#228;\" style=\"background: white; width: 2px; height: 8px; float:left; margin:0;\">\n";
	}
        if (!defined $vieraspelit{$_}) { $vieraspelit{$_} = 0; }
	for (my $i = 0; $i < $vieraspelit{$_}; $i++) {
	    print "<p title=\"$vieraspelit{$_} vieraspeli&#228;\" style=\"background: white; width: 2px; height: 8px; float:left; margin:0;\">\n" if $i ne 0;
	    print "<p title=\"$vieraspelit{$_} vieraspeli&#228;\" style=\"background: red; width: 9px; height: 8px; float:left; margin:0;\">\n";
	}
	print "<\/td>\n";

        print "<td class=\"$td\" style=\"width : 8px;\"><\/td>\n";

        print "<td class=\"$td\">\n";
	if (!defined $vastus{$_}{'low'}) { $vastus{$_}{'low'} = 0; }
	for (my $i = 0; $i < $vastus{$_}{'low'}; $i++) {
	    if ($param_liiga =~ /sm/) {
	        print "<p title=\"$vastus{$_}{'low'} vastustaja(a) sijoilta 11-14\" style=\"background: green; width: 9px; height: 8px; float:left; margin:0;\">\n";
	        print "<p title=\"$vastus{$_}{'low'} vastustaja(a) sijoilta 11-14\" style=\"background: white; width: 2px; height: 8px; float:left; margin:0;\">\n";
	    } else {
	        print "<p title=\"$vastus{$_}{'low'} vastustaja(a) sijoilta 11-15\" style=\"background: green; width: 9px; height: 8px; float:left; margin:0;\">\n";
	        print "<p title=\"$vastus{$_}{'low'} vastustaja(a) sijoilta 11-15\" style=\"background: white; width: 2px; height: 8px; float:left; margin:0;\">\n";
	    }
	}
        if (!defined $vastus{$_}{'mid'}) { $vastus{$_}{'mid'} = 0; }
	for (my $i = 0; $i < $vastus{$_}{'mid'}; $i++) {
	    print "<p title=\"$vastus{$_}{'mid'} vastustaja(a) sijoilta 6-10\" style=\"background: yellow; width: 9px; height: 8px; float:left; margin:0;\">\n";
	    print "<p title=\"$vastus{$_}{'mid'} vastustaja(a) sijoilta 6-10\" style=\"background: white; width: 2px; height: 8px; float:left; margin:0;\">\n";
	}
        if (!defined $vastus{$_}{'top'}) { $vastus{$_}{'top'} = 0; }
	for (my $i = 0; $i < $vastus{$_}{'top'}; $i++) {
	    print "<p title=\"$vastus{$_}{'top'} vastustaja(a) sijoilta 1-5\" style=\"background: red; width: 9px; height: 8px; float:left; margin:0;\">\n";
	    print "<p title=\"$vastus{$_}{'top'} vastustaja(a) sijoilta 1-5\" style=\"background: white; width: 2px; height: 8px; float:left; margin:0;\">\n";
	}
	print "<\/td>\n";
	print "<\/tr>\n";
    }
    print "<\/table><br>\n";
}

sub print_current_table {
    print "<center>\n";
    print "<table border=\"1\">\n";
    print "<tr>\n";
    my @otsikot = ("Sija", "Joukkue", "Pelit", "Pisteet");
    foreach (@otsikot) {
        print "<th><center>$_</center></th>\n";
    }
    print "<\/tr>\n";
    my $td = change_table_td();
    foreach (sort {$taulukko{$a}{'sija'} <=> $taulukko{$b}{'sija'}} keys %taulukko) {
        $td = change_table_td($td);
	print "<tr>\n";
	print "<td class=\"$td\">$taulukko{$_}{'sija'}<\/td>\n";
	print "<td class=\"$td\">$_<\/td>\n";
	print "<td class=\"$td\">$taulukko{$_}{'pelit'}<\/td>\n";
	print "<td class=\"$td\">$taulukko{$_}{'pisteet'}<\/td>\n";
	print "<\/tr>\n";
    }
    print "<\/table><br>\n";
    print "<\/center>\n";
}

sub print_game_days {
    # lasketaan onko 3 (tai enemman) peli� tai lepoa putkeen
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

    print "<table border=\"1\">\n";
    print "<tr>\n";
    
    # Tulosta pelipäivät
    print "<th><center>Joukkue</center></th>\n";
    my $count = 0;
    foreach (@selected_day_list) {
	print "<th><center>$weekdays[$count]<br>\n$_</center></th>\n";
        $count++;
    }
    
    my $td = change_table_td();
    # Tulosta joukkueet ja pelaako
    foreach my $joukkue (sort hashValueAscendingNum keys %kaikkipelit) {
        $td = change_table_td($td);
        print "<tr>\n";
	print "<td class=\"$td\">$joukkue<\/td>\n";
	foreach (@selected_day_list) {
	    if (! defined $pelipaivat{$joukkue}{$_}) {
		if (defined $peliputki{$joukkue}{$_} && $peliputki{$joukkue}{$_} eq "lepo") {
	            print "<td class=\"$td\" title=\"3 tai useampi vapaata putkeen\"><center><b><font color=\"red\">x<\/font><\/b></center><\/td>\n";
		} else {
	            print "<td class=\"$td\"><center>-</center><\/td>\n";
		}
	    } elsif (defined $pelipaivat{$joukkue}{$_}{'kotipeli'}) {
		if (defined $peliputki{$joukkue}{$_} && $peliputki{$joukkue}{$_} eq "peli") {
		    print "<td class=\"$td\" title=\"3 tai useampi peli&#228; putkeen\"><center><b><font color=\"green\">$pelipaivat{$joukkue}{$_}{'kotipeli'}<\/font><\/b></center><\/td>\n";
		} else {
		    print "<td class=\"$td\"><center><b>$pelipaivat{$joukkue}{$_}{'kotipeli'}</b></center><\/td>\n";
		}
	    } elsif (defined $pelipaivat{$joukkue}{$_}{'vieraspeli'}) {
		if (defined $peliputki{$joukkue}{$_} && $peliputki{$joukkue}{$_} eq "peli") {
		    print "<td class=\"$td\" title=\"3 tai useampi peli&#228; putkeen\"><center><font color=\"green\">$pelipaivat{$joukkue}{$_}{'vieraspeli'}<\/font></center><\/td>\n";
		} else {
		    print "<td class=\"$td\"><center>$pelipaivat{$joukkue}{$_}{'vieraspeli'}</center><\/td>\n";
		}
	    }
	}
	print "<\/tr>\n";
    }

    print "<\/tr>\n";
    print "<\/table><br>\n";
}

sub calculate_optimal_change_day {
    my $topic_print = 1;
    my $td = change_table_td();
    my $from_count = 0;

    foreach my $team_to (sort hashValueAscendingNum keys %kaikkipelit) {
        my @day_to_change;
        my $max_difference;
    
        my $to_count = 0;
        my $games_after_change_count = 0;
	my $continue_count = 0;
        $from_count = 0;

        if ($team_from eq $team_to) { next ;}
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
            if (! defined $max_difference || $from_count - $to_count > $max_difference) {
                $max_difference = $from_count - $to_count;
                @day_to_change = "$_";
                $games_after_change_count = $from_count;
		$continue_count = 1;
            }
        }
    
        if ($topic_print) {
	    #print "<b>$team_from</b>, pelej&#228; $from_count.<br>\n";
	    $topic_print = 0;

            print "<table border=\"1\">\n";
            print "<tr>\n";
    
            # Tulosta otsikot
            print "<th><center>Joukkue</center></th>\n";
            print "<th><center>Pelit</center></th>\n";
	    print "<th><center>Yht.</center></th>\n";
	    print "<th><center>Ohje</center></th>\n";
	    print "<th><center>P&#228;iv&#228;t</center></th>\n";
	}
    
        $td = change_table_td($td);
        print "<tr>\n";
	print "<td class=\"$td\">$team_to<\/td>\n";
	print "<td class=\"$td\">$to_count<\/td>\n";

        if ($to_count > $games_after_change_count) {
            #print "<b>$team_to</b>, pelej&#228; $to_count. Pelej&#228; yhteens&#228; $to_count, kun teet vaihdon ennen seuraavan p&#228;iv&#228;n peli&#228;: $day_to_change[0]<br><br>\n";
	    print "<td class=\"$td\">$to_count<\/td>\n";
	    print "<td class=\"$td\">Vaihto ennen seuraavan p&#228;iv&#228;n peli&#228;<\/td>\n";
	    print "<td class=\"$td\">$day_to_change[0]<\/td>\n";
        } else {
            #print "<b>$team_to</b>, pelej&#228; $to_count. Pelej&#228; yhteens&#228; $games_after_change_count, kun teet vaihdon jonain seuraavista p&#228;ivist&#228; (pelien j&#228;lkeen): @day_to_change<br>\n";
	    print "<td class=\"$td\">$games_after_change_count<\/td>\n";
	    print "<td class=\"$td\">Vaihto jonain seuraavista p&#228;ivist&#228; (pelien j&#228;lkeen)<\/td>\n";
	    print "<td class=\"$td\">@day_to_change<\/td>\n";
        }
        print "<\/tr>\n";
    }
    print "<\/tr>\n";
    print "<\/table><br>\n";
    
    print start_form(-action => "$script_name");
    select_teams_form($from_count);
    print hidden(-name => 'liiga', -default => "$param_liiga");
    print hidden(-name => 'start_day', -default => "$start");
    print hidden(-name => 'end_day', -default => "$end");
    print hidden(-name => 'sub', -default => "start_page");
    print submit('Update');
    print endform;
    print "<br>\n";
}

sub hashValueAscendingNum {
   $kaikkipelit{$b} <=> $kaikkipelit{$a} || $kotipelit{$b} <=> $kotipelit{$a} || $vastus{$b}{'low'} <=> $vastus{$a}{'low'} || $vastus{$b}{'mid'} <=> $vastus{$a}{'mid'} || $a cmp $b;
}

sub read_player_list ($) {
    my $players_file = shift;
    my ($joukkue, $pelipaikka);
    
    open FILE, "$players_file" or die "Cant open $players_file\n"; 
    while (<FILE>) {
	if (/^#/) { next; }

        s/\s*$//;

	if (/Maalivahdit/) {
	    $pelipaikka = "Maalivahti";
	    next;
	}
	if (/Puolustajat/) {
	    $pelipaikka = "Puolustaja";
	    next;
	}
	if (/Hyokkaajat/) {
	    $pelipaikka = "Hyokkaaja";
	    next;
	}

        if (/^\s*(\D+)\s*$/) {
            $joukkue = $1;
	    next;
        }
	
	#                  1       2       3       4       5       6       7       8       9                10          11        12
        my $parse = '^\s*(.*?)\s*(\d+)\s*(\d+)\s*(\d+)\s*(\d+)\s*(\d+)\s*(\d+)\s*(\d+)\s*(\d+)\s*.*?\s*(-\d+|\d+)\s+(\d\d\d) (\d)\d\d$';
	#                                           1       2       3       4       5       6       7     8    9                10          11        12
	if ($param_liiga =~ /nhl/) { $parse = '^\s*(.*?)\s*(\d+)\s*(\d+)\s*(\d+)\s*(\d+)\s*(\d+)\s*(\d+)(\s*)(\d+)\s*.*?\s*(-\d+|\d+)\s+(\d\d\d) (\d)\d\d$'; }
	
	#          1       2       3       4       5       6       7       8       9                10          11        12
	#if (/^\s*(.*?)\s*(\d+)\s*(\d+)\s*(\d+)\s*(\d+)\s*(\d+)\s*(\d+)\s*(\d+)\s*(\d+)\s*.*?\s*(-\d+|\d+)\s+(\d\d\d) (\d)\d\d$/) {
	if (/$parse/) {
            # Luetaan vain pelaajat, jotka pelaavat myos 2013
	    if ($param_vuosi == 2012 && $param_sub eq "optimi_joukkue") {
	       if (!defined $pelaaja{$1} && $players_file =~ /2012/) { next; }
	    }
	    $pelaaja{$1}{'ottelut'} += $2;
	    $pelaaja{$1}{'maalit'} += $3;
	    $pelaaja{$1}{'syotot'} += $4;
	    $pelaaja{$1}{'pisteet'} = $pelaaja{$1}{'maalit'} + $pelaaja{$1}{'syotot'};
	    if ($pelipaikka ne "Maalivahti") {
	        $pelaaja{$1}{'laukaukset'} += $9;
	    } else {
	        $pelaaja{$1}{'laukaukset'} = 0;
	    }
	    if ($max_pelatut_pelit < $pelaaja{$1}{'ottelut'}) { $max_pelatut_pelit = $pelaaja{$1}{'ottelut'}; }
            $pelaaja{$1}{'pelipaikka'} = $pelipaikka;
	    if ($param_vuosi == 2012 && $param_sub eq "optimi_joukkue" && defined $pelaaja{$1}{'arvo'}) {
	    } else {
                $pelaaja{$1}{'arvo'} = "$11.$12";
	    }
            $pelaaja{$1}{'lpp'} += $10;
	    
	    # Tama siksi, jos pelaaja on vaihtanut seuraa 2012-2013
	    if (! defined $pelaaja{$1}{'joukkue'}) {
	        $pelaaja{$1}{'joukkue'} = $joukkue;
	    }
	    
	    if ($pelaaja{$1}{'ottelut'} ne "0") {
	        $pelaaja{$1}{'pisteet_per_peli'} = $pelaaja{$1}{'lpp'} / $pelaaja{$1}{'ottelut'}
	    } else {
	        $pelaaja{$1}{'pisteet_per_peli'} = 0;
	    }

            $pelaaja{$1}{'pisteet_per_euro'} = $pelaaja{$1}{'pisteet_per_peli'} / ($pelaaja{$1}{'arvo'} / 100);
	    
	    $pelaaja{$1}{'ennuste_pisteet'} = int($pelaaja{$1}{'pisteet_per_peli'} * $kaikkipelit{$joukkue});
        }
    
    }
    close (FILE);
}

sub change_table_td {
    my $current_td = shift;
    my $new_td;

    if (!defined $current_td || $current_td eq "td1") {
        $new_td = "td2";
    } elsif ($current_td eq "td2") {
        $new_td = "td1";
    }
    
    return $new_td;
}
