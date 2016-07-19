package axl.xdef.types.display
{
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.NetStreamPlayOptions;
	import flash.utils.setTimeout;
	
	import axl.utils.Counter;
	import axl.utils.U;
	import axl.xdef.XSupport;
	/** Simple Video On Demand class that applies minimal mechanic for right net-events respnses and
	 *  video display. Instantiated from <h3><code>&lt;vod/&gt;</code></h3>
	 * Class provides dynamic mechanic (takes care of setting up net connection, net stream, setting buffers),
	 * and turns it into easy API. Minimal setup requires to put <code>rtmp</code> property up and call <code>play()</code>.
	 * <br><br>There are few more playback options like AUTOPLAY, looping, pause(), restart(), volume etc. 
	 * There's also set of callbacks that can be connected to this instance and withdrawn at any time. Class
	 * provides detailed info about playback state in terms of timing (percentage time, percentage buffer, percentage 
	 * bytes).<br><br>All that together  makes building video player easier than it would appear. <br><br>
	 * At the moment despite property <code>useStageVideo</code> presence, there's no stage video support. */
	public class xVOD extends xSprite
	{
		public static const version:String = '0.91';
		private var tname:String = '[xVOD ' + version +']';
		private var xrtmp:String;
		private var xvideoMeta:Object;
		private var xloops:int=1;
		private var xpercentTime:Number=0;
		private var xpercentBuffer:Number=0;
		private var xpercentBytes:Number=0;
		private var xvideoAspectRatio:Number=0;
		private var xbufferMax:Number = 1;
		private var xheight:Number=0;
		private var xwidth:Number=0;
		private var xbufferPlayback:Number = 1;
		private var xvolume:Number = 0.1;

		private var xonFrame:Function; 
		private var infiniteLoop:Boolean = false;
		
		private var xnc:NetConnection;
		private var xvideo:Video;
		private var xns:NetStream;
		private var nso:NetStreamPlayOptions;
		
		private var EMPTY_BUFFER:Boolean=true;
		private var DESTROYED:Boolean=false;
		private var FIRST_FILL:Boolean=true;
		private var IS_PAUSED:Boolean=false;
		
		/** Determines if video is going to start playing ASAP or stays paused waiting
		 * for play command.  */
		public var AUTOPLAY:Boolean = true;
		/** Not supported yet */
		public var useStageVideo:Boolean=false;
		/** Determines if setting width / height should allow to squeeze video (false)
		 * or always maintain aspect ratio (true) @default true */
		public var keepAspectRatio:Boolean=true;
		/** Allows to define user actions on not covered cases in response to 
		 * event.info.code of NetStatusEvent. Currently covered cases:
		 * <ul><li>NetConnection<ul><li>Connect.Success</li><li>Connect.Rejected</li>
		 * <li>Connect.Closed</li><li>Call.failed</li></ul></li>
		 * <li>NetStream<ul><li>Play.StreamNotFound</li><li>Play.Failed</li><li>Play.Start</li>
		 * <li>Play.Stop</li><li>Buffer.Full</li><li>Buffer.Empty</li>* <li>Pause.Notify</li>
		 * <li>Unause.Notify</li></ul></li> </ul> */
		public var netStausEventFunctionMap:Object = {};
		/** Sets the initial number of seconds of video that has to be loaded before it's available to play. */
		public var bufferInitial:Number = 1;
		/** Determines if instance should be disposed once video is finished. Disposed instances can not 
		 * be re-used @default true*/
		public var destroyOnEnd:Boolean=true;
		/** Specifies number of miliseconds before re-connect if previous connection attempt failed and 
		 * <code>reconnectAttemptsNo > 0</code> @see #reconnectAttemptsNo*/
		public var reconnectGapMs:int = 2;
		/** If server has rejected connection request or internet connection is down, player can try to re-connect.
		 * This property defines how many times the reconnect attempt should be made before giving up (destroy)
		 * @see #reconnectGapMs @see #destroy() */
		public var reconnectAttemptsNo:int;
		/** Function or portion of uncompiled code to execute when video playback reaches an end, before 
		 * posible exit sequence. An argument for binCommand. * @see axl.xdef.types.xRoot#binCommand()*/
		public var onComplete:Object;
		/** Function or portion of uncompiled code to execute when an exit sequence occurs.
		 * This may happen for various reasons: video reaches an end, video has been removed from stage,
		 * <code>destroy</code> method has been called manually, security error on net connection occured, exceeded 
		 * amount of re-connections, NetConnection.Call.Failed, NetConnection.Connect.Closed, NetStream.Play.StreamNotFound,
		 * NetStream.Play.Failed.<br>An argument for binCommand. * @see axl.xdef.types.xRoot#binCommand()*/
		public var onExit:Object;
		/** Function or portion of uncompiled code to execute when video starts playing. Both initial and unpause states.
		 * An argument for binCommand. * @see axl.xdef.types.xRoot#binCommand()*/
		public var onPlayStart:Object;
		/** Function or portion of uncompiled code to execute when video buffer reaches it's maximum value (
		 * <code>bufferInitial</code>, then switched to <code>bufferPlayback</code>). Tracking execution of
		 * this callback allows to increase buffer and if hit again - interpretate as sign of
		 *  good bandwidth, hence potential juggle to better quality should be considered (if available).
		 * <br> An argument for binCommand. * @see axl.xdef.types.xRoot#binCommand()*/
		public var onBufferFull:Object;
		/** Function or portion of uncompiled code to execute when video buffer gets empty, typically bandwidth
		 * can't keep up, hence potential juggle to lower quality should be considered (if available). 
		 * This may also happen as a consequence of internet connection loss.
		 * <br> An argument for binCommand. * @see axl.xdef.types.xRoot#binCommand()*/
		public var onBufferEmpty:Object;
		/** Function or portion of uncompiled code to execute when video is paused. First execution may occur
		 * right after video is available for play but <code>AUTOPLAY = false</code> (video is paused then). 
		 * <br> An argument for binCommand. * @see axl.xdef.types.xRoot#binCommand()*/
		public var onPlayStop:Object;
		/** Function or portion of uncompiled code to execute when video meta data is first received. 
		 * Accessible via <code>videoMeta</code>
		 * <br> An argument for binCommand. * @see axl.xdef.types.xRoot#binCommand()*/
		public var onMeta:Object;
		private var xcounter:Counter;
		private var xtimePassed:String;
		private var xtimeRemaining:String;
		/** Format for requesting timeRemaing and timePassed. @see axl.utils.Counter#defaultFormat*/
		public var timeFormat:String;
		
		/** When duration of video is known, internal timer updates two properties:
		 * timePassed and timeRemaining accordong to timeFormat. Once this is done, 
		 * Function or portion of uncompiled hold by this field can be executed. 
		 * @see #timePassed @see #timeRemaining
		 * <br> An argument for binCommand. * @see axl.xdef.types.xRoot#binCommand()*/
		public var onTimerUpdate:Object;
	
		
		/** Simple Video On Demand class that applies minimal mechanic for right net-events respnses and
		 * video display. Instantiated from &lt;vod/&gt; 
		 * @param definition - xml definition
		 * @param xroot - reference to parent xRoot object
		 * @see axl.xdef.types.xVOD
		 * @see axl.xdef.interfaces.ixDef#def
		 * @see axl.xdef.interfaces.ixDef#xroot
		 * @see axl.xdef.XSupport#getReadyType2() */
		public function xVOD(definition:XML=null, xrootObj:xRoot=null)
		{
			super(definition, xrootObj);
			xcounter = new Counter();
			xcounter.autoStart = false;
			xcounter.interval = 1;
		}
		
		private function xOnTimerUpdate():void
		{
			if(!ns || !videoMeta || !videoMeta.hasOwnProperty('duration'))
				return;
			xcounter.timing = [0, int(videoMeta.duration)];
			xcounter.time = ns.time;
			xtimeRemaining = xcounter.tillNext(timeFormat,-1);
			xtimePassed =  xcounter.tillNext(timeFormat,-2);
			if(onTimerUpdate is String)
				xroot.binCommand(onTimerUpdate,this);
			if(onTimerUpdate is Function)
				onTimerUpdate(xtimeRemaining);
		}
		
		private function dealWithStage():void
		{
			if(xroot.stage)
				getStageVideos(xroot.stage);
			else
			{	
				xroot.addEventListener(Event.ADDED_TO_STAGE, function xrootObjOnStage(e:Event):void
				{
					xroot.removeEventListener(Event.ADDED_TO_STAGE, xrootObjOnStage);
					getStageVideos(xroot.stage);
				});
			}
		}		
		
		private function getStageVideos(stage:Stage):void
		{
			if(debug) U.log(tname + '[getStageVideos]', stage);
		}
	
		//------------------------------------------------------ END OF STAGE SECTION ------------------------------------------------------//
		//------------------------------------------------------ CONNECTION SECTION ------------------------------------------------------//
		private function build_netConnection():void
		{
			if(debug) U.log(tname +"[build_netConnection]");
			if(nc && nc.connected && (nc.uri == rtmp))
			{
				if(debug) U.log(tname + 'already connected');
				ON_CONNECTED();
			}
			else
			{
				destroyNC();
				DESTROYED = false;
				xnc = new NetConnection();
				nc.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
				nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
				nc.connect(null);
				if(debug) U.log(tname + rtmp);
			}
		}
		
		private function build_netStream():void
		{
			if(debug) U.log(tname+"build_netStream", ns);
			destroyNS();
			FIRST_FILL = true;
			xns = new NetStream(nc);
			ns.soundTransform = new SoundTransform(xvolume);
			ns.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			ns.videoReliable = false;
			ns.audioReliable = false;
			ns.client = {};
			ns.client.onMetaData = onMetaData;
			//ns.client.onCuePoint = onCuePoint;
			ns.client.onPlayStatus = onPlayStatus;
			ns.bufferTime = bufferInitial;
			ns.bufferTimeMax = bufferMax;
			nso = new NetStreamPlayOptions(); 
		}
		
		private function build_video():void
		{
			if(useStageVideo)
				dealWithStage();
			else
				buildClassicVideo();
		}
		
		private function buildClassicVideo():void
		{
			if(video == null)
			{
				xvideo = new Video();
				xvideo.smoothing = true;
				updateDimensions();
			}
			if(ns)
				video.attachNetStream(ns);
			if(!this.contains(video))
				this.addChild(video);
		}
		
		private function updateDimensions():void
		{
			if(xwidth > 0)
				width = this.xwidth;
			if(this.xheight > 0)
				height = this.xheight;
		}
		
		//------------------------------------------------------ END OF CONNECTION SECTION ------------------------------------------------------//
		//------------------------------------------------------ EVENT HANDLING SECTION ------------------------------------------------------//
		
		override protected function addedToStageHandler(e:Event):void
		{
			super.addedToStageHandler(e);
		}
		
		override protected function removeFromStageHandler(e:Event):void
		{
			super.removeFromStageHandler(e);
			EXIT_SEQUENCE();
		}
		/** Responds to enter frame function if <code>onFrame</code> is defined*/
		protected function onEnterFrameHandler(e:Event=null):void
		{
			if(nc == null || ns == null)
				return;
			onFrame();
		}
		/** Responds to various NetStatusEvent's. General logic distribution is spread against 7 main functions:
		 * <i>ON_CONNECTED, tryReconnect, EXIT_SEQUENCE, ON_BUFER_FULL, ON_BUFFER_EMPTY, ON_PLAY_START, ON_PAUSE</i>*/
		protected function netStatusHandler(event:NetStatusEvent):void
		{
			if(debug) U.log(tname +'+++++++++ netStatusHandler +++++++++', event.info.code);
			switch (event.info.code) 
			{
				//1
				case "NetConnection.Connect.Success":
					ON_CONNECTED();
					break;
				//2 + 3
				case "NetConnection.Connect.Failed":
				case "NetStream.Connect.Rejected":
					tryReconnect();
					break;
				//4
				case "NetConnection.Call.Failed":
					EXIT_SEQUENCE();
					break;
				//5
				case "NetConnection.Connect.Closed":
					//onNetworkFail ? onNetworkFail() : EXIT_SEQUENCE();
					EXIT_SEQUENCE();
					break;
				//6
				case "NetStream.Play.StreamNotFound":	
					EXIT_SEQUENCE();
					break;
				//7
				case "NetStream.Play.Failed":
					EXIT_SEQUENCE();
					break;
				//8
				case "NetStream.Play.Start":
					IS_PAUSED = false;
					ON_PLAY_START();
					break;
				//9
				case "NetStream.Play.Stop":
					//EXIT_SEQUENCE();
					IS_PAUSED = true;
					break;
				//10
				case "NetStream.Buffer.Full":
					ON_BUFFER_FULL();
					break;
				//11
				case "NetStream.Buffer.Empty":
					ON_BUFFER_EMPTY();
					break;
				//14
				case "NetStream.Pause.Notify":
					ON_PAUSE();
					break;
				case "NetStream.Unpause.Notify":
					ns.bufferTime = bufferPlayback;
					ON_PLAY_START();
					break;
				default:
					var f:Object = netStausEventFunctionMap[event.info.code];
					if(f is Function) f();
					else if(f is String) xroot.binCommand(f,this);
					else if(debug) U.log(tname +"[netStatusHandler] no behaviour defined for", event.info.code);
					break;
			}
		}
		/** Responds to security error by calling EXIT_SEQUENCE*/
		protected function securityErrorHandler(e:SecurityErrorEvent):void
		{
			if(debug) U.log(e);
			EXIT_SEQUENCE();
		}
		/** Responds to NetStream.Play.Complete - resolves replay or exit */
		protected function onPlayStatus(info:Object):void 
		{
			if(debug) U.log(U.bin.structureToString(info))
			if('code' in info)
			{
				switch(info.code)
				{
					case "NetStream.Play.Complete":
						resolveVideoComplete();
						break;
					default:
						if(debug) U.log(tname +"[onPlayStatus] no behaviour defined for", info.code);
						break;
				}
			}
		}
		/** As soon as meta data is received, video dimensions and aspect ratio is parsed */
		protected function onMetaData(info:Object):void 
		{
			if(debug) U.log(tname + "onMetaData\n");
			xvideoMeta = info;
			var w:Number = info.width as Number;
			var h:Number = info.height as Number;
			if(debug) U.log('original dim', w + 'x' + h);
			if(!isNaN(w) && !isNaN(h) && w > 0 && h > 0)
			{
				xvideoAspectRatio = w/h;
				updateDimensions();
				if(debug) U.log("videoAspectRatio", videoAspectRatio, "actual video object dimensions:", video ? (video.width + "x" + video.height) : '');
			}
			xcounter.timing = [0, int(xvideoMeta.duration)];
			xcounter.time = ns.time;
			xcounter.onUpdate = xOnTimerUpdate;
			if(onMeta is String)
				xroot.binCommand(onMeta,this);
			if(onMeta is Function)
				onMeta();
		}
		
		//-------------------------------------------------------------- END OF EVENT HANDLING SECTION ------------------------------------------------------//
		//-------------------------------------------------------------- MECHANIC SECTION ------------------------------------------------------//
		
		private function resolveVideoComplete():void
		{
			if(infiniteLoop || --xloops > 0)
				restart();
			else
			{
				if(onComplete is String) xroot.binCommand(onComplete,this);
				else if(onComplete is Function)	onComplete();
				
				if(destroyOnEnd)
					EXIT_SEQUENCE()
				else if(debug) U.log(tname + "destroyOnEnd=false, call EXIT_SEQUENCE or destroy() to dispose this content");
			}
		}
		
		private function ON_CONNECTED():void
		{
			if(debug) U.log("ON_CONNECTED");
			if(DESTROYED)
			{
				if(debug) U.log("connected while destroyed, return");
				EXIT_SEQUENCE();
				return;
			}
			build_netStream(); // BUILDING NET STREAM
			build_video(); // DECIDING WHICH AND BUILDING VIDEO
			if(debug) U.log(tname +"NS PLAY!", rtmp);
			ns.play(rtmp); // PLAY MEANS FILL THE BUFFER IN FACT. ACTUAL PLAY OCCURES ON_PLAY_START
		}
		
		private function ON_PLAY_START():void
		{
			if(debug) U.log("ON_PLAY_START");
			xcounter.interval =1;
			IS_PAUSED = false;
			
			if(onPlayStart is String) xroot.binCommand(onPlayStart,this);
			else if(onPlayStart is Function) onPlayStart();
			
			if(FIRST_FILL)
			{
				if(AUTOPLAY)
				{
					if(debug) U.log(tname +"[ON_PLAY_START] AUTOPLAY = true - NOT PAUSING");
					ns.bufferTime = bufferPlayback;
				}
				else
				{
					if(debug) U.log(tname +"[ON_PLAY_START] AUTOPLAY = false - PAUSING");
					ns.pause();
				}	
			}
			else if(FIRST_FILL = false)
			{
				if(debug) U.log(tname +"[ON_PLAY_START] FIRST_FILL = false");
				ns.bufferTime = bufferPlayback;
			}
			FIRST_FILL = false;
		}
		
		private function ON_PAUSE():void
		{
			IS_PAUSED = true;
			if(onPlayStop is String) xroot.binCommand(onPlayStop,this);
			else if(onPlayStop is Function) onPlayStop();
			xcounter.timing = [0, int(xvideoMeta.duration)];
			xcounter.time = ns.time;
		}
		
		private function ON_BUFFER_FULL():void
		{
			if(debug) U.log("ON_BUFFER_FULL");
			EMPTY_BUFFER = false;
			if(FIRST_FILL)
			{
				// THIS DOES NOT CHANGE BUFFER FROM INITIAL TO PLAYBACK BECAUSE ONLY PLAY CAN DO IT
				//PLAY ON FIRST FILL SO FIRST_FILL ALSO REMAINS UNTOUCHED
				if(debug) U.log(tname + "bufferInitialMs  filled", bufferInitial);
				if(AUTOPLAY)
				{
					if(debug) U.log(tname +"[ON_BUFFER_FULL] AUTOPLAY = true - NOT PAUSING");
				}
				else
				{
					if(debug) U.log(tname +"[ON_BUFFER_FULL] AUTOPLAY = false - PAUSING");
					ns.pause();
				}	
			}
			else
			{
				if(debug) U.log(tname +"[ON_BUFFER_FULL] FIRST_FILL = false");
			}
		
			if(debug) U.log(tname +"NEW BUFFER TIME :", ns.bufferTime);
			if(onBufferFull is String) xroot.binCommand(onBufferFull,this);
			else if(onBufferFull is Function) onBufferFull();
		}		
		
		private function ON_BUFFER_EMPTY():void
		{
			if(debug) U.log("ON_BUFFER_EMPTY");
			EMPTY_BUFFER = true;
			if(onBufferEmpty is String) xroot.binCommand(onBufferEmpty,this);
			else if(onBufferEmpty is Function) onBufferEmpty();
		}
		
		private function tryReconnect():void
		{
			if(debug) U.log("tryReconnect",reconnectAttemptsNo);
			if(--reconnectAttemptsNo > 0)
			{
				setTimeout(build_netConnection, reconnectGapMs);
			}
			else
			{
				if(debug) U.log(" ☠ ☠ ☠ "+reconnectAttemptsNo+" RECCONECTS FAIL ☠ ☠ ☠  ");
				EXIT_SEQUENCE();
			}
		}
		
		private function EXIT_SEQUENCE():void
		{
			if(!DESTROYED)
			{
				if(debug) U.log("EXIT_SEQUENCE");
				onFrame = null;
				destroyAll();
				if(onExit is String) xroot.binCommand(onExit,this);
				else if(onExit is Function) onExit();
			}
			
		}
		
		//------------------------------------------------------ DESTROY SECTION ------------------------------------------------------//
		
		private function destroyAll():void
		{
			if(debug) U.log(tname +"DESTROY ALL");
			DESTROYED = true;
			IS_PAUSED = false;
			xvideoMeta = null;
			destroyNC();
			destroyNS();
			destroyVideo();
			xrtmp = null;
			xcounter.stopAll();
		}
		private function destroyNC():void
		{
			if(nc)
			{
				if(debug) U.log(tname+"DESTROY NET CONNECTION");
				nc.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
				nc.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
				nc.close();
				xnc = null;
			}
			xvideoAspectRatio = 0;
			xvideoMeta = null;
		}
		
		private function destroyNS():void
		{
			if(ns)
			{
				if(debug) U.log(tname+"DESTROY NET STREAM");
				ns.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
				try
				{
					ns.client = null;
					ns.close();
					ns.dispose();
				}
				catch(e:*) { }
				xns = null;
			}
			nso= null;
			xvideoAspectRatio = 0;
			xvideoMeta = null;
		}
				
		private function destroyVideo():void
		{
			if(video)
			{
				if(debug) U.log(tname+"DESTROY VIDEO");
				video.attachNetStream(null);
				video.clear();
				if(video.parent)
					video.parent.removeChild(video);
				xvideo = null;
			}
			xvideoAspectRatio = 0;
			xvideoMeta = null;
		}
		//------------------------------------------------------ PUBLIC API  ------------------------------------------------------//
		/** Returns metadata object supplied by netstream (info about video) if available, null otherwise */
		public function get videoMeta():Object { return xvideoMeta }
		/** Returns video dimensions aspect ratio (w/h) if available, 0 otherwise */
		public function get videoAspectRatio():Number { return xvideoAspectRatio }
		/** Returns NetConnection instance used for NetSteeam if available, null otherwise */
		public function get nc():NetConnection { return xnc }
		/** Returns video instance itself */
		public function get video():Video {	return xvideo}
		/** Returns NetStream instance used if available, null otherwise */
		public function get ns():NetStream { return xns }
		/** Video address to play. Eg. <i>http://ggl.com/v.mp4</i><br>Changing this property during playback causes 
		 * closure of existing connection / stream instantly and building new one instead. */
		public function get rtmp():String { return xrtmp }
		public function set rtmp(v:String):void
		{
			if(v == xrtmp)
				return;
			if(debug) U.log(tname+"SETTING RTMP", v);
			destroyAll();
			xrtmp = v;
			build_netConnection();
		}
		/** Determines how many times video will be played/restarted before <code>onComplete</code> sequence is fired */
		public function get loops():int	{ return xloops }
		public function set loops(v:int):void
		{
			xloops = v;
			infiniteLoop = (v < 1);
		}
		/** Dettermines length of buffer (needed to start playing video) @see #bufferInitial */
		public function get bufferPlayback():Number { return xbufferPlayback }
		public function set bufferPlayback(v:Number):void 
		{
			xbufferPlayback = v;
			if(!FIRST_FILL && ns)
				ns.bufferTime = v;
		}
		/** Specifies a maximum buffer length for live streaming content, in seconds.*/
		public function get bufferMax():Number { return xbufferMax }
		public function set bufferMax(v:Number):void
		{
			xbufferMax = v;
			if(ns)
				ns.bufferTimeMax = v;
		}
		/** Controlls video sound volume. 0 - 1 */
		public function get volume():Number { return xvolume }
		public function set volume(v:Number):void
		{
			xvolume = v > 1 ? 1 : (v < 0 ? 0 : v);
			if(ns)
				ns.soundTransform = new SoundTransform(xvolume);
		}
		
		/** Function to execute on every frame. (callback instead of event listener)*/
		public function get onFrame():Function { return xonFrame }
		public function set onFrame(v:Function):void
		{
			if(v == null)
				this.removeEventListener(Event.ENTER_FRAME, onEnterFrameHandler);
			else
			{
				this.addEventListener(Event.ENTER_FRAME, onEnterFrameHandler);
			}
			xonFrame = v;
		}
		/** Returns values 0-1, determining percentage of video played back.<br>If for whatever reason 
		 * info can't be obtained - returns 0*/
		public function get percentTime():Number
		{
			if(nc == null || ns == null || xvideoMeta == null)
				return 0;
			xpercentTime = (ns.time / xvideoMeta.duration);
			if(xpercentTime < 0) xpercentTime = 0;
			if(xpercentTime > 1) xpercentTime = 1;
			return xpercentTime;
		}
		/** Returns values 0-1, determining percentage of sumaric video playback head and data in the buffer. 
		 * <br>If for whatever reason info can't be obtained - returns 0 */
		public function get percentBuffer():Number
		{
			if(nc == null || ns == null || xvideoMeta == null)
				return 0;
			xpercentBuffer = ((ns.bufferLength +  ns.time) /  xvideoMeta.duration);
			if(xpercentBuffer < 0) xpercentBuffer = 0;
			if(xpercentBuffer > 1) xpercentBuffer = 1;
			return xpercentBuffer;
		}
		/** Returns values 0-1, determining percentage of bytes loaded against total bytes.<br> 
		 * If for whatever reason info can't be obtained - returns 0 */
		public function get percentBytes():Number
		{
			if(ns == null)
				return 0;
			xpercentBytes = ns.bytesLoaded / ns.bytesTotal;
			if(xpercentBytes < 0) xpercentBytes = 0;
			if(xpercentBytes > 1) xpercentBytes = 1;
			return xpercentBytes;
		}
		/**Sets height of the video. If <code>keepAspectRatio=true</code> also sets width.*/
		override public function set height(v:Number):void
		{
			xheight = v;
			if(video)
			{
				video.height = xheight;
				if(keepAspectRatio && videoAspectRatio > 0)
				{
					video.width = xheight * videoAspectRatio;
					xwidth = video.width;
				}
			}
		}
		/**Sets width of the video. If <code>keepAspectRatio=true</code> also sets height.*/
		override public function set width(v:Number):void
		{
			xwidth = v;
			if(video)
			{
				video.width = xwidth;
				if(keepAspectRatio && videoAspectRatio > 0)
				{
					video.height = xwidth / videoAspectRatio;
					xheight = video.height;
				}
			}
		}
		/** Pauses video if available. Same result as <code>stop()</code> */
		public function pause():void { ns ? ns.pause() : null }
		/** Pauses video if available. Same result as <code>pause()</code> */
		public function stop():void { ns ? ns.pause() : null }
		/** Stops video, terminates all connections. Does not remove references. */
		public function destroy():void { EXIT_SEQUENCE(); }
		/** If connection is not yet established - starts build sequence. Otherwise attempts to unpause. */
		public function play():void
		{
			if(!nc)
				return build_netConnection();
			if(nc && nc.connected)
			{
				if(ns)
					ns.resume();
			}
		}
		/** If connections are established - seeks for key frame 0 and dispatches onPlayStart, otherwise 
		 * destroys instance and builds it again. */
		public function restart():void
		{
			if(nc && nc.connected && ns)
			{
				ns.seek(0);
				ON_PLAY_START(); // because seek dispatches SeekStart.Notify and Seek.Notify only (no Play.Start);
			}
			else
			{
				destroyAll();
				XSupport.applyAttributes(def, this);
				build_netConnection();
			}
		}
		/** Returns formatted according to <code>timeFormat</code> String describing current video
		 * playback remaining till video end time @see #timeFormat */
		public function get timeRemaining():String { return xtimeRemaining }
		/** Returns formatted according to <code>timeFormat</code> String describing current video
		 * playback time @see #timeFormat */
		public function get timePassed():String { return xtimeRemaining }

	}
}