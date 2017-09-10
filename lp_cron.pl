#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use HTML::Parser;
use Fcntl ':flock';
require "modules/lp_settings.pm";
require "modules/lp_common_functions.pl";

my $sub = "";
my $test = 0;
my %return;

GetOptions (
    "sub=s"  => \$sub,
	"test"   => \$test
);

sub initialize_return_value() {
	my %return_value = (
		'fail' => 0,
		'message' => ""
	);

	return %return_value;
}

sub sm_sarjataulukko {
    my %return_value = initialize_return_value();
	my $data = fetch_page("http://liiga.fi/tilastot/2017-2018/runkosarja/joukkueet/");
    my $sijoitus = undef;
    my $column = 0;
    my ($joukkue, $ottelut, $pisteet);
    my $file = get_sarjataulukko_filename("sm_liiga");

    my $text;
    my $p = HTML::Parser->new(text_h => [ sub {$text .= shift}, 
				  'dtext']);
    $p->parse($data);
    my @text = split(/\n/, $text);

    if (!$test) {
		open FILE, ">$file" or die "Cannot open $file";
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

	return %return_value;
}

sub nhl_sarjataulukko {
    my %return_value = initialize_return_value();
    my $data = fetch_page("http://www.hockeygm.fi/nhl/sarjataulukko");
    my ($sijoitus, $joukkue, $ottelut, $pisteet);
    my $file = get_sarjataulukko_filename("nhl");

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
    
    if (!$test) {
		open FILE, ">$file" or die "Cannot open $file";
		@text = split(/\n/, $temp);
		foreach (@text) {
			if (!/^\d+\./) { next; }
			s/(\d\.\d\d).*?$/$1/;
			print FILE "$_\n";
		}
		close FILE;
	}
	
	return %return_value;
}

sub sm_kokoonpanot_kaikki {
    my %return_value = initialize_return_value();
	my $pelipaikka = "Maalivahdit";
    my $team_count = 0;
    my $previous_name = "Z";
    my $year = get_default_vuosi("sm_liiga");
	my $period = get_default_jakso("sm_liiga");
    if ($period =~ /\d+/) {
		$period =~ s/^.*?(\d+).*$/period$1/;
	} else {
		$period = "playoff"
	}
	my $file = "player_stats/$year/player_list_${period}.txt";
	my @sm_joukkue = get_joukkue_list("sm_liiga");
	my %name_count;

    # Listaa tahan nimet, jos aakkosjarjestys ei matsaa. Ts. seuraavan joukkueen ensimmainen pelaaja on aakkosissa toisen joukkueen viimeisen jalkeen
	# Joukkue vaihtuu ENNEN lisattya pelaajaa
    #my @pelaajat = ("Ruusu Markus");
	my @pelaajat = ();
    my %katkaisu_pelaajat;
    foreach (@pelaajat) {
        $katkaisu_pelaajat{$_} = 1;
    }

    my $final_player_list = "";

    my $data = fetch_page("http://www.liigaporssi.fi/team/search-players?player_position=all&player_team=all&player_value=all&type=player_search");
	my %player_id = set_player_ids($data);

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
        } elsif ($line =~ /Maalivahdit|Puolustajat|Hy.*kk.*t/) {
			if ($team_count != 0) {
				$return_value{fail} = 1;
				$return_value{'message'} = "Pelaajien aakkosjarjestys pielessa ($pelipaikka). Muokkaa lp_cron.pl filea!";
			}
			$pelipaikka = $line;
			$team_count = 0;
			$final_player_list = "${final_player_list}$sm_joukkue[$team_count]\n";
            $team_count++;
		} elsif (($name lt $previous_name || defined $katkaisu_pelaajat{$name}) && $name ne $previous_name && $final_player_list !~ /Arvo.*?$/) {
            $final_player_list = "${final_player_list}$sm_joukkue[$team_count]\n";
            $team_count++;
	        if ($team_count > $#sm_joukkue) { $team_count = 0; }
        }

		if ($line !~ /\d+/) {
			if ($line =~ /\w+\s+\w+/) {
				if (defined $player_id{$line}) {
					$name_count{$line}++;
					$line = "${$player_id{$line}}[$name_count{$line} - 1] $line";
				}
			}
			$line = modify_char($line);
			$line = replace_position($line);
		}

	    if ($line =~ /^\s*\d+\s*\D+\s+\D+\s*$/ || (length($line) < 7 && $line !~ /Arvo/) || $line =~ /Maalivahti|Puolustaja|Hy.*kk.*/) {
    	    $final_player_list .= "$line ";
    	} else {
    	    $final_player_list .= "$line\n";
    	}
	    $previous_name = $name;
    }

    #Tsekataan, etta joka joukkueelta saadaan pelaajalista. Ollut joskus ongelmia
    if ($final_player_list =~ /Ei hakutuloksia/) {
		$return_value{'fail'} = 1;
		$return_value{'message'} = "Ei hakutuloksia";
		return %return_value;
	}

    if (!$test) {
		open FILE, ">$file" or die "Cant open $file\n"; 
		my @player_list = split(/\n/, $final_player_list);
		foreach (@player_list) {
			print FILE "$_\n";
		}
		close (FILE);
	}

	return %return_value;
}

sub sm_kokoonpanot {
    my %return_value = initialize_return_value();
    my $final_player_list = "";
    my $year = get_default_vuosi("sm_liiga");
	my $period = get_default_jakso("sm_liiga");
    if ($period =~ /\d+/) {
		$period =~ s/^.*?(\d+).*$/period$1/;
	} else {
		$period = "playoff"
	}
	my $file = "player_stats/$year/player_list_${period}.txt";
    my @sm_joukkue = get_joukkue_list("sm_liiga");

    foreach my $joukkue (@sm_joukkue) {
        $final_player_list .= "$joukkue\n";
        my $data = fetch_page("http://www.liigaporssi.fi/team/search-players?player_position=all&player_team=${joukkue}&player_value=all&type=player_search");
		my %player_id = set_player_ids($data);
		my %name_count;

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

			if (!/\d+/) {
				if (/\w+\s+\w+/) {
					if (defined $player_id{$_}) {
						$name_count{$_}++;
						$_ = "${$player_id{$_}}[$name_count{$_} - 1] $_";
					}
				}
				$_ = modify_char($_);
				$_ = replace_position($_);
			}

            if (/^\s*\d+\s*\D+\s+\D+\s*$/ || (length($_) < 7 && $_ !~ /Arvo/) || /Maalivahti|Puolustaja|Hy.*kk.*/) {
                $final_player_list .= "$_ ";
            } else {
                $final_player_list .= "$_\n";
            }

            #Tsekataan, etta joka joukkueelta saadaan pelaajalista. Ollut joskus ongelmia
            if (/Ei hakutuloksia/) {
				$return_value{'fail'} = 1;
				$return_value{'message'} = "Ei hakutuloksia: $joukkue";
                return %return_value;
            }
        }
    }
    
    if (!$test) {
		open FILE, ">$file" or die "Cant open $file\n"; 
		my @player_list = split(/\n/, $final_player_list);
		foreach (@player_list) {
			print FILE "$_\n";
		}
		close (FILE);
	}

    return %return_value;
}

sub nhl_kokoonpanot {
    my %return_value = initialize_return_value();
    my $final_player_list = "";
    my $address = "";
    my $year = get_default_vuosi("nhl");
	my $period = get_default_jakso("nhl");
    if ($period =~ /\d+/) {
		$period =~ s/^.*?(\d+).*$/period$1/;
	} else {
		$period = "playoff"
	}
	my $file = "player_stats/$year/player_list_${period}_nhl.txt";
    my @nhl_joukkue = get_joukkue_list("nhl");
	my %name_count;

    foreach my $joukkue (@nhl_joukkue) {
        $final_player_list .= "$joukkue\n";

        $address = "https://www.hockeygm.fi/team/search-players?player_position=all&player_team=${joukkue}&player_value=all&type=player_search";
        $address =~ s/\s+/%20/g;
        
        my $data = fetch_page($address);
		my %player_id = set_player_ids($data);

        $data =~ s/player_value\">(.*?)\&euro;</player_value\"> $1 </g;
        $data =~ s/\">(.*?)</\"> $1 </g;
    
        my $text;
        my $p = HTML::Parser->new(text_h => [ sub {$text .= shift}, 
                                      'dtext']);
        $p->parse($data);
        my @text = split(/\n/, $text);
    
        foreach (@text) {
            if (/^\s*$/) { next; }
            s/\s*$//;
            s/^\s*//;
            s/-(\s+)/0$1/g;

			if (!/\d+/) {
				if (/\w+\s+\w+/) {
					if (defined $player_id{$_}) {
						$name_count{$_}++;
						$_ = "${$player_id{$_}}[$name_count{$_} - 1] $_";
					}
				}
				$_ = modify_char($_);
				$_ = replace_position($_);
			}

            if (/^\s*\d+\s*\D+\s+\D+\s*$/ || (length($_) < 7 && $_ !~ /Arvo/) || /Maalivahti|Puolustaja|Hy.*kk.*/) {
                $final_player_list .= "$_ ";
            } else {
                $final_player_list .= "$_\n";
            }

            #Tsekataan, etta joka joukkueelta saadaan pelaajalista. Ollut joskus ongelmia
            if (/Ei hakutuloksia/) {
				$return_value{'fail'} = 1;
				$return_value{'message'} = "Ei hakutuloksia: $joukkue";
                return %return_value;
            }
        }
    }
    
    if (!$test) {
		open FILE, ">$file" or die "Cant open $file\n"; 
		my @player_list = split(/\n/, $final_player_list);
		foreach (@player_list) {
			print FILE "$_\n";
		}
		close (FILE);
	}

    return %return_value;
}

sub sm_ottelu_id {
    my %return_value = initialize_return_value();
    my ($yearOffset, $month, $dayOfMonth) = get_date();
    my $new_game_list = "";
    my $day_count = 0;
    my $gameday;
    my $file = get_ottelulista_filename("sm_liiga");

	my $data = fetch_page("http://liiga.fi/ottelut/2017-2018/runkosarja/");
    #my $data = fetch_page("http://www.liiga.fi/ottelut/2017-2018/playoffs/");
    $data = modify_char($data);
    my @data = split(/\n/, $data);

	open my $handle, '<', $file;
    chomp(my @games = <$handle>);
    close $handle;
    foreach my $game (@games) {
        $game =~ s/\s*$//;

        if ($game =~ /(\d\d)\.(\d\d)\./) {
            $gameday = "${yearOffset}${2}$1";
            $day_count++;
        }
	
        if ($day_count == 1) {
            if ($game =~ /^\s*(.*?)\s*-\s*(.*?)\s*$/) {
				my $home = $1;
                my $away = $2;
                my $day_found = 0;
				my $home_found = 0;
				my $away_fuond = 0;
                foreach (@data) {
                    if (/data-time\s*=\s*\"$gameday/) {
                        $day_found = 1;
                    }
                    if ($day_found) {
                        if (/$home/) { $home_found = 1; }
                        if (/$away/) { $away_fuond = 1; }
						#if (/\/(\d+)\/\">$home\s*-\s*$away/) {
						if ($home_found && $away_fuond && /\/(\d+)\/kokoonpanot/) {
							my $id = $1;
                            $game =~ s/$away/$away, $id/;
                            last;
                        }
                    }
                }
				if (!$day_found) {
					$return_value{'fail'} = 1;
					$return_value{'message'} = "Ei loytynyt muokattavaa paivaa $gameday liigan sivulta";
				}
            }
            $game = "$game";
        }
        $new_game_list .= "$game\n";
    }

	if ($new_game_list =~ /^\s*$/) {
		$return_value{'fail'} = 1;
		$return_value{'message'} = "Uusi ottelulista on tyhja. Ei muokattu!";
	}

    if (!$test && !$return_value{'fail'} && $new_game_list !~ /^\s*$/) {
		open FILE, ">$file" or die "Cant open $file\n";
		flock(FILE, LOCK_EX) or die "Could not lock '$file' - $!";
		print FILE "$new_game_list";
		close (FILE);
	}

	return %return_value;
}

sub ottelulista($) {
	my $liiga = shift;
    my %return_value = initialize_return_value();
    my $file = get_ottelulista_filename($liiga);
	my $link = get_ottelulista_link($liiga);
	my $data = fetch_page($link);
    $data = modify_char($data);
	$data =~ s/^.*?(<table.*?table>).*?$/$1/s;
	my $text;
    my $p = HTML::Parser->new(text_h => [ sub {$text .= shift}, 
				  'dtext']);
    $p->parse($data);
	if ($text =~ /\d+-\d+/) {
		$text =~ s/^.+\)//s;
	}
	$text =~ s/(\w+)\s*-\s*(\w+)/$1 - $2/g;
    my @text = split(/\n/, $text);
	
    open FILE, ">$file" or die "Cant open $file\n";
	foreach (@text) {
		if (!/^\s*$/) {
			s/\s*$//;
			s/^\s*//;
			print FILE "$_\n";
		}
	}
	close (FILE);

	return %return_value;
}

sub get_date {
    my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
    $yearOffset += 1900;
    $month++;
    if ($month < 10) { $month = "0$month"; }
    if ($dayOfMonth < 10) { $dayOfMonth = "0$dayOfMonth"; }

    return ($yearOffset, $month, $dayOfMonth);
}

sub set_player_ids($) {
	my $data = shift;
	my %player_id;

	foreach my $line (split(/\n/, $data)) {
		if ($line =~ /player_card.*?(\d+).*?>(.*?)</) {
			push(@{$player_id{$2}}, $1);
		}
	}

	return %player_id;
}

sub replace_position($) {
    my $position = shift;
    
    if ($position =~ /Maalivahdit/) {
        $position = "ID Maalivahti";
    } elsif ($position =~ /Puolustajat/) {
        $position = "ID Puolustaja";
    } elsif ($position =~ /Hyokkaajat/) {
        $position = "ID Hyokkaaja";
    }

    return $position;
}

sub sm_ottelulista {
	ottelulista("sm_liiga"); 
}

sub nhl_ottelulista {
	ottelulista("nhl"); 
}

if ($sub !~ /^\s*$/) {
	%return = eval "$sub()";

	if ($return{'fail'}) {
		print "$sub FAILED:\n";
		print "    $return{'message'}\n";
	} else {
		print "$sub OK\n";
	}
}

1;