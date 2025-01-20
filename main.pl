use strict;
use warnings;
use utf8;
use LWP::UserAgent;
use JSON;
use Time::HiRes qw(usleep);
use Tk;
use Tk::JPEG;
use Tk::Font;
use File::Spec;
use File::Temp qw(tempfile);
binmode(STDOUT, ':utf8');

# Create a user agent object
my $ua = LWP::UserAgent->new;

# Get the input URL and output file path from the arguments supplied to the script
my $input_url = shift @ARGV or die "Usage: $0 <URL> <output_file>\n";
my $output_file = shift @ARGV or die "Usage: $0 <URL> <output_file>\n";
my $visual_mode = shift @ARGV // 0;
my $url = 'https://api.scryfall.com/cards/search?q=' . $input_url;

# Set the required headers
$ua->default_header('User-Agent' => 'MTGExampleApp/1.0');
$ua->default_header('Accept' => 'application/json;q=0.9,*/*;q=0.8');

# Insert a delay of 50-100 milliseconds as per scryfall API guidelines
usleep(50000 + int(rand(50000)));

# Make the GET request
my $response = $ua->get($url);

# Check for HTTP errors
if ($response->is_success) {
    # Decode the JSON response
    my $json = decode_json($response->decoded_content);
    
    # Save the response to the output file
    open(my $fh, '>', $output_file) or die "Could not open file '$output_file' $!";
    foreach my $card (@{$json->{data}}) {
        # Initialize the fields with default values
        my $name = $card->{name} // 'N/A';
        my $type_line = $card->{type_line} // 'N/A';
        my $oracle_text = $card->{oracle_text} // 'N/A';
        my $flavor_text = $card->{flavor_text} // 'N/A';
        my $stats = '';
        if (exists $card->{power} && exists $card->{toughness}) {
            $stats = $card->{power} . "/" . $card->{toughness};
        } elsif (exists $card->{loyalty}) {
            $stats = "Loyalty: " . $card->{loyalty};
        }

        # Write the extracted fields to the output file
        print $fh "Name: $name\n";
        print $fh "Type: $type_line\n";
        print $fh "Oracle Text: $oracle_text\n";
        if ($flavor_text ne 'N/A') {
            print $fh "Flavor Text: $flavor_text\n";
        }
        if ($stats) {
            print $fh "$stats\n";
        }
        print $fh "\n";
    }
    close $fh;

    # Check if visual mode is enabled and run GUI if true
    if ($visual_mode eq "true") {
        # Create the main window
        my $mw = MainWindow->new;
        $mw->title("MTG Card Viewer");
        
        # Define the BindMouseWheel method
        sub Tk::Widget::BindMouseWheel {
            my ($w) = @_;
            $w->bind('<MouseWheel>',
                [ sub { $_[0]->yview('scroll', -($_[1] / 120) * 3, 'units') },
                Tk::Ev("D") ]);

            if ($Tk::platform eq 'unix') {
                $w->bind('<4>',
                    sub { $_[0]->yview('scroll', -3, 'units')
                        unless $Tk::strictMotif;
                    });
                $w->bind('<5>',
                    sub { $_[0]->yview('scroll', 3, 'units')
                        unless $Tk::strictMotif;
                    });
            }
        }

        # Create a scrollable frame for the cards
        my $frame = $mw->Scrolled('Frame', -scrollbars => 'osoe', -width => 800, -height => 700)->pack(-expand => 1, -fill => 'both');

        # Bind mouse wheel events to the scrolling action
        $frame->BindMouseWheel();

        my $row = 0;
        foreach my $card (@{$json->{data}}) {
            if (exists $card->{image_uris}) {
                my $image_url = $card->{image_uris}->{normal};
                my ($fh_temp, $image_file) = tempfile('card_XXXX', SUFFIX => '.jpg', DIR => '/tmp');
                close $fh_temp;
                
                # Download the image
                print "Downloading image for '$card->{name}' from '$image_url'...\n"; 
                my $image_response = $ua->get($image_url, ':content_file' => $image_file);
                if ($image_response->is_success) {
                    # Verify the image file is valid
                    if (-s $image_file) {
                        eval {
                            my $image = $frame->Photo(-file => $image_file);
                            $frame->Label(-image => $image, -anchor => 'w')->grid(-row => $row, -column => 0, -pady => 5, -sticky => 'w');
                        };
                        if ($@) {
                            warn "Could not load image file '$image_file': $@";
                        }
                    } else {
                        warn "Image file '$image_file' is empty or invalid.";
                    }
                } else {
                    warn "Failed to download image from '$image_url': " . $image_response->status_line;
                }
            }

            # Extract additional fields
            my $name = $card->{name} // 'N/A';
            my $type_line = $card->{type_line} // 'N/A';
            my $oracle_text = $card->{oracle_text} // 'N/A';
            my $flavor_text = $card->{flavor_text} // 'N/A';
            my $stats = '';
            if (exists $card->{power} && exists $card->{toughness}) {
                $stats =  $card->{power} . "/" . $card->{toughness};
            } elsif (exists $card->{loyalty}) {
                $stats = "Loyalty: " . $card->{loyalty};
            }

            # Create a Text widget to display the extracted fields with bold labels
            my $text_widget = $frame->Text(-width => 40, -height => 30, -wrap => 'word', -state => 'disabled', -yscrollcommand => ['set', $frame->Subwidget('yscrollbar')])->grid(-row => $row, -column => 1, -pady => 5, -sticky => 'w');
            $text_widget->tagConfigure('bold', -font => 'Helvetica 10 bold');

            # Insert the text with bold labels
            $text_widget->configure(-state => 'normal');
            $text_widget->insert('end', "Name: ", 'bold');
            $text_widget->insert('end', "$name\n\n", 'normal');
            $text_widget->insert('end', "Type: ", 'bold');
            $text_widget->insert('end', "$type_line\n\n", 'normal');
            $text_widget->insert('end', "Oracle Text: ", 'bold');
            $text_widget->insert('end', "$oracle_text\n\n", 'normal');
            if ($flavor_text ne 'N/A') {
                $text_widget->insert('end', "Flavor Text: ", 'bold');
                $text_widget->insert('end', "$flavor_text\n\n", 'normal');
            }
            if ($stats) {
                $text_widget->insert('end', "Power/Toughness: ", 'bold');
                $text_widget->insert('end', "$stats\n\n", 'normal');
            }
            $text_widget->configure(-state => 'disabled');

            $row++;
        }
        MainLoop;
    } else {
        # Prompt the user to download images for all cards
        print "Do you want to download images for all cards? (yes/no): ";
        my $answer = <STDIN>;
        chomp $answer;
        if (lc($answer) eq 'yes' || lc($answer) eq 'y') {
            foreach my $card (@{$json->{data}}) {
            if (exists $card->{image_uris}) {
                my $image_url = $card->{image_uris}->{normal};
                my ($fh_temp, $image_file) = tempfile('card_XXXX', SUFFIX => '.jpg', DIR => '/tmp');
                close $fh_temp;

                # Download the image
                my $image_response = $ua->get($image_url, ':content_file' => $image_file);
                if ($image_response->is_success) {
                # Verify the image file is valid
                if (-s $image_file) {
                    print "Image for '$card->{name}' downloaded successfully to '$image_file'.\n";
                } else {
                    warn "Image file '$image_file' is empty or invalid.";
                }
                } else {
                warn "Failed to download image from '$image_url': " . $image_response->status_line;
                }
            }
            }
        } else {
            print "Image download aborted.\n";
        }
    }
} else {
    die "HTTP GET error: ", $response->status_line;
}