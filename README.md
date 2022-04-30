# poly2lms
Converts Audacity label file with Polyphonic transcription to a Light-O-Rama LMS file where every channel represents a different midi note.

This is known crappy code. Very limited testing done.

This script takes a file with a single (*1*) Audacity label/timing track and outputs a Light-O-Rama LMS file to STDOUT where each midi note is represented as a Light-O-Rama channel. This script does not put in the name of the audio (mp3) file. Once created open the newly created LOR .lms file with the Light-O-Rama Sequence editor and add the media file. Select "Edit" from the sequence editor menu bar then select "Media" and select the audio file.

This script runs from a command prompt. To get a command prompt in MS-Windows press the Windows key on your keyboard, then type "cmd" and press enter.
<input-filename> - contains the file with the one (*1*) audacity track with Polyphonic transcription timing/label info. The script will map the midi numerical value to actual midi notes.

Example usage fomr MS-Windows cmd prompt:
poly2lms.pl AUD-PolyphonicTranscription-for-yourFavSong.txt > yourFavSong.lms

Software You'll Need: (Assuming MS-Windows ENV)
* PERL script interpreter
  http://www.activestate.com/activeperl (many other options too)
  You can verify this is intalled properly by opening a command prompt ("cmd) and typing...

   perl -v

  If you've installed it right you should see the perl version number that has been installed

* LOR S3 (I'm currently using S4 pro)
  http://www1.lightorama.com/sequencing-software-download/
* Audacity (I've been using v2.3.3)
  http://audacity.sourceforge.net/
* Queen Mary Vamp plugins for Audacity - although I think Polyphonic Transcription
  may be included by default.
  http://nutcracker123.com/nutcracker/releases/Vamp_Plugin.exe
