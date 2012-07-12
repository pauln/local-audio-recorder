package com.geleri.media{

import com.adobe.audio.format.WAVWriter;
import fr.kikko.lab.ShineMP3Encoder;

import com.marstonstudio.UploadPostHelper;
import com.dynamicflash.util.Base64;

import flash.display.Sprite;
import flash.events.IOErrorEvent;
import flash.events.SampleDataEvent;
import flash.events.SecurityErrorEvent;
import flash.events.Event;
import flash.media.Microphone;
import flash.media.Sound;
import flash.media.SoundChannel;
import flash.system.*;
import flash.utils.ByteArray;
import flash.display.MovieClip;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.URLRequestMethod;
import flash.net.URLRequestHeader;
import flash.net.URLVariables;
import flash.net.navigateToURL;
import flash.events.IEventDispatcher;
import flash.events.ProgressEvent;
import flash.events.HTTPStatusEvent;
import flash.events.ErrorEvent;
import fl.controls.ProgressBar;
import flash.text.TextField;
import flash.external.ExternalInterface;


public class Record extends Sprite{
	public var microphone:Microphone;
	[Bindable]public var isRecording:Boolean = false;
	[Bindable]public var isPlaying:Boolean = false;
	[Bindable]public var isSoundData:Boolean = false;
	[Bindable]public var soundData:ByteArray;
	[Bindable]public var mp3Data:ByteArray;
	public var sound:Sound;
	public var channel:SoundChannel;
	
	private var _postUrl:String;
	private var _jsCallback:String = "";
	private var _httpParams:Object = new Object();
	private var _fieldName:String = "newfile";
	private var _filename:String;
	private var _soundCompleteHandler:Function;
	private var _progressBar:ProgressBar;
	private var _mp3Encoder:ShineMP3Encoder;
	private var _mp3Ready:Function;
	private var _filenameRegex:RegExp = /[?\/\\]/g;
	
	public function Record(extraSoundCompleteHandler:Function=null)
	{
		init();
		_soundCompleteHandler = extraSoundCompleteHandler;
	}
	public function init():void
	{
		microphone = Microphone.getMicrophone();
		if(microphone.muted) {
			Security.showSettings("privacy");
		}
	}
	public function setPostUrl(addr:String):void
	{
		_postUrl = addr;
	}
	public function setCallback(jsFunc:String):void
	{
		_jsCallback = jsFunc;
	}
	public function setFieldName(fieldName:String):void
	{
		_fieldName = fieldName;
	}
	public function setHttpParam(key:String, val:String):void
	{
		_httpParams[key] = val;
	}
	public function startRecording():void
	{
		isRecording = true;
		microphone.setSilenceLevel(0);
		// Need to force NellyMoser to be able to set rate
		// speex will set rate=16 and cause playback to be super-fast
		microphone.codec = "Nellymoser";
		microphone.rate = 44;
		microphone.gain = 100;
		soundData = new ByteArray();
		trace("Recording");
		microphone.addEventListener(SampleDataEvent.SAMPLE_DATA, onSampleDataReceived);
		isSoundData=true;
	}
	
	public function stopRecording():void
	{
		isRecording = false;
		trace("Stopped recording");
		microphone.removeEventListener(SampleDataEvent.SAMPLE_DATA, onSampleDataReceived);
	}
	
	private function onSampleDataReceived(event:SampleDataEvent):void
	{
		soundData.writeBytes(event.data);
	}
	
	public function soundCompleteHandler(event:Event):void
	{
		isPlaying = false;
		if(_soundCompleteHandler != null) {
			_soundCompleteHandler();
		}
	}
	
	public function startPlaying():void
	{
		isPlaying = true
		soundData.position = 0;
		sound = new Sound();
		sound.addEventListener(SampleDataEvent.SAMPLE_DATA, sound_sampleDataHandler);
		channel = sound.play();
		channel.addEventListener(Event.SOUND_COMPLETE, soundCompleteHandler);
	}
	
	public function sound_sampleDataHandler(event:SampleDataEvent):void
	{
		if (!soundData.bytesAvailable > 0)
		{
			return;
		}
		
		for (var i:int = 0; i < 8192; i++)
		{
			var sample:Number = 0;
			
			if (soundData.bytesAvailable > 0)
			{
				sample = soundData.readFloat();
			}
			event.data.writeFloat(sample); 
			event.data.writeFloat(sample);  
		}
		
	}
	
	public function stopPlaying():void
	{
		channel.stop();
		isPlaying = false;
	}
	
	public function toggleRecording():void
	{
		if (isRecording)
		{
			isRecording = false;
			stopRecording();
		}
		else
		{
			isRecording = true;
			startRecording();
		}
	}
	
	
	public function stop():void
	{
		if (isRecording)
		{
			stopRecording();
		}
		else if (isPlaying)
		{
			stopPlaying();
		}
	}
	public function clear():void
	{
		isSoundData=false;
		soundData = new ByteArray();
	}
	
	// Convert sound to MP3 (via WAV)
	public function convertToMp3(filename:String, progressBar:ProgressBar, mp3Ready:Function):void
	{
		_progressBar = progressBar;
		_mp3Ready = mp3Ready;
		_filename = filename.replace(_filenameRegex,"_"); // Remove slashes etc
		
		// Convert ByteArray to WAV file
		var formattedSound:ByteArray = new ByteArray();
		var wavWriter:WAVWriter = new WAVWriter();
		soundData.position = 0;  // rewind to the beginning of the sample
		wavWriter.numOfChannels = 1; // set the inital properties of the Wave Writer
		wavWriter.sampleBitRate = 16;
		wavWriter.samplingRate = 44100;
		wavWriter.processSamples(formattedSound, soundData, 44100, 1); // convert our ByteArray to a WAV file.
		
		// Convert WAV file to MP3
		formattedSound.position = 0;
		_mp3Encoder = new ShineMP3Encoder(formattedSound);
		_mp3Encoder.addEventListener(Event.COMPLETE, mp3EncodeComplete);
		_mp3Encoder.addEventListener(ProgressEvent.PROGRESS, mp3EncodeProgress);
		_mp3Encoder.addEventListener(ErrorEvent.ERROR, mp3EncodeError);
		_mp3Encoder.start();
	}

	private function mp3EncodeProgress(event : ProgressEvent) : void {
		trace(event.bytesLoaded);
		_progressBar.setProgress(event.bytesLoaded, event.bytesTotal);
	}

	private function mp3EncodeError(event : ErrorEvent) : void {
		trace("[ERROR] : ", event.text);
	}

	private function mp3EncodeComplete(event : Event) : void {
		mp3Data = _mp3Encoder.mp3Data;
		trace("done!");
		_mp3Ready();
	}
	public function httpPost() {
		// If defined, use JS callback instead of doing our own HTTP POST
		if(_postUrl=="form" && _jsCallback.length) {
			var encoded:String = Base64.encodeByteArray(mp3Data);
			ExternalInterface.call(_jsCallback, _filename+".mp3", encoded);
			return;
		}
		
		// POST the completed MP3 back to Moodle in the existing browser window
		/*var parameters:Object = new Object();
		parameters.sesskey = _sesskey;
		parameters.id = _cmid;
		parameters.save = "Upload this file";*/
		var urlRequest:URLRequest = new URLRequest();
		urlRequest.url = _postUrl;
		urlRequest.contentType = 'multipart/form-data; boundary=' + UploadPostHelper.getBoundary();
		urlRequest.method = URLRequestMethod.POST;
		urlRequest.data = UploadPostHelper.getPostData(_fieldName, _filename+".mp3", mp3Data, _httpParams);
		urlRequest.requestHeaders.push( new URLRequestHeader( 'Cache-Control', 'no-cache' ) );
		// Load in browser window
		navigateToURL(urlRequest, "_self");
	}
	
	// HTTP error catching etc
	private function configureListeners(dispatcher:IEventDispatcher):void {
		dispatcher.addEventListener(Event.COMPLETE, completeHandler);
		dispatcher.addEventListener(Event.OPEN, openHandler);
		dispatcher.addEventListener(ProgressEvent.PROGRESS, progressHandler);
		dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
		dispatcher.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
		dispatcher.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
	}

	private function completeHandler(event:Event):void {
		var loader:URLLoader = URLLoader(event.target);
		trace("completeHandler: " + loader.data);
	}

	private function openHandler(event:Event):void {
		trace("openHandler: " + event);
	}

	private function progressHandler(event:ProgressEvent):void {
		trace("progressHandler loaded:" + event.bytesLoaded + " total: " + event.bytesTotal);
	}

	private function securityErrorHandler(event:SecurityErrorEvent):void {
		trace("securityErrorHandler: " + event);
	}

	private function httpStatusHandler(event:HTTPStatusEvent):void {
		trace("httpStatusHandler: " + event);
	}

	private function ioErrorHandler(event:IOErrorEvent):void {
		trace("ioErrorHandler: " + event);
	}

}
}
