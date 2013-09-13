#!/nokia/apps/tww/@sys/bin/perl -w

use strict;
use Getopt::Long;

my $file;
my $liiga;
my $file_content = "";

GetOptions (
    "file=s"  => \$file,
    "liiga=s" => \$liiga,
    );

if (!defined $file) {
    print "-f [file] is missing!\n";
    exit;
}

if (!defined $liiga) {
    print "-l [sm / nhl] liiga is missing!\n";
    exit;
}

my @joukkue;
if ($liiga =~ /sm/) {
    #@joukkue = ("JYP", "Pelicans");
    @joukkue = ("Blues", "HIFK", "HPK", "Ilves", "Jokerit", "JYP", "KalPa", "Karpat", "Lukko", "Pelicans", "SaiPa", "Tappara", "TPS", "Assat");
} elsif ($liiga =~ /nhl/) {
    #@joukkue = ("Anaheim", "Boston", "Buffalo", "Calgary", "Carolina", "Chicago", "Colorado", "Columbus", "Dallas", "Detroit", "Edmonton", "Florida", "Los Angeles", "Minnesota", "Montreal", "Nashville", "New Jersey", "NY Islanders", "NY Rangers", "Ottawa", "Philadelphia", "Phoenix", "Pittsburgh", "San Jose", "St. Louis", "Tampa Bay", "Toronto", "Vancouver", "Washington", "Winnipeg");
    @joukkue = ("Los Angeles", "Nashville", "New Jersey", "NY Rangers", "Philadelphia", "Phoenix", "St. Louis", "Washington");
}

my $team_count = 0;
my $previous_name = "Z";
my $name = "";

# Listaa tahan nimet, jos aakkosjarjestys ei matsaa. Ts. seuraavan joukkueen ensimmainen pelaaja on aakkosissa toisen joukkueen viimeisen jalkeen
my @pelaajat = ();
my @sm_molket = ("Nielsen Simon");
push (@pelaajat, @sm_molket);
my @nhl_molket = ("Luongo Roberto", "LaBarbera Jason", "Giguere Jean-Sebastien", "Bobrovsky Sergei", "Holtby Braden");
push (@pelaajat, @nhl_molket);

my %katkaisu_pelaajat;
foreach (@pelaajat) {
    $katkaisu_pelaajat{$_} = 1;
}

open FILE, "$file" or die "Cant open $file\n"; 
while (<FILE>) {
    if (/^\s*$/) { next; }
    s/\s*$//;
    
    s/(\d\d\d \d\d\d).*$/$1/;

    my $line = $_;
    
    if ($line =~ /^\s*(\D+)\s*$/) {
        $name = $1;
    }
    
    # Ala katkase taman kohdalla, edella olevan pelaajan nimi pienella kirjaimella meinaa katkasta
    if ($name =~ /Voracek Jakub/) {
    } elsif (($name lt $previous_name || defined $katkaisu_pelaajat{$name}) && $name ne $previous_name) {
        $file_content = "${file_content}$joukkue[$team_count]\n";
        $team_count++;
	if ($team_count > $#joukkue) { $team_count = 0; }
    }
    
    $line =~ s/Ä/A/g;
    $line =~ s/ä/a/g;
    $line =~ s/Ö/O/g;
    $line =~ s/ö/o/g;
    $line =~ s/Å/A/g;
    $line =~ s/å/a/g;
    $line =~ s/ü/u/g;
    #$line =~ s/(\s+)-/${1}0/g;
    $line =~ s/-(\s+)/0$1/g;

    if ($line =~ /^\s*\D+\s+\D+\s*$/) {
        $file_content = "${file_content}$line";
    } else {
        $file_content = "${file_content}$line\n";
    }
    
    $previous_name = $name;
}
close (FILE);

open FILE, ">$file" or die "Cant open $file\n"; 
    print FILE "$file_content";
close (FILE);
