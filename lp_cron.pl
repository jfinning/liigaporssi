#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use HTML::Parser;
require LWP::UserAgent;
require "lp_settings.pm";

my $sub;

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
    my $data = fetch_page("http://liiga.fi/tilastot/2015-2016/runkosarja/joukkueet/");
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
            if ($sijoitus == 15) { last; }
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
    my @sm_joukkue = get_joukkue_list("sm_liiga");

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
	    s/-(\s+)/0$1/g;
	
	    my $line = $_;

	    if ($line =~ /^\s*(\D+)\s*$/ && $line !~ /Maalivahdit|Puolustajat|Hy.*kk.*t/) {
            if (length($1) > 6) {
                $name = $1;
            }
        }

        # Ala katkase taman kohdalla, edella olevan pelaajan nimi pienella kirjaimella meinaa katkasta
        if ($name =~ /Voracek Jakub/) {
        } elsif (($name lt $previous_name || defined $katkaisu_pelaajat{$name}) && $name ne $previous_name) {
            $final_player_list = "${final_player_list}$sm_joukkue[$team_count]\n";
            $team_count++;
	        if ($team_count > $#sm_joukkue) { $team_count = 0; }
        }

	    $line = modify_char($line);
        $line = replace_position($line);

	    if ($line =~ /^\s*\D+\s+\D+\s*$/ || (length($line) < 7 && $line !~ /Arvo/) || $line =~ /Maalivahti|Puolustaja|Hy.*kk.*/) {
    	    $final_player_list .= "$line ";
    	} else {
    	    $final_player_list .= "$line\n";
    	}
	    $previous_name = $name;
    }
    
    #Tsekataan, etta joka joukkueelta saadaan pelaajalista. Ollut joskus ongelmia
    if ($final_player_list =~ /Ei hakutuloksia/) { exit; }

    open FILE, ">2015/player_list_period1.txt" or die "Cant open 2015/player_list_period1.txt\n"; 
    
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

    my @sm_joukkue = get_joukkue_list("sm_liiga");
    foreach my $joukkue (@sm_joukkue) {
        $final_player_list .= "$joukkue\n";
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
            s/-(\s+)/0$1/g;
            $_ = replace_position($_);

            if (/^\s*\D+\s+\D+\s*$/ || (length($_) < 7 && $_ !~ /Arvo/) || /Maalivahti|Puolustaja|Hy.*kk.*/) {
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
    
    open FILE, ">2015/player_list_period1.txt" or die "Cant open 2015/player_list_period1.txt\n"; 
    
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
    my $address = "";

    my @nhl_joukkue = get_joukkue_list("sm_liiga");
    foreach my $joukkue (@nhl_joukkue) {
        $final_player_list .= "$joukkue\n";

        $address = "https://www.hockeygm.fi/team/search-players?player_position=all&player_team=${joukkue}&player_value=all&type=player_search";
        $address =~ s/\s+/%20/g;
        
        my $data = fetch_page($address);

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
            s/-(\s+)/0$1/g;
            $_ = replace_position($_);

            if (/^\s*\D+\s+\D+\s*$/ || (length($_) < 7 && $_ !~ /Arvo/) || /Maalivahti|Puolustaja|Hy.*kk.*/) {
                $final_player_list .= "$_ ";
            } else {
                $final_player_list .= "$_\n";
            }

            #Tsekataan, etta joka joukkueelta saadaan pelaajalista. Ollut joskus ongelmia
            if (/Ei hakutuloksia/) {
                print "$address\n";
                print "Ei hakutuloksia: $joukkue\n";
                return 0;
            }
        }
    }
    
    open FILE, ">2015/player_list_period1_nhl.txt" or die "Cant open 2015/player_list_period1_nhl.txt\n"; 
    
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
            my $year_nro = 2015;
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

sub sm_ottelu_id {
    my $year_nro = 2015;
    my $new_game_list;
    my $day_count = 0;
    my $gameday;
    my $file = "games_sm_liiga.txt";

    my $data = fetch_page("http://www.liiga.fi/ottelut/2015-2016/runkosarja/");
    $data = modify_char($data);
    my @data = split(/\n/, $data);

    my @games = `cat $file`;
    foreach my $game (@games) {
        $game =~ s/\s*$//;

        if ($game =~ /(\d\d)\.(\d\d)\./) {
            $gameday = "${year_nro}${2}$1";
            $day_count++;
        }
	
        if ($day_count == 1) {
            if ($game =~ /^\s*(.*?)\s*-\s*(.*?)\s*$/) {
                my $home = $1;
                my $away = $2;
                my $day_found = 0;
                foreach (@data) {
                    if (/data-time\s*=\s*\"$gameday/) {
                        $day_found = 1;
                    }
                    
                    if ($day_found) {
                        if (/\/(\d+)\/\">$home\s*-\s*$away/) {
                            my $id = $1;
                            $game =~ s/$away/$away, $id/;
                            last;
                        }
                    }
                }
            }
            $game = "$game";
        }
	
        $new_game_list .= "$game\n";
    }
    
    open FILE, ">$file" or die "Cant open $file\n"; 
    print FILE "$new_game_list";
    close (FILE);
}

sub fetch_kokoonpanot() {

}

sub replace_position($) {
    my $position = shift;
    
    if ($position =~ /Maalivahdit/) {
        $position = "Maalivahti";
    } elsif ($position =~ /Puolustajat/) {
        $position = "Puolustaja";
    } elsif ($position =~ /Hyokkaajat/) {
        $position = "Hyokkaaja";
    }

    return $position
}

if ($sub =~ /sm_ottelulista/) { ottelulista("games_sm_liiga.txt"); }
elsif ($sub =~ /nhl_ottelulista/) { ottelulista("games_nhl.txt"); }
elsif ($sub =~ /fetch_kokoonpanot/) { fetch_kokoonpanot(); }
elsif ($sub =~ /sm_sarjataulukko/) { sm_sarjataulukko(); }
elsif ($sub =~ /sm_ottelu_id/) { sm_ottelu_id(); }
elsif ($sub =~ /nhl_sarjataulukko/) { nhl_sarjataulukko(); }
elsif ($sub =~ /nhl_kokoonpanot/) { nhl_kokoonpanot(); }
elsif ($sub =~ /sm_kokoonpanot_kaikki/) { sm_kokoonpanot_kaikki(); }
elsif ($sub =~ /sm_kokoonpanot/) {
    my $success = sm_kokoonpanot();
    if (!$success) { sm_kokoonpanot_kaikki(); }
}
