#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use HTML::Parser;
require LWP::UserAgent;

my $sub;
#my @sm_joukkue = ("Blues", "HIFK", "HPK", "Ilves", "JYP", "KalPa", "Karpat", "Lukko", "Pelicans", "SaiPa", "Sport", "Tappara", "TPS", "Assat");
my @sm_joukkue = ("Blues", "HIFK", "JYP", "KalPa", "Karpat", "Lukko", "SaiPa", "Tappara");
my @nhl_joukkue = ("Anaheim", "Arizona", "Boston", "Buffalo", "Calgary", "Carolina", "Chicago", "Colorado", "Columbus", "Dallas", "Detroit", "Edmonton", "Florida", "Los Angeles", "Minnesota", "Montreal", "Nashville", "New Jersey", "NY Islanders", "NY Rangers", "Ottawa", "Philadelphia", "Pittsburgh", "San Jose", "St. Louis", "Tampa Bay", "Toronto", "Vancouver", "Washington", "Winnipeg");
#my @nhl_joukkue = ("Anaheim", "Arizona", "Boston", "Chicago", "Colorado", "Columbus", "Dallas", "Detroit", "Los Angeles", "Minnesota", "Montreal", "NY Rangers", "Philadelphia", "Pittsburgh", "San Jose", "St. Louis", "Tampa Bay");

GetOptions (
    "sub=s"  => \$sub,
    );

if (!defined $sub) { die "Anna -sub [sub]\n"; }

sub fetch_page($) {
    my $link = shift;
    
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;

    my $data = $ua->get($link);

    if ($data->is_success) {
        return $data->decoded_content
    } else {
        die $data->status_line;
    }
}

sub sm_sarjataulukko {
    my $data = fetch_page("http://liiga.fi/tilastot/2014-2015/runkosarja/joukkueet/");
    my $sijoitus = undef;
    my $column = 0;
    my ($joukkue, $ottelut, $pisteet);

    my $text;
    my $p = HTML::Parser->new(text_h => [ sub {$text .= shift}, 
				  'dtext']);
    $p->parse($data);
    my @text = split(/\n/, $text);

    open FILE, ">table_sm_liiga.txt" or die "Cannot open table_sm_liiga.txt";
    foreach (@text) {
	if (/^\s*$/) { next; }
	$_ = modify_char($_);
	if (/^\s*(\d+)\.\s*$/) {
	    $sijoitus = $1;
	}
	if (defined $sijoitus) { $column++; }
	if (/^\s*(\w+)\s*$/ && $column == 2) {
	    $joukkue = $1;
	}
	if (/(\d+)/ && $column == 3) {
	    $ottelut = $1;
	}
	if (/(\d+)/ && $column == 10) {
	    $pisteet = $1;
	    
	    print FILE "$sijoitus. $joukkue $ottelut $pisteet\n";
	    if ($sijoitus == 14) { last; }
	    $column = 0;
	    $sijoitus = undef;
	}
    }
    close FILE;
}

sub nhl_sarjataulukko {
    my $data = fetch_page("http://www.hockeygm.fi/nhl/sarjataulukko");
    my ($sijoitus, $joukkue, $ottelut, $pisteet);

    my $text;
    my $p = HTML::Parser->new(text_h => [ sub {$text .= shift}, 
				  'dtext']);
    $p->parse($data);
    my @text = split(/\n/, $text);
    my $temp = "";

    foreach (@text) {
        s/\s*$//;
        s/^\s*//;
	if (/\d\.$/) {
	    $temp .= "\n$_ ";
	} else {
	    $temp .= "$_ ";
	}
    }
    
    open FILE, ">table_nhl.txt" or die "Cannot open table_nhl.txt";
    @text = split(/\n/, $temp);
    foreach (@text) {
        if (!/^\d+\./) { next; }
	s/(\d\.\d\d).*?$/$1/;
	print FILE "$_\n";
    }
    close FILE;
}

sub sm_kokoonpanot_kaikki {
    my $team_count = 0;
    my $previous_name = "Z";

    # Listaa tahan nimet, jos aakkosjarjestys ei matsaa. Ts. seuraavan joukkueen ensimmainen pelaaja on aakkosissa toisen joukkueen viimeisen jalkeen
    my @pelaajat = ();
    #my @sm_molket = ("Niemi Timo");
    my @sm_molket = ();
    push (@pelaajat, @sm_molket);

    my %katkaisu_pelaajat;
    foreach (@pelaajat) {
        $katkaisu_pelaajat{$_} = 1;
    }

    my $final_player_list = "";

    my $data = fetch_page("http://www.liigaporssi.fi/team/search-players?player_position=all&player_team=all&player_value=all&type=player_search");

    $data =~ s/player_value\">(.*?)\&euro;</player_value\"> $1 </g;
    $data =~ s/\">(.*?)</\"> $1 </g;

    my $text;
    my $p = HTML::Parser->new(text_h => [ sub {$text .= shift}, 
				  'dtext']);
    $p->parse($data);
    my @text = split(/\n/, $text);

    my $name = "";
    foreach (@text) {
	s/\s*$//;
	s/^\s*//;
	if (/^\s*$/) { next; }
	if (length($_) <= 4) { next; }
	s/-(\s+)/0$1/g;
        if (/LPP\/O/) { next; }
	
	my $line = $_;

	if ($line =~ /^\s*(\D+)\s*$/ && $line !~ /Maalivahdit|Puolustajat|Hy.*kk.*t/) {
            $name = $1;
        }

        # Ala katkase taman kohdalla, edella olevan pelaajan nimi pienella kirjaimella meinaa katkasta
        if ($name =~ /Voracek Jakub/) {
        } elsif (($name lt $previous_name || defined $katkaisu_pelaajat{$name}) && $name ne $previous_name) {
            $final_player_list = "${final_player_list}$sm_joukkue[$team_count]\n";
            $team_count++;
	    if ($team_count > $#sm_joukkue) { $team_count = 0; }
        }

	$line = modify_char($line);

	if ($line =~ /^\s*\D+\s+\D+\s*$/) {
    	    $final_player_list .= "$line ";
    	} else {
    	    $final_player_list .= "$line\n";
    	}
	$previous_name = $name;
    }
    
    #Tsekataan, etta joka joukkueelta saadaan pelaajalista. Ollut joskus ongelmia
    if ($final_player_list =~ /Ei hakutuloksia/) { exit; }

    open FILE, ">2014/player_list_playoff.txt" or die "Cant open 2014/player_list_playoff.txt\n"; 
    
    my @player_list = split(/\n/, $final_player_list);
    my $mikko_lehtonen = 0;
    foreach (@player_list) {
	# Tulostetaan vain eka mikko lehtonen
	if (/Lehtonen Mikko/) {
	    $mikko_lehtonen++;
	    if ($mikko_lehtonen > 1) { next; }
	}
	print FILE "$_\n";
    }

    close (FILE);
}

sub sm_kokoonpanot {
    my $final_player_list = "";

    foreach my $joukkue (@sm_joukkue) {
        $final_player_list .= "$joukkue\n";
        #my $data = fetch_page("http://www.liigaporssi.fi/team/search-players?player_position=all&player_team=all&player_value=all&type=player_search");
        my $data = fetch_page("http://www.liigaporssi.fi/team/search-players?player_position=all&player_team=${joukkue}&player_value=all&type=player_search");

	$data = modify_char($data);

        $data =~ s/player_value\">(.*?)\&euro;</player_value\"> $1 </g;
        $data =~ s/\">(.*?)</\"> $1 </g;
    
        my $text;
        my $p = HTML::Parser->new(text_h => [ sub {$text .= shift}, 
                                      'dtext']);
        $p->parse($data);
        my @text = split(/\n/, $text);
    
        foreach (@text) {
            s/\s*$//;
            s/^\s*//;
    	    if (/^\s*$/) { next; }
    	    if (length($_) <= 4) { next; }
            s/-(\s+)/0$1/g;
            if (/LPP\/O/) { next; }

            if (/^\s*\D+\s+\D+\s*$/) {
	        $final_player_list .= "$_ ";
	    } else {
	        $final_player_list .= "$_\n";
	    }

            #Tsekataan, etta joka joukkueelta saadaan pelaajalista. Ollut joskus ongelmia
            if (/Ei hakutuloksia/) {
                print "Ei hakutuloksia: $joukkue\n";
	        return 0;
            }
        }
    }
    
    open FILE, ">2014/player_list_playoff.txt" or die "Cant open 2014/player_list_playoff.txt\n"; 
    
    my @player_list = split(/\n/, $final_player_list);
    my $mikko_lehtonen = 0;
    foreach (@player_list) {
	# Tulostetaan vain eka mikko lehtonen
	if (/Lehtonen Mikko/) {
	    $mikko_lehtonen++;
	    if ($mikko_lehtonen > 1) { next; }
	}
	print FILE "$_\n";
    }

    close (FILE);
    
    return 1;
}

sub nhl_kokoonpanot {
    my $final_player_list = "";

    foreach my $joukkue (@nhl_joukkue) {
        $final_player_list .= "$joukkue\n";
        #my $data = fetch_page("http://www.hockeygm.fi/team/search-players?player_position=all&player_team=all&player_value=all&type=player_search");
        my $data = fetch_page("http://www.hockeygm.fi/team/search-players?player_position=all&player_team=${joukkue}&player_value=all&type=player_search");

	$data = modify_char($data);

        $data =~ s/player_value\">(.*?)\&euro;</player_value\"> $1 </g;
        $data =~ s/\">(.*?)</\"> $1 </g;
    
        my $text;
        my $p = HTML::Parser->new(text_h => [ sub {$text .= shift}, 
                                      'dtext']);
        $p->parse($data);
        my @text = split(/\n/, $text);
    
        foreach (@text) {
            s/\s*$//;
            s/^\s*//;
    	    if (/^\s*$/) { next; }
    	    if (length($_) <= 4) { next; }
            s/-(\s+)/0$1/g;
            if (/HGMP\/O/) { next; }

            if (/^\s*\D+\s+\D+\s*$/) {
	        $final_player_list .= "$_ ";
	    } else {
	        $final_player_list .= "$_\n";
	    }

            #Tsekataan, etta joka joukkueelta saadaan pelaajalista. Ollut joskus ongelmia
            if (/Ei hakutuloksia/) {
                print "Ei hakutuloksia: $joukkue\n";
	        return 0;
            }
        }
    }
    
    open FILE, ">2014/player_list_period5_nhl.txt" or die "Cant open 2014/player_list_period5_nhl.txt\n"; 
    
    my @player_list = split(/\n/, $final_player_list);
    foreach (@player_list) {
	print FILE "$_\n";
    }

    close (FILE);
    
    return 1;
}

# Ajetaan vasta pelipaivan lopuksi, silla tulostetaan vain paivat taman paivan jalkeen
sub ottelulista ($) {
    my $file = shift;
    my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
    $yearOffset += 1900;
    $month++;
    if ($month < 10) { $month = "0$month"; }
    if ($dayOfMonth < 10) { $dayOfMonth = "0$dayOfMonth"; }
    my $current_date = "$yearOffset-$month-$dayOfMonth";
    my $game_date;
    my $day_found = 0;
    my $new_game_list;

    my @games = `cat $file`;
    foreach (@games) {
        s/\s*$//;

        if (/(\d\d)\.(\d\d)\./) {
	    my $day_nro = $1;
	    my $month_nro = $2;
	    my $year_nro = 2014;
	    $game_date = "$year_nro-$month_nro-$day_nro";
	    
	    if ($current_date lt $game_date) { $day_found = 1; }
	}
	
	if (!$day_found) { next; }
	
	$new_game_list .= "$_\n";
    }
    
    open FILE, ">$file" or die "Cant open $file\n"; 
    print FILE "$new_game_list";
    close (FILE);
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
	
	$return = "$return$_";
    }
    return $return;
}

sub sm_ottelu_id {
    my $year_nro = 2014;
    my $new_game_list;
    my $day_count = 0;
    my %game_id;
    my @games = `cat games.txt`;
    foreach my $game (@games) {
        $game =~ s/\s*$//;

	if ($game =~ /(\d\d)\.(\d\d)\./) {
	    $day_count++;
	}
	
	if ($game =~ /(\d\d)\.(\d\d)\./ && $day_count == 1) {
	    my $day_nro = $1;
	    my $month_nro = $2;
            print "www.sm-liiga.fi/sm-liiga.html?pvm=$year_nro-$month_nro-$day_nro\n";
	    my $data = fetch_page("http://www.sm-liiga.fi/sm-liiga.html?pvm=$year_nro-$month_nro-$day_nro");
	    $data = modify_char($data);
	    my @data = split(/\n/, $data);
	    foreach (@data) {
	        if (/away(\d+)\">(.*?)</) { #"
		    $game_id{$2} = $1;
		}
	    }
	}
        if ($day_count == 1) {
	    if ($game =~ /\w+\s*-\s*([a-zA-Z]+)\s*$/) {
		my $away = $1;
		$game =~ s/$away/$away, $game_id{$away}/;
	    }
	    $game = "$game";
	}
	
	$new_game_list .= "$game\n";
    }
    
    open FILE, ">games.txt" or die "Cant open games.txt\n"; 
    print FILE "$new_game_list";
    close (FILE);
}

if ($sub =~ /sm_ottelulista/) { ottelulista("games_sm_liiga.txt"); }
elsif ($sub =~ /nhl_ottelulista/) { ottelulista("games_nhl.txt"); }
elsif ($sub =~ /sm_sarjataulukko/) { sm_sarjataulukko(); }
elsif ($sub =~ /sm_ottelu_id/) { sm_ottelu_id(); }
elsif ($sub =~ /nhl_sarjataulukko/) { nhl_sarjataulukko(); }
elsif ($sub =~ /nhl_kokoonpanot/) { nhl_kokoonpanot(); }
elsif ($sub =~ /sm_kokoonpanot_kaikki/) { sm_kokoonpanot_kaikki(); }
elsif ($sub =~ /sm_kokoonpanot/) {
    my $success = sm_kokoonpanot();
    if (!$success) { sm_kokoonpanot_kaikki(); }
}
