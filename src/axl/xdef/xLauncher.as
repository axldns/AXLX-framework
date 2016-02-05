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
		
		public var onAllDone:Function;
		public var onStageAvailable:Function;
		public var onCfgFileListLoaded:Function;
		public var onProjectSettings:Function;
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
		private var tname:String = '[xLauncher 0.0.3]';
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
			U.log(tname + ' loaderInfo',rootObj.loaderInfo);
			U.log(tname + ' loaderInfo.url',rootObj.loaderInfo.url);
			U.log(tname + ' loaderInfo.parameters.fileName',rootObj.loaderInfo.parameters.fileName);
			U.log(tname + ' loaderInfo.parameters.loadedURL',rootObj.loaderInfo.parameters.loadedURL);
			isLocal = rootObj.loaderInfo.url.match(/^(file|app):/i);
			
			if(rootObj.loaderInfo.parameters.loadedURL != null)
			{
				fileName = U.fileNameFromUrl(rootObj.loaderInfo.parameters.loadedURL,true);
				mergeLoadedURLtoLibraryURLs(rootObj.loaderInfo.parameters.loadedURL.substr(0,rootObj.loaderInfo.parameters.loadedURL.lastIndexOf('/')+1));
			}
			else if(rootObj.loaderInfo.url != null)
			{
				if(isLocal)
					Ldr.defaultPathPrefixes.unshift('..');
			}
			if(rootObj.loaderInfo.parameters.fileName != null)
				fileName = rootObj.loaderInfo.parameters.fileName;
			
			fileName = fileName || rootObj.loaderInfo.parameters.fileName || U.fileNameFromUrl(rootObj.loaderInfo.url);
			
			trace(tname +" fileName =", fileName, 'isLocal:', isLocal);
			fileNameFound()
		}
		
		private function mergeLoadedURLtoLibraryURLs(v:String):void
		{
			if(isLocal)
			{
				Ldr.defaultPathPrefixes.unshift('../');
			}
			for(var i:int = 0; i < Ldr.defaultPathPrefixes.length; i++)
			{
				var s:String =  Ldr.defaultPathPrefixes[i];
				if(s.match(/^(\.\.\/|\/.\.\/)/))
				{
					Ldr.defaultPathPrefixes[i] = v +  Ldr.defaultPathPrefixes[i];
				}
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
			
			trace(tname,'[MERGED] Ldr.defaultPathPrefixes', Ldr.defaultPathPrefixes);
			
			
			NetworkSettings.configPath = '/' + fileName.replace('.swf', '.xml')+ '?cacheBust=' + String(new Date().time).substr(0,-3);
			flow = new Flow();
			flow.addEventListener(flash.events.ErrorEvent.ERROR, errorHandler);
			flow.onConfigLoaded = onConfigLoaded;
			U.autoStageManaement = false;
			U.init(rootObj,800,600,onFilesLoaded,flow);
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
		}
		
		protected function onConfigLoaded(xml:XML):void
		{
			U.log(rootObj +'[xLauncher][onConfigLoaded]');
			if(!(xml is XML) || !xml.hasOwnProperty('root') )
			{
				U.msg("Invalid config file");
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
			rootObj.def = xml.root[0];
			partDone();
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
				U.log(rootObj +"[xSetup][getSourcePrefixes]local loading. Unshifting '..' to source prefixes");
				o.unshift(Ldr.defaultPathPrefixes[0]);
			}
			else
				U.log(rootObj +"[xSetup][getSourcePrefixes] NOT A LOCAL LOADING. First address prefix is:", o[0]);
			return o;
		}		
		
		protected function onFilesLoaded():void
		{
			U.log(rootObj +'[xLauncher][onFilesLoaded]');
			flow.destroy();
			flow = null;
			if(onCfgFileListLoaded)
				onCfgFileListLoaded();
			partDone();
		}
		
		private function partDone():void
		{
			if(++partCounter >= 2)
			{
				U.log(rootObj +'[xLauncher][COMPLETE]');
				if(onAllDone)
					onAllDone();
				destroy();
			}
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
			onAllDone = null;
			onStageAvailable = null;
			onCfgFileListLoaded = null;
			onProjectSettings = null;
		}
	}
}