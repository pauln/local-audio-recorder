local-audio-recorder
====================

A local audio recorder (no streaming server required).  Currently requires Flash Player 10.1 or above.


####Features
* Records in MP3 or WAV format
* Sends recordings to your server via HTTP POST
  * POST URL is configurable - send recordings anywhere you need to
  * Field name is configurable to suit your server-side handler
  * Additional fields (with their values) can be specified and will be included
* Optionally passes the filename and file content to a JavaScript callback instead of performing a POST
* A default filename can be specified
* Force a specific filename if desired

####Live demo
There is a [basic demonstration](http://maxthrax.github.com/local-audio-recorder/demo/) of using the Local Audio Recorder with a JavaScript callback.
This demo requires a browser which supports JavaScript, the HTML5 audio element and Typed Arrays.