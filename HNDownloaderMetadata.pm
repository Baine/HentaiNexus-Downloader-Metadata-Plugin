package LANraragi::Plugin::Metadata::HNDownloader;

use strict;
use warnings;

#Plugins can freely use all Perl packages already installed on the system
#Try however to restrain yourself to the ones already installed for LRR (see tools/cpanfile) to avoid extra installations by the end-user.
use Mojo::JSON qw(from_json);

#You can also use the LRR Internal API when fitting.
use LANraragi::Model::Plugins;
use LANraragi::Utils::Logging qw(get_plugin_logger);
use LANraragi::Utils::Archive qw(is_file_in_archive extract_file_from_archive);

# Copied by hand into the plugins folder
#Meta-information about your plugin.
sub plugin_info {

    return (
        #Standard metadata
        name        => "HentaiNexus Downloader metadata",
        type        => "metadata",
        namespace   => "HentaiNexusDownloaderpluginmetadata",
        author      => "Baine",
        version     => "0.1",
        description => "Collects metadata embedded into your archives by HentaiNexus Downloader json files.",
        icon =>
          "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAACXBIWXMAAAsTAAALEwEAmpwYAAAA\nB3RJTUUH4wYCFDYBnHlU6AAAAB1pVFh0Q29tbWVudAAAAAAAQ3JlYXRlZCB3aXRoIEdJTVBkLmUH\nAAAETUlEQVQ4y22UTWhTWRTHf/d9JHmNJLFpShMcKoRIqxXE4sKpjgthYLCLggU/wI1CUWRUxlmU\nWblw20WZMlJc1yKKKCjCdDdYuqgRiygq2mL8aJpmQot5uabv3XdnUftG0bu593AOv3M45/yvGBgY\n4OrVqwRBgG3bGIaBbduhDSClxPM8tNZMTEwwMTGB53lYloXWmkgkwqdPnygUCljZbJbW1lYqlQqG\nYYRBjuNw9+5dHj16RD6fJ51O09bWxt69e5mammJ5eZm1tTXi8Tiu6xKNRrlx4wZWNBqlXq8Tj8cx\nTRMhBJZlMT4+zuXLlxFCEIvFqFarBEFAKpXCcRzq9TrpdJparcbIyAiHDh1icXERyzAMhBB4nofv\n+5imiWmavHr1inQ6jeM4ZLNZDMMglUqxuLiIlBLXdfn48SNKKXp6eqhUKiQSCaxkMsna2hqe52Hb\nNsMdec3n8+Pn2+vpETt37qSlpYVyucz8/DzT09Ns3bqVYrEIgOM4RCIRrI1MiUQCz/P43vE8jxcv\nXqCUwvM8Zmdn2bJlC6lUitHRUdrb2zFNE9/3sd6/f4/jOLiuSzKZDCH1wV/EzMwM3d3dNN69o729\nnXK5jFKKPXv2sLS0RF9fHydOnMD3fZRSaK0xtNYEQYBpmtTr9RC4b98+LMsCwLZtHj9+TCwWI5/P\nI6Xk5MmTXLhwAaUUG3MA4M6dOzQaDd68eYOUkqHIZj0U2ay11mzfvp1du3YhhGBgYIDjx4/T3d1N\nvV4nCAKklCilcF2XZrOJlBIBcOnSJc6ePYsQgj9yBf1l//7OJcXPH1Y1wK/Ff8SfvT995R9d/SA8\nzyMaja5Xq7Xm1q1bLCwssLS09M1Atm3bFr67urq+8W8oRUqJlBJLCMHNmze5d+8e2Ww2DPyrsSxq\ntRqZTAattZibm6PZbHJFVoUQgtOxtAbwfR8A13WJxWIYANVqFd/36e/v/ypzIpEgCAKEEMzNzYXN\n34CN/FsSvu+jtSaTyeC67jrw4cOHdHZ2kslkQmCz2SQSiYT269evMU0zhF2RVaH1ejt932dlZYXh\n4eF14MLCArZtI6UMAb+1/qBPx9L6jNOmAY4dO/b/agBnnDb9e1un3vhQzp8/z/Xr19eBQgjevn3L\n1NTUd5WilKJQKGAYxje+lpYWrl27xuTk5PqKARSLRfr6+hgaGiKbzfLy5UvGx8dRSqGUwnEcDMNA\nKYUQIlRGNBplZmaGw4cPE4/HOXDgAMbs7Cy9vb1cvHiR+fl5Hjx4QC6XwzAMYrEYz549Y3p6mufP\nn4d6NU0Tx3GYnJzk6NGjNJtNduzYQUdHB+LL8mu1Gv39/WitGRsb4/79+3R1dbF7925yuVw4/Uaj\nwalTpzhy5AhjY2P4vs/BgwdJp9OYG7ByuUwmk6FUKgFw7tw5SqUSlUqFp0+fkkgk2LRpEysrKzx5\n8oTBwUG01ty+fZv9+/eTz+dZXV3lP31rAEu+yXjEAAAAAElFTkSuQmCC",
        parameters => []
    );

}

#Mandatory function to be implemented by your plugin
sub get_tags {

    shift;
    my $lrr_info = shift;    # Global info hash

    my $logger = get_plugin_logger();
    my $file   = $lrr_info->{file_path};

    my $path_in_archive = is_file_in_archive( $file, "info.json" );
    if ($path_in_archive) {

        #Extract info.json
        my $filepath = extract_file_from_archive( $file, $path_in_archive );

        #Open it
        my $stringjson = "";

        open( my $fh, '<:encoding(UTF-8)', $filepath )
          or return ( error => "Could not open $filepath!" );

        while ( my $row = <$fh> ) {
            chomp $row;
            $stringjson .= $row;
        }

        #Use Mojo::JSON to decode the string into a hash
        my $hashjson = from_json $stringjson;

        $logger->debug("Found and loaded the following JSON: $stringjson");

        #Parse it
        my $tags = tags_from_HentaiNexus_json($hashjson);

        #Delete it
        unlink $filepath;

        #Return tags
        $logger->info("Sending the following tags to LRR: $tags");
        return ( tags => $tags );

    } else {
            return ( error => "No HentaiNexus Downloader info.json file found in this archive!" );
        }
}

#tags_from_HentaiNexus_json(decodedjson)
#Goes through the JSON hash obtained from an info.json file and return the contained tags.
sub tags_from_HentaiNexus_json {

    my $hash   = $_[0];
    my $return = "";

    #HentaiNexus jsons are composed of a main manga_info object, containing fields for every metadata.
    #Those fields can contain either a single tag or an array of tags.

    my $tags = $hash;

    #Take every key in the manga_info hash, except for title which we're already processing

    my @filtered_keys = grep { $_ ne "tags" and $_ ne "title" } keys(%$tags);

    foreach my $namespace (@filtered_keys) {

        my $members = $tags->{$namespace};

        if ( ref($members) eq 'ARRAY' ) {

            foreach my $tag (@$members) {

                $return .= ", " unless $return eq "";
                $return .= $namespace . ":" . $tag unless $members eq "";

            }

        } else {

            $return .= ", " unless $return eq "";
            $return .= $namespace . ":" . $members unless $members eq "";

        }

    }

    my $tagsobj = $hash->{"tags"};

    if ( ref($tagsobj) eq 'HASH' ) {

        return $return . "," . tags_from_wRespect($hash);

    } else {

        return $return . "," . tags_from_noRespect($hash);

    }

}

sub tags_from_wRespect {

    my $hash   = $_[0];
    my $return = "";
    my $tags   = $hash->{"tags"};

    foreach my $namespace ( keys(%$tags) ) {

        my $members = $tags->{$namespace};
        foreach my $tag (@$members) {

            $return .= ", " unless $return eq "";
			$return .= $namespace . ":" . $tag;
        }
    }

    return $return;

}

sub tags_from_noRespect {

    my $hash   = $_[0];
    my $return = "";
    my $tags   = $hash;

    my @filtered_keys = grep { /^tags/ } keys(%$tags);

    foreach my $namespace (@filtered_keys) {

        my $members = $tags->{$namespace};

        if ( ref($members) eq 'ARRAY' ) {

            foreach my $tag (@$members) {

                $return .= ", " unless $return eq "";
				$return .= $namespace . ":" . $tag;
            }

        }

    }

    return $return;

}

1;