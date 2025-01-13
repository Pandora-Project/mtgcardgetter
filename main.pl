use LWP::UserAgent;
use JSON;
use Time::HiRes qw(usleep);
use strict;
use warnings;
use utf8;

binmode(STDOUT, ':utf8');

# Create a user agent object
my $ua = LWP::UserAgent->new;

# Get the input URL from the first argument supplied to the script
my $input_url = shift @ARGV or die "Usage: $0 <URL>\n";
my $url = 'https://api.scryfall.com/cards/search?q=' . $input_url;

# Set the required headers
$ua->default_header('User-Agent' => 'MTGCardGetter/1.0');
$ua->default_header('Accept' => 'application/json;q=0.9,*/*;q=0.8');

# Insert a delay of 50-100 milliseconds
usleep(50000 + int(rand(50000)));

# Make the GET request
my $response = $ua->get($url);

# Check for HTTP errors
if ($response->is_success) {
    # Decode the JSON response
    my $json = decode_json($response->decoded_content);
    
    foreach my $card (@{$json->{data}}) {
        print "Name: " . ($card->{name} // 'N/A') . "\n";
        print "Set: " . ($card->{set_name} // 'N/A') . "\n";
        print "Type: " . ($card->{type_line} // 'N/A') . "\n";
        print "Mana Cost: " . ($card->{mana_cost} // 'N/A') . "\n";
        print "Oracle Text: " . ($card->{oracle_text} // 'N/A') . "\n";
        if (exists $card->{image_uris}) {
            print "Image: " . ($card->{image_uris}->{normal} // 'N/A') . "\n";
        }
        print "\n";
    }
}
else {
    die "HTTP GET error: ", $response->status_line;
}