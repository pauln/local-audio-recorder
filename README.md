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
There is a [basic demonstration](http://pauln.github.io/local-audio-recorder/demo/) of using the Local Audio Recorder with a JavaScript callback.
This demo requires a browser which supports JavaScript, the HTML5 audio element and Typed Arrays.

####Options
The following are the standard options, specified as flashvars.
Any additional parameters passed as flashvars will be added to the POST request as extra fields, with names and values as per the flasvars.
* `gateway`: URL to send POST request to, or "form" to use a JavaScript callback.
* `return`: URL to send the user's browser to upon completion of upload.  Set to "reset" to reset the recorder to allow for another recording without reloading the page.
* `filefield`: Name of the field to upload the file under, if local-audio-recorder is handling the POST request for you.
* `callback`: JavaScript callback; takes two parameters: the file name and the file data.
* `filename`: Default file name.
* `forcename`: If this parameter is specified (with any value), the file name provided in the "filename" field will be enforced.
* `format`: Output format.  Set to "wav" to have local-audio-recorder produce a WAV file; otherwise it will default to MP3.
 
**Note that as of May 26 2014, the POST request to upload the file is handled internally** rather than loaded in the user's browser.  **Please specify a return URL instead** (see above), if you wish for the user to be taken somewhere after the recording has been uploaded.  This change is in order to support Flash Player 13, which has removed the ability to set a Content-type for a POST request handed off to the browser (via `navigateToUrl()`).
