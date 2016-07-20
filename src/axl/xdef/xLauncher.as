package axl.xdef
{
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.system.Capabilities;
	import flash.system.Security;
	
	import axl.utils.ConnectPHP;
	import axl.utils.Ldr;
	import axl.utils.NetworkSettings;
	import axl.utils.U;
	import axl.utils.liveArrange.LiveArranger;
	import axl.xdef.types.display.xRoot;

	public class xLauncher
	{
		private var tname:String;
		private var framesCounter:int;
		private var framesAwaitingLimit:int=60;
		private var isLocal:Array;
		/** Dictates config file sub-directory.<br>
		 * Array where first element is regular expression, second "replace" argument.<br>
		 * New string is going to be composed by executing <code>String.replace</code> function on swf file name.<br>
		 * New string is going to be added to <code>appRemote</code> which root location of config file.<br>
		 * Default [/(\w+?)(_.*)/,"$1/$1$2/"] means filename VG_promo will produce VG/VG_PROMO,
		 * which will look for config in appRemote/VG/VG_promo/VG_promo.xml */
		public var appReomoteSPLITfilename:Array = [/(\w+?)(_.*)/,"$1/$1$2/"];
		private var useLiveAranger:Boolean;
		private var liveAranger:LiveArranger;
		private var pathPrefixes:Array;
		private var xroot:xRoot;
		private var onComplete:Function;
		
		public function xLauncher(rootObj:xRoot,onConfigReady:Function)
		{
			xroot = rootObj;
			onComplete = onConfigReady;
			tname= xroot.toString();
			U.autoStageManaement = false;
			U.onStageAvailable = onStageAvailable;
			U.init(xroot,1,1);
			findFilename();
		}
		private function findFilename():void
		{
			U.log(tname + '[findFilename]');
			if(loaderInfoAvailable)
				onLoaderInfoAvailable();
			else
				xroot.addEventListener(Event.ENTER_FRAME, onEnterFrames);
		}
		
		private function get loaderInfoAvailable():Boolean { return xroot.loaderInfo && xroot.loaderInfo.url }
		private function onEnterFrames(e:*=null):void
		{
			if(loaderInfoAvailable)
			{
				xroot.removeEventListener(Event.ENTER_FRAME, onEnterFrames);
				onLoaderInfoAvailable()
			}
			else
			{
				if(++framesCounter < framesAwaitingLimit)
					U.log(tname, ' loaderInfoAvailable=false', framesCounter, '/', framesAwaitingLimit);
				else
				{
					U.log(tname, framesCounter, '/', framesAwaitingLimit, 'limit reached. loaderInfo property not found. ABORT');
					xroot.removeEventListener(Event.ENTER_FRAME, onEnterFrames);
					if(!Ldr.fileInterfaceAvailable)
						throw new Error("Unknown loaderInfo.url");
					else
						getFileNameFromFileClass();
				}
			}
		}
		
		private function getFileNameFromFileClass():void
		{
			U.log("loaderInfo", xroot.loaderInfo, "file class", Ldr.FileClass);
			isLocal = ['app:'];
			xroot.fileName = xroot.fileName || U.fileNameFromUrl(Ldr.FileClass.applicationDirectory.resolvePath('..').nativePath,true);
			U.log(tname +" fileName =", xroot.fileName, ' isLocal:', isLocal);
			fileNameFound()
		}
		
		private function onLoaderInfoAvailable(e:Event=null):void
		{
			U.log(tname + '[onLoaderInfoAvailable]');
			U.log(tname + ' loaderInfo:',xroot.loaderInfo);
			U.log(tname + ' loaderInfo.url:',xroot.loaderInfo.url);
			U.log(tname + ' loaderInfo.parameters.fileName:',xroot.loaderInfo.parameters.fileName, 'vs assigned before:', xroot.fileName);
			U.log(tname + ' loaderInfo.parameters.loadedURL:',xroot.loaderInfo.parameters.loadedURL);
			isLocal = xroot.loaderInfo.url.match(/^(file|app):/i);
			
			//resolve filename
			xroot.fileName = xroot.fileName || xroot.loaderInfo.parameters.fileName || U.fileNameFromUrl(xroot.loaderInfo.parameters.loadedURL,true) || U.fileNameFromUrl(xroot.loaderInfo.url,true);
			
			U.log(tname +" fileName =", xroot.fileName, ' isLocal:', isLocal);
			fileNameFound();
		}
		
		private function fileNameFound():void
		{
			U.log(tname + '[fileNameFound]loading config..');
			U.msg(null);
			resolveDirectories();
			loadConfig();
		}
		
		private function resolveDirectories():void
		{
			var c:Object = flash.system.Capabilities;
			NetworkSettings.configPath = NetworkSettings.configPath || '/cfg.xml';
			pathPrefixes = [];
			if(isLocal)
			{
				if(xroot.loaderInfo && xroot.loaderInfo.parameters.hasOwnProperty('loadedURL'))
				{
						var v:String = xroot.loaderInfo.parameters.loadedURL.substr(0,xroot.loaderInfo.parameters.loadedURL.lastIndexOf('/')+1) + '../';
						pathPrefixes.unshift(v);
				}
				else if(c.os.match(/(android|iphone)/i))
				{
					pathPrefixes = [
						Ldr.FileClass.applicationStorageDirectory.url,
						Ldr.FileClass.applicationDirectory.url
					];
				}
				else
				{
					pathPrefixes.unshift('..'); // to work standalone LOCALLY
				}
			}
			var fileNameNoExtension:String = U.fileNameFromUrl(xroot.fileName,false,true);
			if(xroot.fileName!=null)
			{
				xroot.appRemote += fileNameNoExtension.replace(appReomoteSPLITfilename[0], appReomoteSPLITfilename[1]);
				NetworkSettings.configPath =  '/' + fileNameNoExtension + '.xml';
			}
			
			if(xroot.loaderInfo && xroot.loaderInfo.parameters["remote"])
			{
				pathPrefixes.push(xroot.loaderInfo.parameters["remote"]);
			}
			else
				pathPrefixes.push(xroot.appRemote);
			NetworkSettings.configPath += '?cacheBust=' + String(new Date().time).substr(0,-3);
		}
		
		private function loadConfig():void
		{
			U.log(tname,'[load config] PathPrefixes', pathPrefixes);
			U.log("[]FILENAME", xroot.fileName,'\n[]APPREMOTE',xroot.appRemote, "\n[]CONFIG PATH", NetworkSettings.configPath);
			Ldr.load(NetworkSettings.configPath,onConfigLoaded,null,null,pathPrefixes);
		}
		
		/** [MIDDLE FLOW BREAK] Use it to deal with situations where config or initial files could not be loaded
		 * By default it displays pop-up message*/
		protected function errorHandler(e:Event):void { U.msg("Config file not loaded")  }
		
		
		/**[MIDDLE FLOW 1] As soon as stage is available - loading screen is displayed */
		protected function onStageAvailable():void
		{
			if(xroot.parent is Stage)
			{
				U.log(tname, "[GOT STAGE AS PARENT - using stage owner privileges]");
				xroot.stage.align = StageAlign.TOP_LEFT;
				xroot.stage.scaleMode = StageScaleMode.NO_SCALE;
			}
			else
			{
				U.log(tname, "[GOT "+xroot.parent+" AS PARENT - refrain from setting stage properties]");
			}
			if(useLiveAranger)
				liveAranger = LiveArranger.instance ? LiveArranger.instance : new LiveArranger();
			try { 
				Security.allowDomain("*");
				Security.allowInsecureDomain("*");
				U.log("Security domain set");
			} catch (e:*) { U.log("SecurityError caught",e);}
		}
		
		
		/** [MIDDLE FLOW 2] As soon as config is loaded project AND promo settings are being set */ 
		protected function onConfigLoaded():void
		{
			U.log(tname,"onConfigLoaded");
			var cfg:XML = Ldr.getAny(NetworkSettings.configPath) as XML;
			if(!(cfg is XML))
			{
				U.msg("Invalid config file");
				U.log("Config isn't valid XML file");
				return;
			}
			if(!cfg.hasOwnProperty('root') )
			{
				U.msg("Invalid config file");
				U.log("XML config has to have <root> node");
				return;
			}
			xroot.sourcePrefixes = getSourcePrefixes(cfg);
			
			if(cfg.hasOwnProperty('project'))
			{
				var projectSettings:XML = cfg.project[0];
				if(projectSettings.hasOwnProperty('@debug'))
					xroot.debug = (projectSettings.@debug == 'true');
				else
					xroot.debug = false;
				if(projectSettings.hasOwnProperty('@phpTimeout'))
					ConnectPHP.globalTimeout = int(projectSettings.@phpTimeout);
				if(projectSettings.hasOwnProperty('@assetsTimeout'))
					Ldr.globalTimeout = int(projectSettings.@assetsTimeout);
				U.log("[[[[[[ PROJECT ]]]]]]]", projectSettings.toXMLString());
			}
			
			// BUILD
			
			onComplete(cfg);
			destroy();
		}
		private function getSourcePrefixes(cfg:XML):Array
		{
			U.log(tname + '[getSourcePrefixes] local:', isLocal);
			var o:Array = [xroot.appRemote];
			if(cfg.hasOwnProperty('remote') && cfg.remote.hasOwnProperty('0') && cfg.remote[0].hasOwnProperty('children'))
			{
				var xmll:XMLList = cfg.remote[0].children();
				var ll:int = xmll.length();
				for(var i:int = 0; i<ll;i++)
					o.unshift(xmll[i].toString());
			}
			if(isLocal)
				o = pathPrefixes.concat(o);//o.unshift(pathPrefixes[0]);
			return o;
		}
		
		private function destroy():void
		{
			U.log('[xLauncher][DESTROY]');
		}
	}
}