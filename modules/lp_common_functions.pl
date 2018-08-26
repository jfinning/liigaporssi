#!/usr/bin/perl -w

require LWP::UserAgent;

sub fetch_page($) {
    my $link = shift;
    
    my $ua = LWP::UserAgent->new;
    $ua->timeout(20);
    $ua->env_proxy;

    my $data = $ua->get($link);

    if ($data->is_success) {
        return $data->decoded_content;
    } else {
        die $data->status_line;
    }
}
