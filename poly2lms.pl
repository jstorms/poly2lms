# poly2lms.pl <input-labelfile> <output-lmsfile>
# Written by John Storms 
# listentoourlights@gmail.com
# http://listentoourlights.com
# 
# This is known crappy code. Very limited testing done.
#
# This script takes a file with a single (*1*) Audacity label/timing track and outputs
# a Light-O-Rama LMS file to STDOUT where each midi note is represented as a Light-O-Rama channel.
# This script does not put in the name of the audio (mp3) file. Once created open the newly created
# LOR .lms file with the Light-O-Rama Sequence editor and add the media file. Select "Edit" from
# the sequence editor menu bar then select "Media" and select the audio file.
#
# This script runs from a command prompt. To get a command prompt in MS-Windows press the Windows key 
# on your keyboard, then type "cmd" and press enter.
#
# <input-filename> - contains the file with the one (*1*) audacity track with Polyphonic transcription
# timing/label info. The script will map the midi numerical value to actual midi notes.
#
# [<output_lms_file>] - output file containing the XML sequence for Light-O-Rama sequence editor.
#                     Be sure to give it a .lms extension.
#                     If no output file is specified then the file is dumped to STDOUT.
#
# Example usage fomr MS-Windows cmd prompt:
# poly2lms.pl AUD-PolyphonicTranscription-for-yourFavSong.txt yourFavSong.lms
#
# Software You'll Need: (Assuming MS-Windows ENV)
# * PERL script interpreter
#   http://www.activestate.com/activeperl (many other options too)
#   You can verify this is intalled properly by opening a command prompt ("cmd) and typing...
#
#    perl -v
#
#   If you've installed it right you should see the perl version number that has been installed
#
# * LOR S3 (I'm currently using S4 pro)
#   http://www1.lightorama.com/sequencing-software-download/
# * Audacity (I've been using v2.3.3)
#   http://audacity.sourceforge.net/
# * Queen Mary Vamp plugins for Audacity - although I think Polyphonic Transcription
#   may be included by default.
#   http://nutcracker123.com/nutcracker/releases/Vamp_Plugin.exe
#
# Potential improvements:
# * Use an XML library. Apologies in advance, there are better ways to manipulate XML
# * Modify to do multiple timing grids from one input file.
# * Modify to modularize label mapping so other mappings other than midi can be done
# * Use pointers to the arrays for better memory usage.
# * Better command line argument handling
# * Replace color constant with some color options
# * Figure out better way to get total number of centiseconds in a song

my($filename) = $ARGV[0];     # Audacity label/timing file
my($outfile) = $ARGV[1];      # LMS outputfile
my($usage) = "poly2lms.pl \<polyphonic_label_file.txt\> \[<lms_outfile_filename.lms\>]\n\<polyphonic_label_file.txt\> -- Polyphonic transcription label file exported from Audacity\n\[<lms_outfile_filename.lms\>] - Optional Light-O-Rama XML file to be loaded into sequence editor. Give .LMS extension\nIf no output file is specified then the LMS file is dumped to STDOUT.\nGenerated LMS file will not have an audio file specified, this needs to be set from the sequence editor.";

my($savedindex) = 0;
my($splitbylabel) = 1;

# Did user specify a filename?
if($filename eq "") {	die("ERROR: No label filename provided.\n$usage\n"); } 

if(-e $filename){
	# Convert timings/labels into LOR XML snippets
	my(@output) = create_LOR_XML_snips($filename,$savedindex,$splitbylabel);

	if( $outfile eq "") {
		# print output that can be copy/pasted into LOR .lms files
		foreach my $i (@output) { print $i; }
	} else {
		open(WRITE,">".$outfile);
		print WRITE @output;
		close(WRITE);
		print "Polyphonic Transcription labels [$filename] transformed into Light-O-Rama LMS file [$outfile]. Be sure to specify the audio file after opening.\n";
	} #endif
}else{
	die("ERROR: File $filename does not exist.\n$usage\n");
} #endif filecheck
 

# INPUTS
# filename = tab deliminated text file containing "1" audacity label/timing information
#            <starting seconds>\t<ending seconds>\t<label>
# savedindex = Used to number the timing grid
# splitbylabel = if 1, this will create channels for each label. Labels are assumed
#                to be integers representing MIDI notes.
# OUTPUTS
# Array of XML snippets
sub create_LOR_XML_snips {
	my($filename) = shift(@_);
	my($savedindex) = shift(@_);
	my($splitbylabel) = shift(@_);

	my($xml_lor_header) = create_LOR_header()."\n";
	my($xml_lor_seqheader) = create_LOR_seqheader()."\n";
	my($xml_lor_animation) = create_LOR_animation()."\n\<\/sequence\>\n";

	my($name); # Timing Grid name
	($name) = split(/\./,$filename);

	if( $savedindex eq "") { $savedindex = "0"; }
	if( $splitbylabel eq "") { $splitbylabel = "1"; }

	my($totcenti) = 0; # best shot at getting the total time

	##### Prep for Timing Grids
	my(@timing); # Holds XML timing grid
	my(%timing); # Used to avoid duplicating times
	# Start Timing Grid
	push(@timing,"\<timingGrids\>\n");
	push(@timing,"\<timingGrid saveID=\"".$savedindex."\" name=\"".$name."\" type=\"freeform\"\>\n");
	push(@timing,"\t\<timing centisecond=\"0\"\/\>\n");

	# Open Audacity label file and go through line by line
	open(READ,$filename);
	my($line);
	$line = <READ>;
	while($line ne "") {
		chop($line);
		my($start,$stop,$label); ($start,$stop,$label) = split(/\t/,$line);

		# convert seconds to centiseconds the way LOR likes it
		$start = second_to_whole_centisecond($start);
		$stop = second_to_whole_centisecond($stop);
		$label = int($label);

		#### Update Timing Grid
		if( $timing{$start} eq "") { # Making sure timing doesn't already exist
			$timing{$start} = 1; # Note that it exists now
			# Add timing data to XML timing grid
			push(@timing,"\t\<timing centisecond=\"".$start."\"\/\>\n");
		} #ENDIF
		if( $timing{$stop} eq "") { # Making sure timing doesn't already exist
			$timing{$stop} = 1; # Note that it exists now
			# Add timing data to XML timing grid
			push(@timing,"\t\<timing centisecond=\"".$stop."\"\/\>\n");
		} #ENDIF

		if($splitbylabel) {
			# CHANNEL DATA: Save for a 2nd pass (optimization opportunity here)
			push(@chdata,"$label,$start,$stop");
			# Watch for highest value stop time
			if( $stop > $totcenti) { $totcenti = $stop; }
		} #endif

		$line = <READ>;
	} #endwhile
	close(READ);

	# Finish off timing grid XML
	push(@timing,"\<\/timingGrid\>\n\<\/timingGrids\>\n");

	my(@channelsNtracks); # Holds channel and track XML elements
	my($chlen); #length of channel array
	if($splitbylabel) {
		($chlen,@channelsNtracks) = do_channels_and_tracks($totcenti,$savedindex,@chdata);
	} #endif

	my(@channelsXml); (@channelsXml) = @channelsNtracks[0..$chlen-1];
	my(@tracksXml); (@tracksXml) = @channelsNtracks[$chlen..$#channelsNtracks];


	#return($xml_lor_header,$xml_lor_seqheader,@channelsNtracks,@timing,$xml_lor_animation);
	return($xml_lor_header,$xml_lor_seqheader,@channelsXml,@timing,@tracksXml,$xml_lor_animation);
} # create_LOR_XML_snips


# @channelsNtracks = do_channels_and_tracks($totcenti,$savedindex,@chdata);
# This function creates the LOR XML blocks for Channels and Tracks
# It returns
# $chlen = Number of array entries used for channels
# @channels = Array containing channel XML
# @tracks = Array containing tracks XML
sub do_channels_and_tracks {
	my($totcenti) = shift(@_);
	my($savedindex) = shift(@_);
	my(@chdata) = @_;

	my($color) = 202; # Color to use for channels. OMG he used a constant

	# Sort channel data by channel number then start time.
	my(@channeldata) = sort(@chdata); 
	@chdata = (); # Free up some memory

	my(@ch); # Holds the Channel element
	my(@tracks); # Holds the Track element

	my($lastch) = 0; # Used to detect new channel
	my($count) = 0; # Used to increment savedIndex

	# Prep tracks and channels elements
	push(@tracks,"\<tracks\>\n\t\t\t\<track totalCentiseconds=\"".$totcenti."\" timingGrid=\"".$savedindex."\"\>\n\t\t\t\t\<channels\>\n");
	push(@ch,"\<channels\>\n");

	foreach my $i (@channeldata) {  ## midi,start time, stop time ##
		my($midi,$start,$stop); ($midi,$start,$stop) = split(/,/,$i);
		if( $midi ne $lastch ) { #### NEW CHANNEL DETECTED
			$lastch = $midi;
			my($chname) = getmidi($midi); # Map midi number to note name
			if( $count) { # Do this on every channel except on the first hit
				push(@ch,"\t\<\/channel>\n");
			} #endif

			# Add to channel XML
			push(@ch,"\t\<channel name=\"$chname\" color=\"".$color."\" centiseconds=\"$totcenti\" savedIndex=\"$count\"\>\n");

			# Add channel to track XML (how LOR knows what channels are in the track)
			push(@tracks,"\t\t\t\<channel savedIndex=\"".$count."\"\/\>\n");
			$count++; # Increment for savedIndex
		} #endif
		push(@ch,"\t\t\<effect type=\"intensity\" startCentisecond=\"".$start."\" endCentisecond=\"".$stop."\" startIntensity=\"100\" endIntensity=\"0\"/>\n");
	} #foreach

	# End Channel and Tracks elements
	push(@ch,"\t\<\/channel>\n");
	push(@ch,"\<\/channels>\n");

	push(@tracks,"\t\t\<\/channels\>\n\t\t\t\<loopLevels\/\>\n\t\t\t\<\/track\>\n\t\t\<\/tracks\>\n");

	#return("\#CHANNEL ELEMENT\n",@ch,"\#TRACKS ELEMENT\n",@tracks);

	my($chlen); $chlen = @ch;

	return($chlen,@ch,@tracks);
} # do_channels_and_tracks

# maps an integer to a midi note name
# pulled a table off the Internet and massaged it into a hash table.
# https://studiocode.dev/resources/midi-middle-c/
sub getmidi {
	my($note) = shift(@_);
	my(%midi);
	$midi{'0'}="C-1";
	$midi{'1'}="C#-1";
	$midi{'2'}="D-1";
	$midi{'3'}="D#-1";
	$midi{'4'}="E-1";
	$midi{'5'}="F-1";
	$midi{'6'}="F#-1";
	$midi{'7'}="G-1";
	$midi{'8'}="G#-1";
	$midi{'9'}="A-1";
	$midi{'10'}="A#-1";
	$midi{'11'}="B-1";
	$midi{'12'}="C0";
	$midi{'13'}="C0#";
	$midi{'14'}="D0";
	$midi{'15'}="D#0-Eb0";
	$midi{'16'}="E0";
	$midi{'17'}="F0";
	$midi{'18'}="F#0-Gb0";
	$midi{'19'}="G0";
	$midi{'20'}="G#0-Ab0";
	# https://www.inspiredacoustics.com/en/MIDI_note_numbers_and_center_frequencies
	$midi{'21'}="A0";
	$midi{'22'}="A#0-Bb0";
	$midi{'23'}="B0";
	$midi{'24'}="C1";
	$midi{'25'}="C#1-Db1";
	$midi{'26'}="D1";
	$midi{'27'}="D#1-Eb1";
	$midi{'28'}="E1";
	$midi{'29'}="F1";
	$midi{'30'}="F1#-Gb1";
	$midi{'31'}="Low_G1";
	$midi{'32'}="Low_G#1-Ab1";
	$midi{'33'}="Low_A1";
	$midi{'34'}="Low_A#1-Bb1";
	$midi{'35'}="Low_B1";
	$midi{'36'}="Low_C2";
	$midi{'37'}="Low_C#2-Db2";
	$midi{'38'}="Low_D2";
	$midi{'39'}="Low_D#2-Eb2";
	$midi{'40'}="Low_E2";
	$midi{'41'}="Low_F2";
	$midi{'42'}="Low_F#2-Gb2";
	$midi{'43'}="Bass_G2";
	$midi{'44'}="Bass_G#2-Ab2";
	$midi{'45'}="Bass_A2";
	$midi{'46'}="Bass_A#2-Bb2";
	$midi{'47'}="Bass_B2";
	$midi{'48'}="Bass_C3";
	$midi{'49'}="Bass_C#3-Db3";
	$midi{'50'}="Bass_D3";
	$midi{'51'}="Bass_D#3-Eb3";
	$midi{'52'}="Bass_E3";
	$midi{'53'}="Bass_F3";
	$midi{'54'}="Bass_F#3-Gb3";
	$midi{'55'}="Middle_G3";
	$midi{'56'}="Middle_G#3-Ab3";
	$midi{'57'}="Middle_A3";
	$midi{'58'}="Middle_A#3-Bb3";
	$midi{'59'}="Middle_B3";
	$midi{'60'}="Middle_C4-middle-C";
	$midi{'61'}="Middle_C#4-Db4";
	$midi{'62'}="Middle_D4";
	$midi{'63'}="Middle_D#4-Eb4";
	$midi{'64'}="Middle_E4";
	$midi{'65'}="Middle_F4";
	$midi{'66'}="Treble_F#4-Gb4";
	$midi{'67'}="Treble_G4";
	$midi{'68'}="Treble_G#4-Ab4";
	$midi{'69'}="Treble_A4";
	$midi{'70'}="Treble_A#4-Bb4";
	$midi{'71'}="Treble_B4";
	$midi{'72'}="Treble_C5";
	$midi{'73'}="Treble_C#5-Db5";
	$midi{'74'}="Treble_D5";
	$midi{'75'}="Treble_D#5-Eb5";
	$midi{'76'}="Treble_E5";
	$midi{'77'}="Treble_F5";
	$midi{'78'}="High_F#5-Gb5";
	$midi{'79'}="High_G5";
	$midi{'80'}="High_G#5-Ab5";
	$midi{'81'}="High_A5";
	$midi{'82'}="High_A#5-Bb5";
	$midi{'83'}="High_B5";
	$midi{'84'}="High_C6";
	$midi{'85'}="High_C#6-Db6";
	$midi{'86'}="High_D6";
	$midi{'87'}="High_D#6-Eb6";
	$midi{'88'}="High_E6";
	$midi{'89'}="High_F6";
	$midi{'90'}="F#6-Gb6";
	$midi{'91'}="G6";
	$midi{'92'}="G#6-Ab6";
	$midi{'93'}="A6";
	$midi{'94'}="A#6-Bb6";
	$midi{'95'}="B6";
	$midi{'96'}="C7";
	$midi{'97'}="C#7-Db7";
	$midi{'98'}="D7";
	$midi{'99'}="D#7-Eb7";
	$midi{'100'}="E7";
	$midi{'101'}="F7";
	$midi{'102'}="F#7-Gb7";
	$midi{'103'}="G7";
	$midi{'104'}="G#7-Ab7";
	$midi{'105'}="A7";
	$midi{'106'}="A#7-Bb7";
	$midi{'107'}="B7";
	$midi{'108'}="C8";
	$midi{'109'}="C#8-Db8";
	$midi{'110'}="D8";
	$midi{'111'}="D#8-Eb8";
	$midi{'112'}="E8";
	$midi{'113'}="F8";
	$midi{'114'}="F#8-Gb8";
	$midi{'115'}="G8";
	$midi{'116'}="G#8-Ab8";
	$midi{'117'}="A8";
	$midi{'118'}="A#8-Bb8";
	$midi{'119'}="B8";
	$midi{'120'}="C9";
	$midi{'121'}="C#9-Db9";
	$midi{'122'}="D9";
	$midi{'123'}="D#9-Eb9";
	$midi{'124'}="E9";
	$midi{'125'}="F9";
	$midi{'126'}="F#9-Gb9";
	$midi{'127'}="G9";
	$midi{'128'}="G#9-Ab9";
	$midi{'129'}="A9";
	$midi{'130'}="A#9-Bb9";
	$midi{'131'}="B9";
	return($midi{$note});
} #getmidi

# Converts seconds to centisecond
sub second_to_whole_centisecond { return(round($_[0]*100,0)); }

# Just rounds a number to the nearest $places
# Grabbed this sub of Internet vs. including a perl lib or writing yet another round function
sub round { 
    my ($number, $places) = @_;
    my $sign = ($number < 0) ? '-' : '';
    my $abs = abs($number);

    if($places < 0) {
        $places *= -1;
        return $sign . substr($abs+("0." . "0" x $places . "5"), 0, $places+length(int($abs))+1);
    } else {
        my $p10 = 10**$places;
        return $sign . int($abs/$p10 + 0.5)*$p10;
    } #endif
} # round

# This function creates the XML header (first line) for a LOR file
# Optionally you can pass in a hash table with the following keys, but you never will
# version
# encoding
# standalone
# my($xml_lor_header) = create_LOR_header();
# Returns a string with the first line of XML
sub create_LOR_header {
	my(%in) = @_;
	my($xml);
	my(@keys); @keys = ("version","encoding","standalone");
	if( $in{'version'} eq "")  { $in{'version'} = "1.0"; }
	if( $in{'encoding'} eq "")  { $in{'encoding'} = "UTF-8"; }
	if( $in{'standalone'} eq "")  { $in{'standalone'} = "no"; }

	$xml = "<\?xml";
	foreach(@keys) {
		$xml .= " ".$_."=\"".$in{$_}."\"";
	} #end foreach
	$xml .= "\?\>";


	return($xml);
} # create_LOR_header

# This function creates the LOR XML header to the sequence section.
# my($xml_lor_seqheader) = create_LOR_seqheader();
# Returns an XML string
sub create_LOR_seqheader {
	my(%in) = @_;
	my($xml);
	my(@keys); @keys = ("saveFileVersion","author","createdAt","musicAlbum","musicArtist","musicFilename","musicTitle","videoUsage");

	if( $in{'videoUsage'} eq "")  { $in{'videoUsage'} = "2"; }
	if( $in{'saveFileVersion'} eq "")  { $in{'saveFileVersion'} = "14"; }
	if( $in{'author'} eq "")  { $in{'author'} = "Poly2LMS by John Storms"; }

	$xml = "<sequence";
	foreach(@keys) {
		$xml .= " ".$_."=\"".$in{$_}."\"";
	} #end foreach
	$xml .= "\>";

	return($xml);

} # create_LOR_seqheader

# This function creates the XML LOR snippet for a blank animation block
# my($xml_lor_animation) =create_LOR_animation();
# Returns a string containing the XML
sub create_LOR_animation {
	my(%in) = @_;
	my($xml);
	my(@keys); @keys = ("rows","columns","image");

	if( $in{'rows'} eq "")  { $in{'rows'} = "40"; }
	if( $in{'columns'} eq "")  { $in{'columns'} = "60"; }
	
	$xml = "<animation";
	foreach(@keys) {
		$xml .= " ".$_."=\"".$in{$_}."\"";
	} #end foreach
	$xml .= "\/\>";

	return($xml);
} # create_LOR_animation
