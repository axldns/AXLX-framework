package axl.xdef
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	
	import axl.ui.Messages;
	import axl.utils.ConnectPHP;
	import axl.utils.Flow;
	import axl.utils.Ldr;
	import axl.utils.NetworkSettings;
	import axl.utils.U;
	import axl.xdef.types.xRoot;

	public class xLauncher
	{
		private var appRemote:Object;
		private var flow:Flow;
		private var projectSettings:XML;
		private var isLocal:Boolean;
		private var rootObj:xRoot;
		private var setPermitedProps:Function;
		private var partCounter:int=0;
		
		public var onAllReady:Function;
		public var onStageAvailable:Function;
		public var onConfigReady:Function;
		public var onProjectSettings:Function;
		public var onErrors:Function;
		/** 
		 * <code>appRemoteURLs</code> can be sufixed with <code>fileName</code> or its chunks before loading config.<br>
		 * If value is null/undefined: config is loaded as appRemoteURLs + filename.xml<br>
		 * Otherwise replaced filename is added to appremote.<br>
		 * Let <code>appRemoteURLs = 'http://axldns.com/'</code><br>
		 * Let <code>fileName = MOV_VIP_axldns_201601.swf</code><br>
		 * If <code>appRemoteSPLITfilename = null</code><br>
		 * Loaded config URL is: <code>http://axldns.com/MOV_VIP_axldns_201601.xml</code><br>
		 * if <code>appRemoteSPLITfilename = ["_","/"]</code>
		 * Loaded config URL is <code>http://axldns.com/MOV/VIP/axldns/201601/MOV_VIP_axldns_201601.xml</code><br>
		 * if <code>appRemoteSPLITfilename = [/_/,"/"]</code>
		 * Loaded config URL is <code>http://axldns.com/MOV/VIP_axldns_201601/MOV_VIP_axldns_201601.xml</code><br>
		 * @see #fileName
		 * */
		public var appReomoteSPLITfilename:Array;
		/** Forces to load config of specific <code>fileName</code>. If it's not set,<br>
		 * it checks  for <code>loaderInfo.parameters.fileName</code>,<br>
		 * if it's not set it tries to figure it out from <code>loaderInfo.url</code>
		 * @see #appReomoteSPLITfilename */
		public var fileName:String;
		private var framesCounter:int;
		public var framesAwaitingLimit:int = 30;
		private var isLaunched:Boolean;
		private var tname:String = '[xLauncher 0.0.12]';
		
		public function xLauncher(target:xRoot,setPermitedProperties:Function)
		{
			rootObj = target;
			setPermitedProps = setPermitedProperties;
		}
		
		public function launch(appRemoteURLs:Object):void 
		{ 
			if(!isLaunched)
			{
				U.log(rootObj +'[xLauncher][launch]' + appRemoteURLs);
				appRemote = appRemoteURLs;
				findFilename();
			}
			isLaunched = true;
		}
		
		private function findFilename():void
		{
			U.log(tname + '[findFilename]');
			if(loaderInfoAvailable)
				onLoaderInfoAvailable();
			else
				rootObj.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		private function get loaderInfoAvailable():Boolean { return rootObj.loaderInfo && rootObj.loaderInfo.url }
		private function onEnterFrame(e:*=null):void
		{
			if(loaderInfoAvailable)
			{
				rootObj.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
				onLoaderInfoAvailable()
			}
			else
			{
				if(++framesCounter < framesAwaitingLimit)
					U.log(rootObj + ' loaderInfoAvailable=false', framesCounter, '/', framesAwaitingLimit);
				else
				{
					U.log(rootObj, framesCounter, '/', framesAwaitingLimit, 'limit reached. loaderInfo property not found. ABORT');
					rootObj.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
					isLaunched = false;
				}
			}
		}
		
		private function onLoaderInfoAvailable(e:Event=null):void
		{
			U.log(tname + '[onLoaderInfoAvailable]');
			U.log(tname + ' loaderInfo:',rootObj.loaderInfo);
			U.log(tname + ' loaderInfo.url:',rootObj.loaderInfo.url);
			U.log(tname + ' loaderInfo.parameters.fileName:',rootObj.loaderInfo.parameters.fileName, 'vs assigned before:', fileName);
			U.log(tname + ' loaderInfo.parameters.loadedURL:',rootObj.loaderInfo.parameters.loadedURL);
			isLocal = rootObj.loaderInfo.url.match(/^(file|app):/i);
			
			
			//resolve filename
			fileName = fileName || rootObj.loaderInfo.parameters.fileName || U.fileNameFromUrl(rootObj.loaderInfo.parameters.loadedURL,true) || U.fileNameFromUrl(rootObj.loaderInfo.url,true);
			//resolve directories
			if(rootObj.loaderInfo.parameters.loadedURL != null)
			{
				// this is not local
				mergeLoadedURLtoLibraryURLs();
			}
			else if(rootObj.loaderInfo.url != null)
			{
				if(isLocal)
					Ldr.defaultPathPrefixes.unshift('..');
			}
			
			U.log(tname +" fileName =", fileName, ' isLocal:', isLocal);
			fileNameFound()
		}
		
		private function mergeLoadedURLtoLibraryURLs():void
		{
			trace('mergeLoadedURLtoLibraryURLs')
			if(isLocal)
			{
				trace('mergeLoadedURLtoLibraryURLs is local', Ldr.defaultPathPrefixes);
				//Ldr.defaultPathPrefixes.unshift('../');
			
			
				// retrurns [www.example.com/test/location] FROM [www.example.com/test/location/flash.swf]
				var v:String = rootObj.loaderInfo.parameters.loadedURL.substr(0,rootObj.loaderInfo.parameters.loadedURL.lastIndexOf('/')+1);
				
				Ldr.defaultPathPrefixes.unshift(v);
				trace('mergeLoadedURLtoLibraryURLs AFTER', Ldr.defaultPathPrefixes);
				//adds [www.example.com/test/location] TO ANYTHING LIKE [../flash.xml] 
				
				/*for(var i:int = 0; i < Ldr.defaultPathPrefixes.length; i++)
				{
					var s:String =  Ldr.defaultPathPrefixes[i];
					if(true||s.match(/^(\.\.\/|\/.\.\/|\.)/))
					{
						Ldr.defaultPathPrefixes[i] = v +  Ldr.defaultPathPrefixes[i];
					}
				}*/
			}
		}
		
		private function fileNameFound():void
		{
			U.log(tname + '[fileNameFound]');
			U.msg(null);
			if(appReomoteSPLITfilename is Array && appReomoteSPLITfilename.length ==2)
			{
				appRemote += U.fileNameFromUrl(fileName,false,true).replace(appReomoteSPLITfilename[0], appReomoteSPLITfilename[1]);
			}
			Ldr.defaultPathPrefixes.push(rootObj.loaderInfo.parameters["remote"] || appRemote);
			
			U.log(tname,'[MERGED] Ldr.defaultPathPrefixes', Ldr.defaultPathPrefixes);
			
			
			NetworkSettings.configPath = fileName.replace('.swf', '.xml')+ '?cacheBust=' + String(new Date().time).substr(0,-3);
			flow = new Flow();
			flow.addEventListener(flash.events.ErrorEvent.ERROR, errorHandler);
			flow.addEventListener(flash.events.Event.COMPLETE, onFlowComplete);
			flow.onConfigLoaded = onConfigLoaded;
			U.autoStageManaement = false;
			U.log(tname, 'Calling U.init with flow of config', NetworkSettings.configPath);
			U.init(rootObj,800,600,onAllDone,flow);
			onStageAvailable?onStageAvailable():null
		}
		
		protected function errorHandler(e:Event):void
		{
			U.log(rootObj +'[xLauncher][ErrorHandler]');
			if(isLocal)
			{
				if(!Messages.areDisplayed)
					U.msg('Flow error - config'+ e.toString());
			}
			else
				U.log('Flow error - config'+ e.toString())
			isLaunched = false;
			if(onErrors)
				onErrors();
		}
		
		protected function onConfigLoaded(xml:XML):void
		{
			U.log(rootObj +'[xLauncher][onConfigLoaded]');
			if(!(xml is XML) || !xml.hasOwnProperty('root') )
			{
				U.log("Invalid config file");
				return;
			}
			if(xml.hasOwnProperty('project'))
			{
				projectSettings = xml.project[0];
				
				if(projectSettings.hasOwnProperty('@phpTimeout'))
					ConnectPHP.globalTimeout = int(projectSettings.@phpTimeout);
				if(projectSettings.hasOwnProperty('@assetsTimeout'))
					Ldr.globalTimeout = int(projectSettings.@assetsTimeout);
				var debug:Boolean = (projectSettings.hasOwnProperty('@debug') && (projectSettings.@debug == 'true'))
				var font:String = projectSettings.hasOwnProperty('@defaultFont') ? String(projectSettings.@defaultFont) : null;
				setPermitedProps(xml,font,debug,getSourcePrefixes(xml))
			}
			if(onProjectSettings)
				onProjectSettings();
			U.log("[[[[[[[ PROJECT BUILD ]]]]]]]", projectSettings.toXMLString());
			buildContent(xml.root[0]);
		}
		
		private function buildContent(rootDef:XML):void
		{
			if(rootObj.stage)
				rootObj.def = rootDef;
			else
				rootObj.addEventListener(Event.ADDED_TO_STAGE, rootHasStage);
			function rootHasStage(e:Event):void
			{
				rootObj.removeEventListener(Event.ADDED_TO_STAGE, rootHasStage);
				rootObj.def = rootDef;
			}		
		}
		
		private function getSourcePrefixes(conf:XML):Array
		{
			var xmll:XMLList = conf.remote[0].children();
			var ll:int = xmll.length();
			var o:Array = [];
			for(var i:int = 0; i<ll;i++)
				o.push(xmll[i].toString());
			if(isLocal)
			{
				o.unshift(Ldr.defaultPathPrefixes[0]);
				U.log(rootObj +"[xSetup][getSourcePrefixes][LOCAL]");
			}
			else
			{
				o.push(Ldr.defaultPathPrefixes[0]);
				U.log(rootObj +"[xSetup][getSourcePrefixes][NOT A LOCAL LOADING]");
			}
			U.log(tname, rootObj, '[xSetup][SRC PATHS]:\n# ', o.join('\n# '));
			return o;
		}		
		
		protected function onFlowComplete(e:Event=null):void
		{
			U.log(rootObj +'[xLauncher][onFilesLoaded]');
			flow.removeEventListener(flash.events.ErrorEvent.ERROR, errorHandler);
			flow.removeEventListener(flash.events.Event.COMPLETE, onFlowComplete);
			flow.destroy();
			flow = null;
			if(onConfigReady)
				onConfigReady();
		}
		
		
		protected function onAllDone():void
		{
			U.log(rootObj +'[xLauncher][COMPLETE]');
			if(onAllReady)
				onAllReady();
		}
		
		private function destroy():void
		{
			U.log(rootObj +'[xLauncher][DESTROY]');
			fileName = null;
			appRemote = null;
			projectSettings = null;
			
			isLocal = undefined; 
			rootObj = null;
			setPermitedProps = null;
			partCounter = 0;
			onStageAvailable = null;
			onConfigReady = null;
			onProjectSettings = null;
		}
	}
}