#!/usr/bin/perl -w

use strict;
use CGI::Carp qw(fatalsToBrowser);
use CGI qw(:standard);
use CGI::Ajax;
use Time::HiRes qw(usleep gettimeofday tv_interval);

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
my $max_teams = 10;
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

# Nama on vain tulokset arvontaan ->
use List::Util 'shuffle';
my %jaahylla;
# <- Nama on vain tulokset arvontaan

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
my $param_a_script          = $cgi->param('a_script');
my $param_a_script_end      = $cgi->param('a_script_end');
my $param_a_script_start    = $cgi->param('a_script_start');
if (!defined $param_joukkueen_hinta)   { $param_joukkueen_hinta = "2000.0"; }
if (!defined $param_ottelut)           { $param_ottelut = 0; }
if (!defined $param_remove_players)    { $param_remove_players = ""; }
if (!defined $param_vuosi)             { $param_vuosi = 2013; }
if (!defined $param_pelipaikka)        { $param_pelipaikka = "Pelaaja"; }
if (!defined $param_sub)               { $param_sub = ""; }
if (!defined $param_graafi)            { $param_graafi = "LPP ennuste"; }
if (!defined $param_liiga)             { $param_liiga = "sm_liiga"; }
if (!defined $param_sort)              { $param_sort = "lpp_per_peli"; }
if (!defined $param_joukkue)           { $param_joukkue = "Joukkue"; }
if (!defined $param_order)             { $param_order = "descending"; }
if (!defined $param_read_players_from) {
    if ($param_liiga =~ /nhl/) {
        $param_read_players_from = "Jakso 3";
    } else {
        $param_read_players_from = "Jakso 4";
    }
}

my ($pelit, $sarjataulukko, $playoff_joukkueet, $jaljella_olevat_joukkueet);
sub alustus {
    @all_day_list = ();
    @selected_day_list = ();
    %vastus = (); %kotipelit = (); %vieraspelit = (); %kaikkipelit = ();

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
            $end = "15.02.";
        } else {
            $end = "08.02.";
        }
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

        if ((/0\t(.*?)\s*-\s*(.*?)\s*$/ && $param_liiga eq "sm_liiga") || (/^\s*(\D*?)\s*-\s*(.*?)\s*$/ && $param_liiga eq "nhl")) {
            $kotipelit{$1}++;
            $vieraspelit{$2}++;
            $kaikkipelit{$1}++;
            $kaikkipelit{$2}++;
	
	    $pelipaivat{$1}{$pelipaiva}{kotipeli} = $2;
	    $pelipaivat{$2}{$pelipaiva}{vieraspeli} = $1;

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

    if (! defined $team_from) {
        foreach (sort keys %kaikkipelit) {
            $team_from = $_;
	    last;
        }
    }
}
alustus();

my $pjx = new CGI::Ajax( 'print_game_days_div'              => \&print_game_days,
                           'print_team_compare_table_div'     => \&print_team_compare_table,
			   'calculate_optimal_change_day_div' => \&calculate_optimal_change_day,
			   'print_player_list_div'            => \&print_player_list,
			   'print_optimi_joukkue_div'         => \&print_optimi_joukkue,
			   'print_start_day_div'              => \&select_days_start_form,
			   'print_end_day_div'                => \&select_days_end_form,
			   'calculate_game_result_div'        => \&calculate_game_result,
                           'alustus'                          => \&alustus);
print $pjx->build_html( $cgi, \&update_menus);

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
            @jakso = ("Jakso PO", "Jakso 5", "Jakso 4", "Jakso 3", "Jakso 2", "Jakso 1", "Jaksot 1-2", "Jaksot 1-3", "Jaksot 1-4", "Jaksot 1-5", "Jaksot 1-PO");
	} else {
            @jakso = ("Jakso PO", "Jakso 5", "Jakso 4", "Jakso 3", "Jakso 2", "Jakso 1", "Jaksot 1-2", "Jaksot 1-3", "Jaksot 1-4", "Jaksot 1-5", "Jaksot 1-PO");
	}
	return @jakso;
    }
}

sub update_menus {
    my $html;
    $html .= "<html>\n";
    $html .= "<head>\n";
    $html .= "<title>Liigaporssi pilalle tilastojen avulla - Sepeti</title>\n";
    
    my $css = `cat css/css.html`;
    
    $html .= "$css\n";
    
    $html .= "<script type=\"text/javascript\">\n";

    $html .= "var _gaq = _gaq || [];\n";
    $html .= "_gaq.push(['_setAccount', 'UA-26708167-1']);\n";
    $html .= "_gaq.push(['_trackPageview']);\n";

    $html .= "(function() {\n";
    $html .= "    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;\n";
    $html .= "    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';\n";
    $html .= "    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);\n";
    $html .= "})();\n";

    $html .= "</script>\n";

    $html .= "</head>\n";
    
    $html .= "<center>\n";
    
    $html .= "<div id=\"container\">\n";
    $html .= "<ul id=\"nav\">\n";

    if ($param_liiga =~/sm_liiga/) {
        $html .= "<li><A HREF=\"$script_name?sub=print_start_page&liiga=nhl\">NHL</A></li>\n";
    } else {
        $html .= "<li><A HREF=\"$script_name?sub=print_start_page&liiga=sm_liiga\">SM-Liiga</A></li>\n";
    }
    $html .= "<li><A HREF=\"$script_name?sub=print_start_page&liiga=$param_liiga\">Ottelulista</A></li>\n";
    $html .= "<li><A HREF=\"$script_name?sub=player_list&sort=lpp_per_peli&liiga=$param_liiga\">Pelaajalista</A></li>\n";
    $html .= "<li><A HREF=\"$script_name?sub=optimi_joukkue&liiga=$param_liiga\">Optimijoukkue</A></li>\n";
    $html .= "<li><A HREF=\"$script_name?sub=arvo_tulos&liiga=$param_liiga\">Arvo tulos</A></li>\n";
    $html .= "<li><A HREF=\"http://liigaporssi.freehostia.com/mjguest\" target=\"_blank\">Vieraskirja</A></li>\n";
    $html .= "<li><a href=\"mailto:jepponen\@gmail.com\">Mailia</a></li>";
 
    $html .= "</ul>\n";
    $html .= "</div>\n";
    
    $html .= "<br><br>\n";
    
    if ($param_sub =~ /start_page|^\s*$/) { $html .= print_start_page()};
    if ($param_sub =~ /player_list/)      {$html .= print_player_list_form()};
    if ($param_sub =~ /optimi_joukkue/)   {$html .= print_optimi_joukkue_form()};
    if ($param_sub =~ /arvo_tulos/)       {$html .= calculate_game_result_form()};

    $html .= "</center>\n";
    
    return $html;
}

sub print_optimi_joukkue_form {
    alustus();
    read_player_lists();

    my $a_script = "print_optimi_joukkue_div( ['read_players_from','ottelut','arvo','liiga','joukkueen_hinta','remove_players','start_day','end_day','a_script'";
    my @paikka = muuttujien_alustusta("paikka");
    foreach my $paikka (@paikka) {
	$a_script .= ",'$paikka->[4]'";
    }
    $a_script .= "],['optimi_joukkue_div'] );";
    my $a_script_start = $a_script . "print_end_day_div( ['start_day','end_day','a_script_end','liiga'],['end_day_div'] );";
    my $a_script_end = $a_script . "print_start_day_div( ['start_day','end_day','a_script_start','liiga'],['start_day_div'] );";

    my $html;
    $html .= "<input type='hidden' name='a_script' id='a_script' value=\"$a_script\">\n";
    $html .= "<center>\n";
    $html .= "T&#228;ll&#228; sivulla voit koota laskennallisia optimikokoonpanoja antamillasi ehdoilla.<br>\n";

    $html .= "Joukkueen arvo tE\n";
    $html .= "<input type='text' name='joukkueen_hinta' id='joukkueen_hinta' SIZE='6' MAXLENGTH='6' VALUE=\"$param_joukkueen_hinta\">\n";

    $html .= "Pelatut pelit v&#228;h.: <select name=\"ottelut\" id=\"ottelut\" onchange=\"$a_script\">\n";
    my @ottelut_taulukko = (0 .. $max_pelatut_pelit);
    foreach (@ottelut_taulukko) {
        if (defined $param_ottelut && $_ == $param_ottelut) {
            $html .= "<option selected>$_<\/option>\n";
        } elsif (!defined $param_ottelut && $_ == 0) {
            $html .= "<option selected>$_<\/option>\n";
        } else {
            $html .= "<option>$_<\/option>\n";
        }
    }
    $html .= "<\/select>\n";

    # Arvo
    $html .= "Pelaajan arvo alle: \n";
    my @arvotaulukko = ("999", "500", "450", "400", "350", "300", "250");
    $html .= "<select name=\"arvo\" id=\"arvo\" onchange=\"$a_script\">\n";
    foreach my $current_arvo (@arvotaulukko) {
        if (defined $param_arvo && $current_arvo eq $param_arvo) {
	    $html .= "<option selected>$current_arvo<\/option>\n";
	} else {
            $html .= "<option>$current_arvo<\/option>\n";
	}
    }
    $html .= "<\/select>\n";

    # Jakso
    $html .= "<select name=\"read_players_from\" id=\"read_players_from\" onchange=\"$a_script\">\n";
    my @jakso = muuttujien_alustusta("jakso");
    foreach my $current_arvo (@jakso) {
        if ($current_arvo eq $param_read_players_from) {
	    $html .= "<option selected>$current_arvo<\/option>\n";
	} else {
            $html .= "<option>$current_arvo<\/option>\n";
	}
    }
    $html .= "<\/select><br>\n";

    $html .= "<input type='hidden' name='a_script_start' id='a_script_start' value=\"$a_script_start\">\n";
    $html .= "<input type='hidden' name='a_script_end' id='a_script_end' value=\"$a_script_end\">\n";

    $html .= "Valitse aikav&#228;li, jolle haluat optimikokoonpanon laskettavan: \n";

    $html .= "<span id='start_day_div'>" . select_days_start_form($a_script_start) . "</span>\n";
    $html .= "<span id='end_day_div'>" . select_days_end_form($a_script_end) . "</span><br>\n";

    $html .= "<br>Kopioi t&#228;h&#228;n pelaajien nimi&#228;, jotka haluat skipata. Esim. loukkaantuneita pelaajia.<br>\n";
    $html .= "<TEXTAREA NAME='remove_players' id='remove_players' COLS=40 ROWS=5>\n";
    $html .= "<\/TEXTAREA><br>\n";
    $html .= "<br>\n";
    
    $html .= "<div id='optimi_joukkue_div'>" . print_optimi_joukkue($a_script) . "</div>\n";
    
    return $html;
}

sub print_optimi_joukkue {
    my $a_script;
    if (defined $param_a_script) {
        $a_script = $param_a_script;
    } else { $a_script = shift; }
    
    alustus();
    read_player_lists();

    my $html;
    $html .= "<input type='hidden' name='liiga' id='liiga' value=\"$param_liiga\">\n";
    
    my $optimi_pisteet = 0;
    my $optimi_hinta = 0;
    my $hinta;
    my $pisteet;

    my @maalivahdit_karsitut;
    my @puolustajat_karsitut;
#    my @hyokkaajat_karsitut;
    my $hyokkaajat_karsitut;
    
    my @top1_maalivahdit = (-50, -50, -50, -50, -50, -50, -50, -50, -50, -50);
    my @top2_puolustajat = (-50, -50, -50, -50, -50, -50, -50, -50, -50, -50);
    my @top3_hyokkaajat = (-50, -50, -50, -50, -50, -50, -50, -50, -50, -50);
    
    foreach (sort {$pelaaja->{$a}->{arvo} <=> $pelaaja->{$b}->{arvo} || $pelaaja->{$a}->{ennuste_pisteet} <=> $pelaaja->{$b}->{ennuste_pisteet}} keys %{$pelaaja}) {
	if ($playoff_joukkueet !~ $pelaaja->{$_}->{joukkue}) { next; }
	if ($pelaaja->{$_}->{pelipaikka} =~ /Maalivahti/) {
	    push (@maalivahdit_kaikki, "$_, $pelaaja->{$_}->{arvo} tE, Ennuste $pelaaja->{$_}->{ennuste_pisteet}");
	    if ($jaljella_olevat_joukkueet !~ $pelaaja->{$_}->{joukkue}) { next; }
	    if ($pelaaja->{$_}->{ottelut} < $param_ottelut) { next; }
            if ($pelaaja->{$_}->{ennuste_pisteet} <= 0) { next; }
	    if ($param_remove_players =~ /$_/) { next; }
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
	    if ($jaljella_olevat_joukkueet !~ $pelaaja->{$_}->{joukkue}) { next; }
	    if ($pelaaja->{$_}->{ottelut} < $param_ottelut) { next; }
            if ($pelaaja->{$_}->{ennuste_pisteet} <= 0) { next; }
	    if ($param_remove_players =~ /$_/) { next; }
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
	    if ($jaljella_olevat_joukkueet !~ $pelaaja->{$_}->{joukkue}) { next; }
	    if ($pelaaja->{$_}->{ottelut} < $param_ottelut) { next; }
            if ($pelaaja->{$_}->{ennuste_pisteet} <= 0) { next; }
	    if ($param_remove_players =~ /$_/) { next; }
	    if (/$o_hyokkaaja1/ || /$o_hyokkaaja2/ || /$o_hyokkaaja3/) { next; }
	    if (defined $param_arvo && $pelaaja->{$_}->{arvo} > $param_arvo) { next; }
	    if ($pelaaja->{$_}->{ennuste_pisteet} > $top3_hyokkaajat[0]) {
	        $top3_hyokkaajat[0] = $pelaaja->{$_}->{ennuste_pisteet};
		@top3_hyokkaajat = sort {$a <=> $b} @top3_hyokkaajat;
	    } else { next; }
	    push (@$hyokkaajat_karsitut, $_);
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

    $html .= "<table border=\"1\">\n";
    $html .= "<tr>\n";
    
    my @otsikko = ("P", "Kiinnitetty pelaaja", "Nimi", "Joukkue", "Pelatut", "Tulevat", "Arvo", "LPP ennuste", "LPP ennustegraafi");
    foreach (@otsikko) {
        $html .= "<th><center>$_</center></th>\n";
    }
    $html .= "<\/tr>\n";

    my $count = 0;
    @paikka = muuttujien_alustusta("paikka");
    my $td = change_table_td();
    foreach my $paikka (@paikka) {
	$td = change_table_td($td);
	$html .= "<tr>\n";
        $html .= "<td class=\"$td\">$paikka->[3]: <\/td>\n";
	$html .= "<td class=\"$td\">";
	$html .= "<select name=\"$paikka->[4]\" id=\"$paikka->[4]\" onchange=\"$a_script\">\n";
        $html .= "<option>$paikka->[1]<\/option>\n";
	foreach (@{$paikka->[2]}) {
            if (/$paikka->[5]/) {
                $html .= "<option selected>$_<\/option>\n";
            } else {
                $html .= "<option>$_<\/option>\n";
            }
        }
        $html .= "<\/select>\n";
	$html .= "<\/td>\n";
        $html .= "<td class=\"$td\">$paikka->[0]<\/td>\n";
        $html .= "<td class=\"$td\">$pelaaja->{$paikka->[0]}->{joukkue}<\/td>\n";
        $html .= "<td class=\"$td\"><center>$pelaaja->{$paikka->[0]}->{ottelut}</center><\/td>\n";
        $html .= "<td class=\"$td\"><center>$kaikkipelit{$pelaaja->{$paikka->[0]}->{joukkue}}</center><\/td>\n";
        $html .= "<td class=\"$td\">$pelaaja->{$paikka->[0]}->{arvo}<\/td>\n";
        $html .= "<td class=\"$td\"><center>$pelaaja->{$paikka->[0]}->{ennuste_pisteet}</center><\/td>\n";
	
	$optimi_hinta += $pelaaja->{$paikka->[0]}->{arvo};
	$optimi_pisteet += $pelaaja->{$paikka->[0]}->{ennuste_pisteet};
	
	$html .= "<td class=\"$td\">\n";
	my $width = $pelaaja->{$paikka->[0]}->{ennuste_pisteet} / 2;
	if ($width < 0) {
	    $width = abs($width);
	    $html .= "<p style=\"background: red; width: ${width}px; height: 8px;\">\n";
	} else {
	    $html .= "<p style=\"background: green; width: ${width}px; height: 8px;\">\n";
	}
	$html .= "<\/td>\n";

        $html .= "<\/tr>\n";
	$count++;
    }
    $html .= "<\/table>\n";

    $html .= "<br>Pisteet: $optimi_pisteet, hinta: $optimi_hinta<br><br>\n";

    $html .= "Alla laskennan parhaat joukkueet.<br>\n";
    $html .= "<table border=\"1\">\n";
    $html .= "<tr>\n";
    @otsikko = ("Sija", "M", "P1", "P2", "H1", "H2", "H3", "Pisteet", "Hinta");
    foreach (@otsikko) {
        $html .= "<th><center>$_</center></th>\n";
    }
    $html .= "<\/tr>\n";

    my $team_count = 0;
    $td = change_table_td();
    foreach my $pelaajat (sort {$top_teams{3}{$b}{pisteet} <=> $top_teams{3}{$a}{pisteet}} keys %{$top_teams{3}}) {
        $html .= "<tr>\n";
	$team_count++;
	$td = change_table_td($td);
	my @players = split(/,/, $pelaajat);
	$html .= "<td class=\"$td\">$team_count<\/td>\n";
	$html .= "<td class=\"$td\">$players[0]<\/td>\n";
	$html .= "<td class=\"$td\">$players[1]<\/td>\n";
	$html .= "<td class=\"$td\">$players[2]<\/td>\n";
	$html .= "<td class=\"$td\">$players[3]<\/td>\n";
	$html .= "<td class=\"$td\">$players[4]<\/td>\n";
	$html .= "<td class=\"$td\">$players[5]<\/td>\n";
	$html .= "<td class=\"$td\">$top_teams{3}{$pelaajat}{pisteet}<\/td>\n";
	$html .= "<td class=\"$td\">$top_teams{3}{$pelaajat}{hinta}<\/td>\n";
	$html .= "<\/tr>\n";
	if ($team_count == $max_teams) { last; }
    }
    $html .= "<\/table>\n";
    $html .= "<\/center>\n";

    return $html;
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

	for (my $h1_count = 0; $h1_count <= $#$hyokkaajat_karsitut; $h1_count++) {
	    $hyokkaaja1 = $hyokkaajat_karsitut->[$h1_count];';
    }

    if ($o_hyokkaaja2 =~ /Kaikki/) {
        push (@loop_count2, "hyokkaaja2");
	$loops2 = "$loops2" . '
	
	for (my $h2_count = $h1_count + 1; $h2_count <= $#$hyokkaajat_karsitut; $h2_count++) {
	    $hyokkaaja2 = $hyokkaajat_karsitut->[$h2_count];';
    }

    if ($o_hyokkaaja3 =~ /Kaikki/) {
        push (@loop_count2, "hyokkaaja3");
	$loops2 = "$loops2" . '
	
	for (my $h3_count = $h2_count + 1; $h3_count <= $#$hyokkaajat_karsitut; $h3_count++) {
	    $hyokkaaja3 = $hyokkaajat_karsitut->[$h3_count];';
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

sub print_player_list_form {
    my $html;
    alustus();
    read_player_lists();

    my $a_script = "print_player_list_div( ['vuosi','read_players_from','joukkue','pelipaikka','ottelut','arvo','graafi','liiga','sort','order'],['player_list_div'] );";

    # Valikot taulukon karsimiseen
    my $condition = "";
    my $param_list = "";

    # Vuosi
    $html .= "<select name=\"vuosi\" id=\"vuosi\" onchange=\"$a_script\">\n";
    my @vuodet = muuttujien_alustusta("vuodet");
    foreach (@vuodet) {
        if ($_ == $param_vuosi) {
            $html .= "<option selected>$_<\/option>\n";
	    $param_vuosi = $_;
        } else {
            $html .= "<option>$_<\/option>\n";
        }
    }
    $html .= "<\/select>\n";

    #Jakso
    $html .= "<select name=\"read_players_from\" id=\"read_players_from\" onchange=\"$a_script\">\n";
    my @jakso = muuttujien_alustusta("jakso");
    foreach my $current_arvo (@jakso) {
        if ($current_arvo eq $param_read_players_from) {
	    $html .= "<option selected>$current_arvo<\/option>\n";
	    $param_list = "${param_list}&read_players_from=$current_arvo";
	} else {
            $html .= "<option>$current_arvo<\/option>\n";
	}
    }
    $html .= "<\/select>\n";

    # Joukkue
    my @tmp_joukkueet = sort keys %taulukko;
    my @joukkueet = ("Joukkue");
    push (@joukkueet, @tmp_joukkueet);
    $html .= "<select name=\"joukkue\" id=\"joukkue\" onchange=\"$a_script\">\n";
    foreach my $joukkue (@joukkueet) {
        if ($joukkue eq $param_joukkue) {
	    $html .= "<option selected>$joukkue<\/option>\n";
	    if ($joukkue =~ /Jaljella olevat/) {
	        $condition = "if (\$jaljella_olevat_joukkueet !~ /\$pelaaja->{\$nimi}->{joukkue}/) { next; }";
	    } elsif ($joukkue !~ /Joukkue/) {
	        $condition = "if (\$pelaaja->{\$nimi}->{joukkue} !~ /$param_joukkue/) { next; }";
	    }
	    $param_list = "${param_list}&joukkue=$joukkue";
	} else {
            $html .= "<option>$joukkue<\/option>\n";
	}
    }
    $html .= "<\/select>\n";

    # Pelipaikka
    $html .= "<select name=\"pelipaikka\" id=\"pelipaikka\" onchange=\"$a_script\">\n";
    if ($param_pelipaikka =~ /Pelaaja/) {
        $html .= "<option selected>Pelaaja<\/option>\n";
    } else {
        $html .= "<option>Pelaaja<\/option>\n";
    }
    if ($param_pelipaikka =~ /Hyokkaaja/) {
        $html .= "<option selected>Hyokkaaja<\/option>\n";
	$condition = "$condition\n if (\$pelaaja->{\$nimi}->{pelipaikka} !~ /Hyokkaaja/) { next; }";
	$param_list = "${param_list}&pelipaikka=Hyokkaaja";
    } else {
        $html .= "<option>Hyokkaaja<\/option>\n";
    }
    if ($param_pelipaikka =~ /Puolustaja/) {
        $html .= "<option selected>Puolustaja<\/option>\n";
	$condition = "$condition\n if (\$pelaaja->{\$nimi}->{pelipaikka} !~ /Puolustaja/) { next; }";
	$param_list = "${param_list}&pelipaikka=Puolustaja";
    } else {
        $html .= "<option>Puolustaja<\/option>\n";
    }
    if ($param_pelipaikka =~ /Maalivahti/) {
        $html .= "<option selected>Maalivahti<\/option>\n";
	$condition = "$condition\n if (\$pelaaja->{\$nimi}->{pelipaikka} !~ /Maalivahti/) { next; }";
	$param_list = "${param_list}&pelipaikka=Maalivahti";
    } else {
        $html .= "<option>Maalivahti<\/option>\n";
    }
    $html .= "<\/select>\n";

    # Ottelut vahintaan
    $html .= "Ottelut v&#228;h.: <select name=\"ottelut\" id=\"ottelut\" onchange=\"$a_script\">\n";
    my @ottelut_taulukko = (0 .. $max_pelatut_pelit);
    foreach (@ottelut_taulukko) {
        if (defined $param_ottelut && $_ == $param_ottelut) {
            $html .= "<option selected>$_<\/option>\n";
	    $condition = "$condition\n if (\$pelaaja->{\$nimi}->{ottelut} < $_) { next; }";
	    $param_list = "${param_list}&ottelut=$_";
        } elsif (!defined $param_ottelut && $_ == 0) {
            $html .= "<option selected>$_<\/option>\n";
	    $condition = "$condition\n if (\$pelaaja->{\$nimi}->{ottelut} < $_) { next; }";
	    $param_list = "${param_list}&ottelut=$_";
        } else {
            $html .= "<option>$_<\/option>\n";
        }
    }
    $html .= "<\/select>\n";

    # Arvo
    my @arvotaulukko = ("0-X", "200-249", "250-299", "300-349", "350-399", "400-449", "450-499", "500-X", "Alle 200", "Alle 250", "Alle 300", "Alle 350", "Alle 400", "Alle 450", "Alle 500");
    $html .= "<select name=\"arvo\" id=\"arvo\" onchange=\"$a_script\">\n";
    foreach my $current_arvo (@arvotaulukko) {
        if (defined $param_arvo && $current_arvo eq $param_arvo) {
	    $html .= "<option selected>$current_arvo<\/option>\n";
	    if ($current_arvo =~ /(\d+)-(\d+)/) {
	        $condition = "$condition\n if (\$pelaaja->{\$nimi}->{arvo} < $1 || \$pelaaja->{\$nimi}->{arvo} > $2) { next; }";
	    } elsif ($current_arvo =~ /(\d+)-X/) {
	        $condition = "$condition\n if (\$pelaaja->{\$nimi}->{arvo} < $1) { next; }";
	    } elsif ($current_arvo =~ /Alle\s*(\d+)/) {
	        $condition = "$condition\n if (\$pelaaja->{\$nimi}->{arvo} > $1) { next; }";
	    }
	    $param_list = "${param_list}&arvo=$current_arvo";
	} else {
            $html .= "<option>$current_arvo<\/option>\n";
	}
    }
    $html .= "<\/select>\n";

    # Graafi
    $html .= "Graafi: <select name=\"graafi\" id=\"graafi\" onchange=\"$a_script\">\n";
    my @graafit = ("LPP ennuste", "Arvo");
    foreach (@graafit) {
        if (/$param_graafi/) {
            $html .= "<option selected>$_<\/option>\n";
	    $param_graafi = $_;
	    $param_list = "${param_list}&graafi=$_";
        } else {
            $html .= "<option>$_<\/option>\n";
        }
    }
    $html .= "<\/select>\n";
    $html .= "<div id='player_list_div'>" . print_player_list() . "</div>\n";
    
    return $html;
}

sub create_player_list_parser {
    my $condition = "";
    my $param_list = "";

    $param_list = "${param_list}&read_players_from=$param_read_players_from";

    my @tmp_joukkueet = sort keys %taulukko;
    my @joukkueet = ("Joukkue");
    push (@joukkueet, @tmp_joukkueet);
    foreach my $joukkue (@joukkueet) {
        if ($joukkue eq $param_joukkue) {
	    if ($joukkue =~ /Jaljella olevat/) {
	        $condition = "if (\$jaljella_olevat_joukkueet !~ /\$pelaaja->{\$nimi}->{joukkue}/) { next; }";
	    } elsif ($joukkue !~ /Joukkue/) {
	        $condition = "if (\$pelaaja->{\$nimi}->{joukkue} !~ /$param_joukkue/) { next; }";
	    }
	    $param_list = "${param_list}&joukkue=$joukkue";
	}
    }

    $condition = "$condition\n if (\$pelaaja->{\$nimi}->{pelipaikka} !~ /$param_pelipaikka/) { next; }" if ($param_pelipaikka !~ /Pelaaja/);
    $param_list = "${param_list}&pelipaikka=$param_pelipaikka" if ($param_pelipaikka !~ /Pelaaja/) ;

    my @ottelut_taulukko = (0 .. $max_pelatut_pelit);
    foreach (@ottelut_taulukko) {
        if (defined $param_ottelut && $_ == $param_ottelut) {
	    $condition = "$condition\n if (\$pelaaja->{\$nimi}->{ottelut} < $_) { next; }";
	    $param_list = "${param_list}&ottelut=$_";
        } elsif (!defined $param_ottelut && $_ == 0) {
	    $condition = "$condition\n if (\$pelaaja->{\$nimi}->{ottelut} < $_) { next; }";
	    $param_list = "${param_list}&ottelut=$_";
        }
    }

    my @arvotaulukko = ("0-X", "200-249", "250-299", "300-349", "350-399", "400-449", "450-499", "500-X", "Alle 200", "Alle 250", "Alle 300", "Alle 350", "Alle 400", "Alle 450", "Alle 500");
    foreach my $current_arvo (@arvotaulukko) {
        if (defined $param_arvo && $current_arvo eq $param_arvo) {
	    if ($current_arvo =~ /(\d+)-(\d+)/) {
	        $condition = "$condition\n if (\$pelaaja->{\$nimi}->{arvo} < $1 || \$pelaaja->{\$nimi}->{arvo} > $2) { next; }";
	    } elsif ($current_arvo =~ /(\d+)-X/) {
	        $condition = "$condition\n if (\$pelaaja->{\$nimi}->{arvo} < $1) { next; }";
	    } elsif ($current_arvo =~ /Alle\s*(\d+)/) {
	        $condition = "$condition\n if (\$pelaaja->{\$nimi}->{arvo} > $1) { next; }";
	    }
	    $param_list = "${param_list}&arvo=$current_arvo";
	}
    }

    $param_list = "${param_list}&graafi=$param_graafi";
    
    return ($param_list, $condition);
}

sub print_player_list {
    alustus();
    read_player_lists();
    my $nimi;
    my ($param_list, $condition) = create_player_list_parser();
    my $html;
    
    $html .= "<input type='hidden' name='sort' id='sort' value=\"$param_sort\">\n";
    $html .= "<input type='hidden' name='liiga' id='liiga' value=\"$param_liiga\">\n";
    $html .= "<input type='hidden' name='order' id='order' value=\"$param_order\">\n";
    $html .= "<table border=\"1\">\n";
    $html .= "<tr>\n";

    $param_list = "${param_list}&vuosi=$param_vuosi&liiga=$param_liiga";
    
    $html .= "<th><center>Sija</center></th>\n";
    $html .= print_player_list_header("Nimi", "nimi", $param_list);
    $html .= print_player_list_header("Pelipaikka", "pelipaikka", $param_list);
    $html .= print_player_list_header("Joukkue", "joukkue", $param_list);
#    $html .= "<th><center>Pelipaikka</center></th>\n";
#    $html .= "<th><center>Joukkue</center></th>\n";
    $html .= print_player_list_header("Pe", "ottelut", $param_list);
    $html .= print_player_list_header("Ma", "maalit", $param_list);
    $html .= print_player_list_header("Sy", "syotot", $param_list);
    $html .= print_player_list_header("Pi", "pisteet", $param_list);
    $html .= print_player_list_header("La", "laukaukset", $param_list);
    $html .= print_player_list_header("Arvo", "arvo", $param_list);
    $html .= print_player_list_header("LPP", "lpp", $param_list);
    $html .= print_player_list_header("LPP / Peli", "lpp_per_peli", $param_list);
    $html .= print_player_list_header("Hinta/Laatu", "euroa_per_lpp_per_peli", $param_list);
    $html .= print_player_list_header("Ennuste", "ennuste", $param_list);
    $html .= "<th><center>$param_graafi</center></th>\n";
    $html .= "</center></th>\n";
    
    $html .= "<\/tr>\n";

    my $td = change_table_td();
    my $count = 0;
    my $sort_order = "sort_list";
    if ($param_order =~ /ascending/) { $sort_order = "sort_list_ascending"; }


    foreach $nimi (sort $sort_order keys %{$pelaaja}) {
	eval($condition);
        $td = change_table_td($td);
	$count++;
	$html .= "<tr>\n";
	$html .= "<td class=\"$td\">$count<\/td>\n";
	$html .= "<td class=\"$td\">$nimi<\/td>\n";
	$html .= "<td class=\"$td\">$pelaaja->{$nimi}->{pelipaikka}<\/td>\n";
	$html .= "<td class=\"$td\">$pelaaja->{$nimi}->{joukkue}<\/td>\n";
	$html .= "<td class=\"$td\">$pelaaja->{$nimi}->{ottelut}<\/td>\n";
	$html .= "<td class=\"$td\">$pelaaja->{$nimi}->{maalit}<\/td>\n";
	$html .= "<td class=\"$td\">$pelaaja->{$nimi}->{syotot}<\/td>\n";
	$html .= "<td class=\"$td\">$pelaaja->{$nimi}->{pisteet}<\/td>\n";
	$html .= "<td class=\"$td\">$pelaaja->{$nimi}->{laukaukset}<\/td>\n";
	$html .= "<td class=\"$td\">$pelaaja->{$nimi}->{arvo}<\/td>\n";
	$html .= "<td class=\"$td\"><center>$pelaaja->{$nimi}->{lpp}</center><\/td>\n";
	$html .= "<td class=\"$td\"><center>";
	$html .= sprintf("%.2f", $pelaaja->{$nimi}->{pisteet_per_peli});
	$html .= "</center><\/td>\n";
	$html .= "<td class=\"$td\"><center>";
	$html .= sprintf("%.2f", $pelaaja->{$nimi}->{pisteet_per_euro});
	$html .= "</center><\/td>\n";
	$html .= "<td class=\"$td\">";
	$html .= "$pelaaja->{$nimi}->{ennuste_pisteet}";
        $html .= "<\/td>\n";
	$html .= "<td class=\"$td\">\n";
	my $width;
	if ($param_graafi =~ /LPP ennuste/) {
	    $width = $pelaaja->{$nimi}->{ennuste_pisteet} / 2;
	} elsif ($param_graafi =~ /Arvo/) {
	    $width = $pelaaja->{$nimi}->{arvo} / 3;
	}
	if ($width < 0) {
	    $width = abs($width);
	    $html .= "<p style=\"background: red; width: ${width}px; height: 8px;\">\n";
	} else {
	    $html .= "<p style=\"background: green; width: ${width}px; height: 8px;\">\n";
	}
	$html .= "<\/td>\n";

	$html .= "<\/tr>\n";
    }
    $html .= "<\/table>\n";
    
    return $html;
}

sub print_player_list_header {
    my ($header, $sort_name, $param_list) = @_;
    my $a_script = "print_player_list_div( ['vuosi','read_players_from','joukkue','pelipaikka','ottelut','arvo','graafi','liiga','sort__$sort_name','order__descending'],['player_list_div'] );";
    my $html;
    if ($param_sort eq $sort_name && $param_order =~ /descending/) {
        $a_script =~ s/(order__descending)/order__ascending/;
	$html .= "<th class=\"des\"><center><A HREF=\"#\" onclick=\"$a_script\">$header</A></center></th>\n";
    } elsif ($param_sort eq $sort_name) {
        $html .= "<th class=\"asc\"><center><A HREF=\"#\" onclick=\"$a_script\">$header</A></center></th>\n";
    } else {
        $html .= "<th><center><A HREF=\"#\" onclick=\"$a_script\">$header</A></center></th>\n";
    }
    
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

sub sort_list {
    if (! defined $param_sort) { return 0; }
    if ($param_sort =~ /arvo/) {
	{$pelaaja->{$b}->{arvo} <=> $pelaaja->{$a}->{arvo} || $pelaaja->{$b}->{ennuste_pisteet} <=> $pelaaja->{$a}->{ennuste_pisteet}};
    } elsif ($param_sort =~ /euroa_per_lpp_per_peli/) {
	{$pelaaja->{$b}->{pisteet_per_euro} <=> $pelaaja->{$a}->{pisteet_per_euro} || $pelaaja->{$b}->{ennuste_pisteet} <=> $pelaaja->{$a}->{ennuste_pisteet}};
    } elsif ($param_sort =~ /nimi/) {
	{$a cmp $b};
    } elsif ($param_sort =~ /joukkue/) {
	{$pelaaja->{$a}->{joukkue} cmp $pelaaja->{$b}->{joukkue} || $pelaaja->{$b}->{ennuste_pisteet} <=> $pelaaja->{$a}->{ennuste_pisteet}};
    } elsif ($param_sort =~ /pelipaikka/) {
	{$pelaaja->{$a}->{pelipaikka} cmp $pelaaja->{$b}->{pelipaikka} || $pelaaja->{$b}->{ennuste_pisteet} <=> $pelaaja->{$a}->{ennuste_pisteet}};
    } elsif ($param_sort =~ /ottelut/) {
	{$pelaaja->{$b}->{ottelut} <=> $pelaaja->{$a}->{ottelut} || $pelaaja->{$b}->{ennuste_pisteet} <=> $pelaaja->{$a}->{ennuste_pisteet}};
    } elsif ($param_sort =~ /maalit/) {
	{$pelaaja->{$b}->{maalit} <=> $pelaaja->{$a}->{maalit} || $pelaaja->{$b}->{pisteet} <=> $pelaaja->{$a}->{pisteet} || $pelaaja->{$b}->{ennuste_pisteet} <=> $pelaaja->{$a}->{ennuste_pisteet}};
    } elsif ($param_sort =~ /syotot/) {
	{$pelaaja->{$b}->{syotot} <=> $pelaaja->{$a}->{syotot} || $pelaaja->{$b}->{pisteet} <=> $pelaaja->{$a}->{pisteet} || $pelaaja->{$b}->{ennuste_pisteet} <=> $pelaaja->{$a}->{ennuste_pisteet}};
    } elsif ($param_sort =~ /pisteet/) {
	{$pelaaja->{$b}->{pisteet} <=> $pelaaja->{$a}->{pisteet} || $pelaaja->{$b}->{ennuste_pisteet} <=> $pelaaja->{$a}->{ennuste_pisteet} || $pelaaja->{$b}->{ennuste_pisteet} <=> $pelaaja->{$a}->{ennuste_pisteet}};
    } elsif ($param_sort =~ /laukaukset/) {
	{$pelaaja->{$b}->{laukaukset} <=> $pelaaja->{$a}->{laukaukset} || $pelaaja->{$b}->{ennuste_pisteet} <=> $pelaaja->{$a}->{ennuste_pisteet}};
    } elsif ($param_sort =~ /lpp_per_peli/) {
	{$pelaaja->{$b}->{pisteet_per_peli} <=> $pelaaja->{$a}->{pisteet_per_peli} || $pelaaja->{$b}->{ennuste_pisteet} <=> $pelaaja->{$a}->{ennuste_pisteet}};
    } elsif ($param_sort =~ /lpp/) {
	{$pelaaja->{$b}->{lpp} <=> $pelaaja->{$a}->{lpp} || $pelaaja->{$b}->{ennuste_pisteet} <=> $pelaaja->{$a}->{ennuste_pisteet}};
    } elsif ($param_sort =~ /ennuste/) {
	{$pelaaja->{$b}->{ennuste_pisteet} <=> $pelaaja->{$a}->{ennuste_pisteet} || $pelaaja->{$a}->{arvo} <=> $pelaaja->{$b}->{arvo}};
    }
}

sub sort_list_ascending {
    if ($param_sort =~ /arvo/) {
	{$pelaaja->{$a}->{arvo} <=> $pelaaja->{$b}->{arvo} || $pelaaja->{$b}->{ennuste_pisteet} <=> $pelaaja->{$a}->{ennuste_pisteet}};
    } elsif ($param_sort =~ /euroa_per_lpp_per_peli/) {
	{$pelaaja->{$a}->{pisteet_per_euro} <=> $pelaaja->{$b}->{pisteet_per_euro} || $pelaaja->{$b}->{ennuste_pisteet} <=> $pelaaja->{$a}->{ennuste_pisteet}};
    } elsif ($param_sort =~ /nimi/) {
	{$b cmp $a};
    } elsif ($param_sort =~ /joukkue/) {
	{$pelaaja->{$b}->{joukkue} cmp $pelaaja->{$a}->{joukkue} || $pelaaja->{$b}->{ennuste_pisteet} <=> $pelaaja->{$a}->{ennuste_pisteet}};
    } elsif ($param_sort =~ /pelipaikka/) {
	{$pelaaja->{$b}->{pelipaikka} cmp $pelaaja->{$a}->{pelipaikka} || $pelaaja->{$b}->{ennuste_pisteet} <=> $pelaaja->{$a}->{ennuste_pisteet}};
    } elsif ($param_sort =~ /ottelut/) {
	{$pelaaja->{$a}->{ottelut} <=> $pelaaja->{$b}->{ottelut} || $pelaaja->{$b}->{ennuste_pisteet} <=> $pelaaja->{$a}->{ennuste_pisteet}};
    } elsif ($param_sort =~ /maalit/) {
	{$pelaaja->{$a}->{maalit} <=> $pelaaja->{$b}->{maalit} || $pelaaja->{$a}->{pisteet} <=> $pelaaja->{$b}->{pisteet} || $pelaaja->{$b}->{ennuste_pisteet} <=> $pelaaja->{$a}->{ennuste_pisteet}};
    } elsif ($param_sort =~ /syotot/) {
	{$pelaaja->{$a}->{syotot} <=> $pelaaja->{$b}->{syotot} || $pelaaja->{$a}->{pisteet} <=> $pelaaja->{$b}->{pisteet} || $pelaaja->{$b}->{ennuste_pisteet} <=> $pelaaja->{$a}->{ennuste_pisteet}};
    } elsif ($param_sort =~ /pisteet/) {
	{$pelaaja->{$a}->{pisteet} <=> $pelaaja->{$b}->{pisteet} || $pelaaja->{$a}->{ennuste_pisteet} <=> $pelaaja->{$b}->{ennuste_pisteet}};
    } elsif ($param_sort =~ /laukaukset/) {
	{$pelaaja->{$a}->{laukaukset} <=> $pelaaja->{$b}->{laukaukset} || $pelaaja->{$a}->{ennuste_pisteet} <=> $pelaaja->{$b}->{ennuste_pisteet}};
    } elsif ($param_sort =~ /lpp_per_peli/) {
	{$pelaaja->{$a}->{pisteet_per_peli} <=> $pelaaja->{$b}->{pisteet_per_peli} || $pelaaja->{$b}->{ennuste_pisteet} <=> $pelaaja->{$a}->{ennuste_pisteet}};
    } elsif ($param_sort =~ /lpp/) {
	{$pelaaja->{$a}->{lpp} <=> $pelaaja->{$b}->{lpp} || $pelaaja->{$b}->{ennuste_pisteet} <=> $pelaaja->{$a}->{ennuste_pisteet}};
    } elsif ($param_sort =~ /ennuste/) {
	{$pelaaja->{$a}->{ennuste_pisteet} <=> $pelaaja->{$b}->{ennuste_pisteet} || $pelaaja->{$a}->{arvo} <=> $pelaaja->{$b}->{arvo}};
    }
}

sub print_start_page {
    my $a_script_start = "print_game_days_div( ['start_day','end_day','team_from','liiga'],['game_days_div'] ); print_team_compare_table_div( ['start_day','end_day','team_from','liiga'],['team_compare_table_div'] ); calculate_optimal_change_day_div( ['start_day','end_day','team_from','liiga'],['optimal_change_day_div','peli_count_div'] ); print_end_day_div( ['start_day','end_day','a_script_end','liiga'],['end_day_div'] );";
    my $a_script_end = "print_game_days_div( ['start_day','end_day','team_from','liiga'],['game_days_div'] ); print_team_compare_table_div( ['start_day','end_day','team_from','liiga'],['team_compare_table_div'] ); calculate_optimal_change_day_div( ['start_day','end_day','team_from','liiga'],['optimal_change_day_div','peli_count_div'] ); print_start_day_div( ['start_day','end_day','a_script_start','liiga'],['start_day_div'] );";
       
    my $html;
    $html .= "<input type='hidden' name='a_script_start' id='a_script_start' value=\"$a_script_start\">\n";
    $html .= "<input type='hidden' name='a_script_end' id='a_script_end' value=\"$a_script_end\">\n";
    $html .= "<center>\n";
    $html .= "<div id='game_days_div'>" . print_game_days() . "</div>\n";
    $html .= "<span id='start_day_div'>" . select_days_start_form($a_script_start) . "</span>\n";
    $html .= "<span id='end_day_div'>" . select_days_end_form($a_script_end) . "</span><p>\n";
    $html .= "<input type='hidden' name='liiga' id='liiga' value=\"$param_liiga\">\n";
    $html .= "<div id='team_compare_table_div'>" . print_team_compare_table() . "</div>\n";
    my ($html_temp, $from_count) = calculate_optimal_change_day();
    $html .= "<div id='optimal_change_day_div'>$html_temp</div>\n";
    $html .= select_teams_form($from_count);
    $html .= "<\/center>\n";
    
    return $html;
}

sub select_days_start_form {
    my $a_script;
    if (defined $param_a_script_start) {
        $a_script = $param_a_script_start;
    } else { $a_script = shift; }

    my $html;

    $html .= "Start <select name=\"start_day\" id=\"start_day\" onchange=\"$a_script\">\n";
    foreach (@all_day_list) {
	if (/$start/) {
	    $html .= "<option selected>$_</option>\n";
	} else {
	    $html .= "<option>$_</option>\n";
	}
	if (/$end/) { last; }
    }
    $html .= "</select>\n";
    
    return $html;
}

sub select_days_end_form {
    my $a_script;
    if (defined $param_a_script_end) {
        $a_script = $param_a_script_end;
    } else { $a_script = shift; }

    my $start_found = 0;
    my $html;

    $html .= "End <select name=\"end_day\" id=\"end_day\" onchange=\"$a_script\">\n";
    foreach (@all_day_list) {
	if ($_ =~ /$start/) { $start_found = 1; }
	if (!$start_found) { next; }
	if (/$end/) {
	    $html .= "<option selected>$_</option>\n";
	} else {
	    $html .= "<option>$_</option>\n";
	}
    }
    $html .= "</select>\n";
    
    return $html;
}

sub select_teams_form {
    my $html;
    
    my $count = shift;
    $html .= "Vaihda pelaaja joukkueesta <select name=\"team_from\" id=\"team_from\" onchange=\"calculate_optimal_change_day_div( ['start_day','end_day','team_from','liiga'],['optimal_change_day_div','peli_count_div'] );\">\n";
    foreach (sort keys %kaikkipelit) {
        $html .= "<option>$_</option>\n";
    }
    $html .= "</select> pelej&#228; <span id='peli_count_div'>$count</span>\n";
    
    return $html;
}

sub print_team_compare_table {
    alustus();

    my $html;
    my $td = change_table_td();
    $html .= "<table border=\"1\">\n";
    foreach (sort hashValueAscendingNum keys %kaikkipelit) {
        $td = change_table_td($td);
	$html .= "<tr>\n";
	$html .= "<td title=\"$kaikkipelit{$_} peli&#228;\" class=\"$td\">$_<\/td>\n";
        $html .= "<td class=\"$td\">\n";
	if (!defined $kotipelit{$_}) { $kotipelit{$_} = 0; }
	for (my $i = 0; $i < $kotipelit{$_}; $i++) {
	    $html .= "<p title=\"$kotipelit{$_} kotipeli&#228;\" style=\"background: green; width: 9px; height: 8px; float:left; margin:0;\">\n";
	    $html .= "<p title=\"$kotipelit{$_} kotipeli&#228;\" style=\"background: white; width: 2px; height: 8px; float:left; margin:0;\">\n";
	}
        if (!defined $vieraspelit{$_}) { $vieraspelit{$_} = 0; }
	for (my $i = 0; $i < $vieraspelit{$_}; $i++) {
	    $html .= "<p title=\"$vieraspelit{$_} vieraspeli&#228;\" style=\"background: white; width: 2px; height: 8px; float:left; margin:0;\">\n" if $i ne 0;
	    $html .= "<p title=\"$vieraspelit{$_} vieraspeli&#228;\" style=\"background: red; width: 9px; height: 8px; float:left; margin:0;\">\n";
	}
	$html .= "<\/td>\n";

        $html .= "<td class=\"$td\" style=\"width : 8px;\"><\/td>\n";

        $html .= "<td class=\"$td\">\n";
	if (!defined $vastus{$_}{low}) { $vastus{$_}{low} = 0; }
	for (my $i = 0; $i < $vastus{$_}{low}; $i++) {
	    if ($param_liiga =~ /sm/) {
	        $html .= "<p title=\"$vastus{$_}{low} vastustaja(a) sijoilta 11-14\" style=\"background: green; width: 9px; height: 8px; float:left; margin:0;\">\n";
	        $html .= "<p title=\"$vastus{$_}{low} vastustaja(a) sijoilta 11-14\" style=\"background: white; width: 2px; height: 8px; float:left; margin:0;\">\n";
	    } else {
	        $html .= "<p title=\"$vastus{$_}{low} vastustaja(a) sijoilta 11-15\" style=\"background: green; width: 9px; height: 8px; float:left; margin:0;\">\n";
	        $html .= "<p title=\"$vastus{$_}{low} vastustaja(a) sijoilta 11-15\" style=\"background: white; width: 2px; height: 8px; float:left; margin:0;\">\n";
	    }
	}
        if (!defined $vastus{$_}{mid}) { $vastus{$_}{mid} = 0; }
	for (my $i = 0; $i < $vastus{$_}{mid}; $i++) {
	    $html .= "<p title=\"$vastus{$_}{mid} vastustaja(a) sijoilta 6-10\" style=\"background: yellow; width: 9px; height: 8px; float:left; margin:0;\">\n";
	    $html .= "<p title=\"$vastus{$_}{mid} vastustaja(a) sijoilta 6-10\" style=\"background: white; width: 2px; height: 8px; float:left; margin:0;\">\n";
	}
        if (!defined $vastus{$_}{top}) { $vastus{$_}{top} = 0; }
	for (my $i = 0; $i < $vastus{$_}{top}; $i++) {
	    $html .= "<p title=\"$vastus{$_}{top} vastustaja(a) sijoilta 1-5\" style=\"background: red; width: 9px; height: 8px; float:left; margin:0;\">\n";
	    $html .= "<p title=\"$vastus{$_}{top} vastustaja(a) sijoilta 1-5\" style=\"background: white; width: 2px; height: 8px; float:left; margin:0;\">\n";
	}
	$html .= "<\/td>\n";
	$html .= "<\/tr>\n";
    }
    $html .= "<\/table><br>\n";
    
    return $html;
}

sub print_game_days {
    alustus();
    
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

    $html .= "<table border=\"1\">\n";
    $html .= "<tr>\n";
    
    # Tulosta pelipäivät
    $html .= "<th><center>Joukkue</center></th>\n";
    my $count = 0;
    foreach (@selected_day_list) {
	$html .= "<th><center>$weekdays[$count]<br>\n$_</center></th>\n";
        $count++;
    }
    
    my $td = change_table_td();
    # Tulosta joukkueet ja pelaako
    foreach my $joukkue (sort hashValueAscendingNum keys %kaikkipelit) {
        $td = change_table_td($td);
        $html .= "<tr>\n";
	$html .= "<th>$joukkue<\/th>\n";
	foreach (@selected_day_list) {
	    if (! defined $pelipaivat{$joukkue}{$_}) {
		if (defined $peliputki{$joukkue}{$_} && $peliputki{$joukkue}{$_} eq "lepo") {
	            $html .= "<td class=\"$td\" title=\"3 tai useampi vapaata putkeen\"><center><b><font color=\"red\">x<\/font><\/b></center><\/td>\n";
		} else {
	            $html .= "<td class=\"$td\"><center>-</center><\/td>\n";
		}
	    } elsif (defined $pelipaivat{$joukkue}{$_}{kotipeli}) {
		if (defined $peliputki{$joukkue}{$_} && $peliputki{$joukkue}{$_} eq "peli") {
		    $html .= "<td class=\"$td\" title=\"3 tai useampi peli&#228; putkeen\"><center><b><font color=\"green\">$pelipaivat{$joukkue}{$_}{kotipeli}<\/font><\/b></center><\/td>\n";
		} else {
		    $html .= "<td class=\"$td\"><center><b>$pelipaivat{$joukkue}{$_}{kotipeli}</b></center><\/td>\n";
		}
	    } elsif (defined $pelipaivat{$joukkue}{$_}{vieraspeli}) {
		if (defined $peliputki{$joukkue}{$_} && $peliputki{$joukkue}{$_} eq "peli") {
		    $html .= "<td class=\"$td\" title=\"3 tai useampi peli&#228; putkeen\"><center><font color=\"green\">$pelipaivat{$joukkue}{$_}{vieraspeli}<\/font></center><\/td>\n";
		} else {
		    $html .= "<td class=\"$td\"><center>$pelipaivat{$joukkue}{$_}{vieraspeli}</center><\/td>\n";
		}
	    }
	}
	$html .= "<\/tr>\n";
    }

    $html .= "<\/tr>\n";
    $html .= "<\/table><br>\n";
    
    return $html;
}

sub calculate_optimal_change_day {
    alustus();
    
    my $html;
    
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
	    $topic_print = 0;

            $html .= "<table border=\"1\">\n";
            $html .= "<tr>\n";
    
            # Tulosta otsikot
            $html .= "<th><center>Joukkue</center></th>\n";
            $html .= "<th><center>Pelit</center></th>\n";
	    $html .= "<th><center>Yht.</center></th>\n";
	    $html .= "<th><center>Ohje</center></th>\n";
	    $html .= "<th><center>P&#228;iv&#228;t</center></th>\n";
	}
    
        $td = change_table_td($td);
        $html .= "<tr>\n";
	$html .= "<td class=\"$td\">$team_to<\/td>\n";
	$html .= "<td class=\"$td\">$to_count<\/td>\n";

        if ($to_count > $games_after_change_count) {
	    $html .= "<td class=\"$td\">$to_count<\/td>\n";
	    $html .= "<td class=\"$td\">Vaihto ennen seuraavan p&#228;iv&#228;n peli&#228;<\/td>\n";
	    $html .= "<td class=\"$td\">$day_to_change[0]<\/td>\n";
        } else {
	    $html .= "<td class=\"$td\">$games_after_change_count<\/td>\n";
	    $html .= "<td class=\"$td\">Vaihto jonain seuraavista p&#228;ivist&#228; (pelien j&#228;lkeen)<\/td>\n";
	    $html .= "<td class=\"$td\">@day_to_change<\/td>\n";
        }
        $html .= "<\/tr>\n";
    }
    $html .= "<\/tr>\n";
    $html .= "<\/table><br>\n";

    return ($html, $from_count);
}

sub hashValueAscendingNum {
   $kaikkipelit{$b} <=> $kaikkipelit{$a} || $kotipelit{$b} <=> $kotipelit{$a} || $vastus{$b}{low} <=> $vastus{$a}{low} || $vastus{$b}{mid} <=> $vastus{$a}{mid} || $a cmp $b;
}

sub read_player_list ($$) {
    my $players_file = shift;
    my %pelaaja = @_;
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
	
	#                  1       2       3       4       5       6       7       8       9       10         11        12               13          14    15
        my $parse = '^\s*(.*?)\s*(\d+)\s*(\d+)\s*(\d+)\s*(\d+)\s*(\d+)\s*(\d+)\s*(\d+)\s*(\d+)\s*(\d+)\s*(-\d+|\d+)\s*(\d+)\s*.*?\s*(-\d+|\d+)\s+(\d\d\d) (\d)\d\d$';
	if ($param_liiga =~ /nhl/ && $pelipaikka !~ /Maalivahti/) {
	    #               1       2       3       4       5       6       7    8    9           10           11       12              13          14     15
	    $parse = '^\s*(.*?)\s*(\d+)\s*(\d+)\s*(\d+)\s*(\d+)\s*(\d+)\s*(\d+)(\s*)(\d+)\s*(\d+\s*\d+)\s*(-\d+|\d+)\s*(\d+)\s*.*?\s*(-\d+|\d+)\s+(\d\d\d) (\d)\d\d$';
	}
	if (/$parse/) {
	    $pelaaja{$1}{ottelut} += $2;
	    $pelaaja{$1}{maalit} += $3;
	    $pelaaja{$1}{syotot} += $4;
	    $pelaaja{$1}{pisteet} = $pelaaja{$1}{maalit} + $pelaaja{$1}{syotot};
	    if ($pelipaikka ne "Maalivahti") {
	        $pelaaja{$1}{laukaukset} += $9;
	    } else {
	        $pelaaja{$1}{laukaukset} = 0;
	        $pelaaja{$1}{paastetyt} += $9;
	    }
	    if ($max_pelatut_pelit < $pelaaja{$1}{ottelut}) { $max_pelatut_pelit = $pelaaja{$1}{ottelut}; }
            $pelaaja{$1}{pelipaikka} = $pelipaikka;
            $pelaaja{$1}{jaahyt} += $12;
            $pelaaja{$1}{lpp} += $13;
            $pelaaja{$1}{arvo} = "$14.$15";
            $pelaaja{$1}{joukkue} = $joukkue;
	    
	    if ($pelaaja{$1}{ottelut} ne "0") {
	        $pelaaja{$1}{pisteet_per_peli} = $pelaaja{$1}{lpp} / $pelaaja{$1}{ottelut}
	    } else {
	        $pelaaja{$1}{pisteet_per_peli} = 0;
	    }

            $pelaaja{$1}{pisteet_per_euro} = $pelaaja{$1}{pisteet_per_peli} / ($pelaaja{$1}{arvo} / 100);
	    
	    $pelaaja{$1}{ennuste_pisteet} = int($pelaaja{$1}{pisteet_per_peli} * $kaikkipelit{$joukkue});
        }
    }
    close (FILE);
    
    return %pelaaja;
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

sub calculate_interval ($) {
    my $old = shift;
    my $current_time = [gettimeofday];
    if (!defined $old) { $old = $current_time; }
    my $elapsed_time = tv_interval $old, $current_time;
    
    return $elapsed_time, $current_time;
}

#
######################################################
# Kaikki taman alla on vain tulosten arvontaa varten #
######################################################
#

sub calculate_game_result_form {
    alustus();
    
    my $html;

    # Tulosta joukkueet ja pelaako
    foreach my $joukkue (sort hashValueAscendingNum keys %kaikkipelit) {
	$_ = $start;
	if (defined $pelipaivat{$joukkue}{$_}{'kotipeli'}) {
            my $a_script = "calculate_game_result_div( ['joukkue__$joukkue','liiga__$param_liiga','start_day__$start'],['game_result_div'] );";
	    $html .= "<A HREF=\"#\" onclick=\"$a_script\"><font color=\"red\">$joukkue - $pelipaivat{$joukkue}{$_}{'kotipeli'}</font></A><br>\n";
	}
    }
    $html .= "<p><div id='game_result_div'>\n";
    $html .= "<div style=\"width:400px; padding:5px; border:5px solid gray; margin:0px;\">T&#228;&#228;ll&#228; voit arpoa tulevan kierroksen otteluita. Arvonnassa k&#228;ytet&#228;&#228;n painotuksia, mutta randomia on mukana
             reippaasti. T&#228;m&#228; n&#228;kyy varsinkin pelien lopputuloksissa, jotka vaihtelevat arvontakerrasta toiseen. Sivun
             ei olekaan tarkoitus pyrki&#228; realismiin, vaan on tehty pelk&#228;st&#228;&#228;n huvitteluun.</div>\n";
    $html .= "</div>\n";

    return $html;
}

sub calculate_game_result {
    alustus();
    
    # Luetaan pelaajat kaikista jaksoista (Tama siksi, ettei jakson alussa vaikuta aina yksi peli liikaa)
    $param_read_players_from =~ s/^(\w+)\s+(.*?)$/$1 1-$2/;
    read_player_lists();
    
    my $koti = $param_joukkue;
    my $vieras = $pelipaivat{$param_joukkue}{$start}{'kotipeli'};
    my %joukkueet;
    my %tilastot;
    my $html;
    
    $joukkueet{$koti}{pelit} = $taulukko{$koti}{pelit};
    $joukkueet{$vieras}{pelit} = $taulukko{$vieras}{pelit};
    
    foreach my $nimi (keys %{$pelaaja}) {
	# Alustetaan pelaajakohtaiset tilastot
	foreach (0..$pelaaja->{$nimi}->{maalit} * 2) { push (@{$joukkueet{$pelaaja->{$nimi}->{joukkue}}{maalintekija_pelaaja}}, $nimi); }
	foreach (0..$pelaaja->{$nimi}->{syotot} * 2) { push (@{$joukkueet{$pelaaja->{$nimi}->{joukkue}}{syottaja_pelaaja}}, $nimi); }
	foreach (0..$pelaaja->{$nimi}->{laukaukset}) { push (@{$joukkueet{$pelaaja->{$nimi}->{joukkue}}{laukaukset_pelaaja}}, $nimi); }
	foreach (2..$pelaaja->{$nimi}->{jaahyt}) { push (@{$joukkueet{$pelaaja->{$nimi}->{joukkue}}{jaahyt_pelaaja}}, $nimi); }
	# Alustetaan joukkueen tilastot
	$joukkueet{$pelaaja->{$nimi}->{joukkue}}{maalit} += $pelaaja->{$nimi}->{maalit};
	$joukkueet{$pelaaja->{$nimi}->{joukkue}}{paastetyt} += $pelaaja->{$nimi}->{paastetyt} if ($pelaaja->{$nimi}->{pelipaikka} =~ /Maalivahti/);
	$joukkueet{$pelaaja->{$nimi}->{joukkue}}{laukaukset} += $pelaaja->{$nimi}->{laukaukset};
	$joukkueet{$pelaaja->{$nimi}->{joukkue}}{jaahyt} += $pelaaja->{$nimi}->{jaahyt};
	
	$tilastot{$pelaaja->{$nimi}->{joukkue}}{$nimi}{maalit} = 0;
	$tilastot{$pelaaja->{$nimi}->{joukkue}}{$nimi}{syotot} = 0;
	$tilastot{$pelaaja->{$nimi}->{joukkue}}{$nimi}{laukaukset} = 0;
	$tilastot{$pelaaja->{$nimi}->{joukkue}}{$nimi}{jaahyt} = 0;
    }
    
    foreach ($koti, $vieras) {
        if ($joukkueet{$_}{pelit} > 0) {
	    $joukkueet{$_}{maalit_per_peli} = $joukkueet{$_}{maalit} / $joukkueet{$_}{pelit};
	    $joukkueet{$_}{paastetyt_per_peli} = $joukkueet{$_}{paastetyt} / $joukkueet{$_}{pelit};
	    $joukkueet{$_}{laukaukset_per_peli} = $joukkueet{$_}{laukaukset} / $joukkueet{$_}{pelit};
	    $joukkueet{$_}{jaahyt_per_peli} = int(($joukkueet{$_}{jaahyt} / $joukkueet{$_}{pelit}) / 2);
	} else {
	    $joukkueet{$_}{maalit_per_peli} = 1;
	    $joukkueet{$_}{paastetyt_per_peli} = 1;
	    $joukkueet{$_}{laukaukset_per_peli} = 25;
	    $joukkueet{$_}{jaahyt_per_peli} = 5;
	}
    }
    
    # Arvotaan joukkueiden maalit (vois tarvittaessa jattaa pois, ku arvotaan uudelleen myohemmin pelin sisalla)
    $joukkueet{$koti}{arvotut_maalit} = int(rand($joukkueet{$koti}{maalit_per_peli} * 1.5 + 1) + rand($joukkueet{$vieras}{paastetyt_per_peli}));
    $joukkueet{$vieras}{arvotut_maalit} = int(rand($joukkueet{$vieras}{maalit_per_peli} * 1.5 + 1) + rand($joukkueet{$koti}{paastetyt_per_peli}));
    # Maalimaarat taulukoihin
    my @maali = (1..3600);
    foreach (1..$joukkueet{$koti}{arvotut_maalit}) { $maali[$_] = $koti; }
    foreach (1..$joukkueet{$vieras}{arvotut_maalit}) { $maali[-$_] = $vieras; }
    @maali = shuffle @maali;
    my @maali_koti_yv = (1..3600);
    foreach (1..int($joukkueet{$koti}{arvotut_maalit} * 1.5)) { $maali_koti_yv[$_] = $koti; }
    foreach (1..int($joukkueet{$vieras}{arvotut_maalit} / 2)) { $maali_koti_yv[-$_] = $vieras; }
    @maali_koti_yv = shuffle @maali_koti_yv;
    my @maali_koti_yv2 = (1..3600);
    foreach (1..int($joukkueet{$koti}{arvotut_maalit} * 4)) { $maali_koti_yv2[$_] = $koti; }
    foreach (1..int($joukkueet{$vieras}{arvotut_maalit} / 3)) { $maali_koti_yv2[-$_] = $vieras; }
    @maali_koti_yv2 = shuffle @maali_koti_yv2;
    my @maali_vieras_yv = (1..3600);
    foreach (1..int($joukkueet{$koti}{arvotut_maalit} / 2)) { $maali_vieras_yv[$_] = $koti; }
    foreach (1..int($joukkueet{$vieras}{arvotut_maalit} * 1.5)) { $maali_vieras_yv[-$_] = $vieras; }
    @maali_vieras_yv = shuffle @maali_vieras_yv;
    my @maali_vieras_yv2 = (1..3600);
    foreach (1..int($joukkueet{$koti}{arvotut_maalit} / 3)) { $maali_vieras_yv2[$_] = $koti; }
    foreach (1..int($joukkueet{$vieras}{arvotut_maalit} * 4)) { $maali_vieras_yv2[-$_] = $vieras; }
    @maali_vieras_yv2 = shuffle @maali_vieras_yv2;

    # Arvotaan joukkueiden jaahyt
    my @jaahy = (1..3600);
    foreach (1..$joukkueet{$koti}{jaahyt_per_peli}) { $jaahy[$_] = $koti; }
    foreach (1..$joukkueet{$vieras}{jaahyt_per_peli}) { $jaahy[-$_] = $vieras; }
    @jaahy = shuffle @jaahy;
    
    # Arvotaan joukkueen laukaisumaara
    $joukkueet{$koti}{arvotut_laukaukset} = int(rand($joukkueet{$koti}{laukaukset_per_peli})) + $joukkueet{$koti}{laukaukset_per_peli} / int(rand(3) + 1);
    $joukkueet{$vieras}{arvotut_laukaukset} = int(rand($joukkueet{$vieras}{laukaukset_per_peli})) + $joukkueet{$vieras}{laukaukset_per_peli} / int(rand(3) + 1);

#    $html .= "Ottelut $joukkueet{$koti}{pelit} - $joukkueet{$vieras}{pelit}<br>\n";
#    $html .= "Maalit $joukkueet{$koti}{maalit} - $joukkueet{$vieras}{maalit}<br>\n";
#    $html .= "M_per_peli $joukkueet{$koti}{maalit_per_peli} - $joukkueet{$vieras}{maalit_per_peli}<br>\n";
#    $html .= "Paastetyt $joukkueet{$koti}{paastetyt} - $joukkueet{$vieras}{paastetyt}<br>\n";
    
    my (@maalintekija, @syottaja_1, @syottaja_2, @laukoja, @jaahyilija, $kotimaali, $vierasmaali, $kotijaahy, $vierasjaahy);
    my $koti_count = 0;
    my $vieras_count = 0;
    my @pelikello = (0..3600);
    my $edellinen_maali = 9;
    my $sekunti = 0;
    my $ja_maali = "";
    my $table;
    
    my $td = change_table_td();
    # Kaydaan lapi koko peli sekunti sekunnilta
    foreach my $sekunti (@pelikello) {
	if ($sekunti == 1) {
	    $table .= "<tr><th></th><th><center>1. Er&auml;</center></th><th></th></tr>\n";
	}
	if ($sekunti == 1201) {
	    $table .= "<tr><th></th><th><center>2. Er&auml;</center></th><th></th></tr>\n";
	    $td = change_table_td();
	    $edellinen_maali = 9;
	}
	if ($sekunti == 2401) {
	    $table .= "<tr><th></th><th><center>3. Er&auml;</center></th><th></th></tr>\n";
	    $td = change_table_td();
	    $edellinen_maali = 9;
	}
	if ($sekunti == 3601) {
	    $table .= "<tr><th></th><th><center>JA</center></th><th></th></tr>\n";
	    $td = change_table_td();
	    $edellinen_maali = 9;
	}

	# Jaahyt kuluu
	my %jaahylla_oleva_joukkue;
	my $yv_av_tv_maali = "";
	$jaahylla_oleva_joukkue{$koti} = 0;
	$jaahylla_oleva_joukkue{$vieras} = 0;
	foreach my $pelaaja (keys %jaahylla) {
	    if ($jaahylla{$pelaaja}{aika} == 0) {
	        delete $jaahylla{$pelaaja};
	    } else {
	        $jaahylla{$pelaaja}{aika}--;
		$jaahylla_oleva_joukkue{$jaahylla{$pelaaja}{joukkue}}++;
	    }
	}
	
	my $temp = int(rand(3600));
	my $joukkue_maali;
	if ($jaahylla_oleva_joukkue{$koti} == $jaahylla_oleva_joukkue{$vieras} || ($jaahylla_oleva_joukkue{$koti} > 1 && $jaahylla_oleva_joukkue{$vieras} > 1)) {
	    $joukkue_maali = $maali[$temp];
	} elsif ($jaahylla_oleva_joukkue{$koti} == $jaahylla_oleva_joukkue{$vieras} - 1) {
	    $joukkue_maali = $maali_koti_yv[$temp];
	} elsif ($jaahylla_oleva_joukkue{$koti} - 1 == $jaahylla_oleva_joukkue{$vieras}) {
	    $joukkue_maali = $maali_vieras_yv[$temp];
	} elsif ($jaahylla_oleva_joukkue{$koti} < $jaahylla_oleva_joukkue{$vieras}) {
	    $joukkue_maali = $maali_koti_yv2[$temp];
	} elsif ($jaahylla_oleva_joukkue{$koti} > $jaahylla_oleva_joukkue{$vieras}) {
	    $joukkue_maali = $maali_vieras_yv2[$temp];
	}
	my $joukkue_jaahy = $jaahy[$temp];
	$edellinen_maali-- if ($edellinen_maali > 0);

        my $pisteet = int(rand(12));

        # Peli ratkeaa VL-kisaan
	if ($sekunti == 3900) {
	    $ja_maali = "VL";
	    $pisteet = 0;
	    $yv_av_tv_maali = "";
	    foreach (@maali) {
	        if (/\D+/) {
		    $joukkue_maali = $_;
		    last;
		}
	    }
	}
	
	# Jos tulee maali ja edellisesta maalista kulunut asetettu aika
	if ($joukkue_maali !~ /\d+/ && $edellinen_maali == 0) {
	    $edellinen_maali = 9;
	    my $peliaika = calculate_peliaika($sekunti);
	
	    if ($joukkue_maali =~ /$koti/) {
	        $koti_count++;
		$vierasmaali = '&nbsp;';
		if ($jaahylla_oleva_joukkue{$koti} < $jaahylla_oleva_joukkue{$vieras} && $ja_maali !~ /VL/) {
		    $yv_av_tv_maali = "YV";
		    if ($jaahylla_oleva_joukkue{$koti} == 0 && $jaahylla_oleva_joukkue{$vieras} > 1) {
		        $yv_av_tv_maali = "YV2";
		    }
		    # Jaahy loppuu, kun tulee yv maali
		    foreach (sort { $jaahylla{$a}{aika} cmp $jaahylla{$b}{aika} } keys %jaahylla) {
		        if ($jaahylla{$_}{joukkue} =~ /$vieras/) { delete $jaahylla{$_}; }
		    }
		}
		if ($jaahylla_oleva_joukkue{$koti} > $jaahylla_oleva_joukkue{$vieras} && $ja_maali !~ /VL/) { $yv_av_tv_maali = "AV"; }
	    }
	    if ($joukkue_maali =~ /$vieras/) {
	        $vieras_count++;
		$kotimaali = '&nbsp;';
		if ($jaahylla_oleva_joukkue{$koti} > $jaahylla_oleva_joukkue{$vieras} && $ja_maali !~ /VL/) {
		    # Jaahy loppuu, kun tulee yv maali
		    $yv_av_tv_maali = "YV";
		    if ($jaahylla_oleva_joukkue{$vieras} == 0 && $jaahylla_oleva_joukkue{$koti} > 1) {
		        $yv_av_tv_maali = "YV2";
		    }
		    foreach (sort { $jaahylla{$a}{aika} cmp $jaahylla{$b}{aika} } keys %jaahylla) {
		        if ($jaahylla{$_}{joukkue} =~ /$koti/) { delete $jaahylla{$_}; }
		    }
		}
		if ($jaahylla_oleva_joukkue{$koti} < $jaahylla_oleva_joukkue{$vieras} && $ja_maali !~ /VL/) { $yv_av_tv_maali = "AV"; }
	    }
	    if ($jaahylla_oleva_joukkue{$koti} == $jaahylla_oleva_joukkue{$vieras} && $jaahylla_oleva_joukkue{$koti} > 0) { $yv_av_tv_maali = "TV"; }

	    if ($sekunti > 3600 && $ja_maali eq "") {
	        $ja_maali = "JA";
	    }

	    do { @maalintekija = shuffle @{$joukkueet{$joukkue_maali}{maalintekija_pelaaja}} } until $pelaaja->{$maalintekija[0]}->{pelipaikka} !~ /Maalivahti/ && !defined $jaahylla{$maalintekija[0]};
	    $tilastot{$joukkue_maali}{$maalintekija[0]}{maalit}++ if ($ja_maali !~ /VL/);
	    $tilastot{$joukkue_maali}{$maalintekija[0]}{laukaukset}++ if ($ja_maali !~ /VL/);
	    my $maali = "<b>$maalintekija[0] $koti_count - $vieras_count $yv_av_tv_maali $ja_maali </b>\n";
	    if ($pisteet > 1) {
	        do { @syottaja_1 = shuffle @{$joukkueet{$joukkue_maali}{syottaja_pelaaja}} } until $syottaja_1[0] ne $maalintekija[0] && !defined $jaahylla{$maalintekija[0]};
	        $tilastot{$joukkue_maali}{$syottaja_1[0]}{syotot}++;
	        $maali .= "($syottaja_1[0]";
	    }
	    if ($pisteet > 4) {
	        do { @syottaja_2 = shuffle @{$joukkueet{$joukkue_maali}{syottaja_pelaaja}} } until $syottaja_2[0] ne $maalintekija[0] && $syottaja_2[0] ne $syottaja_1[0] && !defined $jaahylla{$maalintekija[0]};
	        $tilastot{$joukkue_maali}{$syottaja_2[0]}{syotot}++;
	        $maali .= ", $syottaja_2[0]";
	    }
	    if ($pisteet > 1) { $maali .= ")"; }

	    if ($joukkue_maali =~ /$koti/) { $kotimaali = $maali; }
	    if ($joukkue_maali =~ /$vieras/) { $vierasmaali = $maali; }
	    $td = change_table_td($td);
            $table .= "<tr>\n";
	    $table .= "<td class=\"$td\">$kotimaali</td>\n";
	    $table .= "<td class=\"$td\">$peliaika</td>\n";
	    $table .= "<td class=\"$td\">$vierasmaali</td>\n";
	    $table .= "</tr>\n";
	}

	# Jos tulee jaahy
	if ($joukkue_jaahy !~ /\d+/) {
	    my $peliaika = calculate_peliaika($sekunti);
	    $edellinen_maali = 4;

	    my $minutes = 2;
	    my $syy = jaahyn_syy($minutes);

	    do { @jaahyilija = shuffle @{$joukkueet{$joukkue_jaahy}{jaahyt_pelaaja}} } until !defined $jaahylla{$jaahyilija[0]};
	    $jaahylla{$jaahyilija[0]}{aika} = $minutes * 60;
	    $jaahylla{$jaahyilija[0]}{joukkue} = $joukkue_jaahy;
	    $tilastot{$joukkue_jaahy}{$jaahyilija[0]}{jaahyt} += $minutes;

	    if ($joukkue_jaahy =~ /$koti/) {
	        $kotijaahy = "$jaahyilija[0] - $syy $minutes min";
		$vierasjaahy = '&nbsp;';
	    }
	    if ($joukkue_jaahy =~ /$vieras/) {
	        $kotijaahy = '&nbsp;';
	        $vierasjaahy = "$jaahyilija[0] - $syy $minutes min";
	    }
            
	    $td = change_table_td($td);
	    $table .= "<tr>\n";
	    $table .= "<td class=\"$td\">$kotijaahy</td>\n";
	    $table .= "<td class=\"$td\">$peliaika</td>\n";
	    $table .= "<td class=\"$td\">$vierasjaahy</td>\n";
	    $table .= "</tr>\n";
	}

        # Peli etenee jatkoajalle
	if ($sekunti == 3600 && $koti_count == $vieras_count) {
	    push (@pelikello, (3601..3900));
        }
	# Peli ratkesi jatkoajalla
	if ($ja_maali ne "") { last; }
    }
    $html .= "<b>$koti - $vieras $koti_count - $vieras_count $ja_maali</b><p>\n";
    $html .= "<table border=\"1\">$table</table><p>\n";

    # Arvotaan laukaukset pelaajille
    foreach my $joukkue ($koti, $vieras) {
        foreach (1..$joukkueet{$joukkue}{arvotut_laukaukset}) {
	    do { @laukoja = shuffle @{$joukkueet{$joukkue}{laukaukset_pelaaja}} } until $pelaaja->{$laukoja[0]}->{pelipaikka} !~ /Maalivahti/;
	    $tilastot{$joukkue}{$laukoja[0]}{laukaukset}++;
	}
    }
    
    # Tulostetaan tilastot
    $html .= "<div align=\"center\">\n";
#$html .= "<table>\n";
    foreach my $joukkue ($koti, $vieras) {
#$html .= "<th valign=\"top\">\n";
	$td = change_table_td();
	$html .= "<table style=\"display: inline-block;\">\n";
#$html .= "<table>\n";
        
	$html .= "<tr>\n";
        my @otsikko = ("Nimi", "Ma", "Sy", "Pi", "La", "Ja");
        foreach (@otsikko) {
            $html .= "<th><center>$_</center></th>\n";
        }
        $html .= "<\/tr>\n";
	
	foreach my $nimi (sort {
	    $tilastot{$joukkue}{$b}{maalit} cmp $tilastot{$joukkue}{$a}{maalit} || 
	    $tilastot{$joukkue}{$b}{syotot} cmp $tilastot{$joukkue}{$a}{syotot} ||
	    $tilastot{$joukkue}{$b}{laukaukset} cmp $tilastot{$joukkue}{$a}{laukaukset} ||
	    $tilastot{$joukkue}{$b}{jaahyt} cmp $tilastot{$joukkue}{$a}{jaahyt}
	    } keys %{$tilastot{$joukkue}}) {
	    my $pisteet = $tilastot{$joukkue}{$nimi}{maalit} + $tilastot{$joukkue}{$nimi}{syotot};
	    $td = change_table_td($td);
	    $html .= "<tr>\n";
	    $html .= "<td class=\"$td\">$nimi</td>\n";
	    $html .= "<td class=\"$td\">$tilastot{$joukkue}{$nimi}{maalit}</td>\n";
	    $html .= "<td class=\"$td\">$tilastot{$joukkue}{$nimi}{syotot}</td>\n";
	    $html .= "<td class=\"$td\">$pisteet</td>\n";
	    $html .= "<td class=\"$td\">$tilastot{$joukkue}{$nimi}{laukaukset}</td>\n";
	    $html .= "<td class=\"$td\">$tilastot{$joukkue}{$nimi}{jaahyt}</td>\n";
	    $html .= "</tr>\n";
	}
	$html .= "</table>\n";
#$html .= "</th>\n";
    }
    $html .= "</div>\n";
#$html .= "</table>\n";

    return $html;
}

sub calculate_peliaika {
    my $sekunti = shift;
    
    my $peliaika = int($sekunti / 60);
    if ($peliaika < 10) { $peliaika = "0$peliaika"; }
    my $sek = $sekunti % 60;
    if ($sek < 10) { $sek = "0$sek"; }
    $peliaika = "$peliaika:$sek";

    return $peliaika;
}

sub jaahyn_syy {
    my $min = shift;
    
    my @jaahyn_syy;
    
    if ($min == 2) {
    @jaahyn_syy = shuffle (
        "Automaattinen kaytosrangaistus",
#        "Automaattinen pelirangaistus kaytoksesta",
        "Estaminen",
        "Huitominen",
        "Joukkuerangaistus",
        "Joukkuerangaistus toimihenkilolle",
        "Kampitus",
        "Keihastaminen",
        "Kiekon peittaminen",
        "Kiekon sulkeminen",
        "Kiinnipitaminen",
        "Kiinnipitaminen vastustajan mailasta",
        "Kohtuuttoman kova peli",
        "Korkea maila",
        "Koukkaaminen",
        "Kyynarpaataklaus",
        "Kaytosrangaistus",
        "Laitataklaus",
        "Leikkaaminen",
        "Liikaa pelaajia jaalla",
        "Maalin tahallinen siirtaminen",
        "Mailan paalla lyominen",
        "Mailan tai muun esineen heitt. pelialueelta",
        "Mailan tai muun esineen heitto",
#        "Nyrkkitappelu",
#        "Ottelurangaistus",
        "Pelin viivyttaminen",
        "Pelin viivyttaminen - kiekko katsomoon",
        "Pelirangaistus kaytoksesta",
        "Pieni kaytosrangaistus",
        "Poikittainen maila",
        "Polvitaklaus",
        "Potkaiseminen",
        "Paahan kohdistuva taklaus",
        "Paalla iskeminen",
        "Rikkoutunut maila",
        "Ryntays",
        "Selasta taklaaminen",
        "Sukeltaminen",
        "Saantojen vastainen varuste",
        "Toimihenkilon lahteminen pelaajapenkilta",
#        "Toimihenkilon ottelurangaistus",
#        "Toimihenkilon pelirangaistus kaytoksesta",
        "Vaarallinen varuste",
        "Varusteiden korjaaminen",
        "Vakivaltaisuus",
    );
    }
    
    return $jaahyn_syy[0];
}
