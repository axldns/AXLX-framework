/**
 *
 * AXLX Framework
 * Copyright 2014-2016 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package axl.xdef
{
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.system.Capabilities;
	import flash.system.Security;
	import flash.system.System;
	import flash.utils.describeType;
	
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
		/** Modyfies config file sub-directory.<br>
		 * Array where first element is regular expression, second "replace" argument.<br><br>
		 * If xRoot.appRemote is defined, final location of config file is going to be composed by executing <code>String.replace</code> on value of 
		 * xRoot.fileName with regular expression of this property.<br>
		 * New string is going to be concatenated with <code>appRemote</code> defined in xRoot class.<br>
		 * Default [/(\w+?)(_.*)/,"$1/$1$2/"] means filename VG_promo will produce VG/VG_PROMO,
		 * which will look for config in appRemote/VG/VG_promo/VG_promo.xml<br>
		 * If xRoot.appRemote is not defined, this property is ignored. */
		public var appReomoteSPLITfilename:Array = [/(\w+?)(_.*)/,"$1/$1$2/"];
		private var useLiveAranger:Boolean;
		private var liveAranger:LiveArranger;
		private var pathPrefixes:Array;
		private var xroot:xRoot;
		private var onComplete:Function;
		private var xparams:Object;
		
		public function xLauncher(rootObj:xRoot,onConfigReady:Function,parameters:Object=null)
		{
			xroot = rootObj;
			onComplete = onConfigReady;
			xparams = parameters;
			validateParams();
			tname= '[xRoot ' + xRoot.version+'][xLauncher]';
			U.autoStageManaement = false;
			U.onStageAvailable = onStageAvailable;
			U.init(xroot,1,1);
			findFilename();
		}
		
		private function validateParams():void
		{
			var type:XML = describeType(xparams);
			if(type.@isDynamic.toString() != "true")
				xparams = {};
			flash.system.System.disposeXML(type);
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
				onLoaderInfoAvailable();
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
			xroot.fileName = xroot.fileName ||  xparams.fileName || U.fileNameFromUrl(Ldr.FileClass.applicationDirectory.resolvePath('..').nativePath,true);
			U.log(tname +" fileName =", xroot.fileName, ' isLocal:', isLocal);
			fileNameFound();
		}
		
		private function onLoaderInfoAvailable(e:Event=null):void
		{
			var report:String = tname + '[onLoaderInfoAvailable][REPORT]:'
			report += '\n\tloaderInfo.url:',xroot.loaderInfo.url;
			report += '\n\tloaderInfo.parameters.fileName: ' + xroot.loaderInfo.parameters.fileName + ' vs assigned before: ' + xroot.fileName;
			report += '\n\tloaderInfo.parameters.loadedURL: ' + xroot.loaderInfo.parameters.loadedURL;
			report += '\n\tparameters.fileName: ' + xparams.fileName;
			report += '\n\tparameters.loadedURL: ' + xparams.loadedURL;
			isLocal = xroot.loaderInfo.url.match(/^(file|app):/i);
			
			//resolve filename
			xroot.fileName = xroot.fileName || xparams.fileName || xroot.loaderInfo.parameters.fileName || U.fileNameFromUrl(xroot.loaderInfo.parameters.loadedURL,true) || U.fileNameFromUrl(xroot.loaderInfo.url,true);
			
			report += "\n\tfileName: " + xroot.fileName + '\nisLocal: ' + isLocal;
			U.log(report);
			report = null;
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
			
			pathPrefixes = [];
			
			var isMobile:Boolean = flash.system.Capabilities.os.match(/(android|iphone)/i);
			var isAppLoadedFromApp:Boolean = !isMobile && xroot.loaderInfo.url != null && xroot.loaderInfo.url.match(/^app:/) !=null;
			var isStandAlone:Boolean = !isMobile && xroot.loaderInfo.url != null && xroot.loaderInfo.url.match(/^file:/) != null;
			
			var appRemoteWasSet:Boolean = (xroot.appRemote != null);
			var dirParameterPassed:Boolean =  (xroot.loaderInfo.parameters.hasOwnProperty('loadedURL'));
			var fileNameNoExtension:String = U.fileNameFromUrl(xroot.fileName,false,true);
			
			
			//app remote
			if(!appRemoteWasSet && xroot.loaderInfo != null)
			{
				if(xparams.loadedURL != null)
					xroot.appRemote = U.dirFromUrl(xparams.loadedURL) + '../';
				else if(xroot.loaderInfo.parameters.hasOwnProperty('loadedURL'))
					xroot.appRemote = U.dirFromUrl(xroot.loaderInfo.parameters.loadedURL) + '../';
				else if(xroot.loaderInfo.url != null)
					xroot.appRemote = U.dirFromUrl(xroot.loaderInfo.url) + '../';
			}
			if(appRemoteWasSet && xroot.fileName != null && appReomoteSPLITfilename != null)
				xroot.appRemote += fileNameNoExtension.replace(appReomoteSPLITfilename[0], appReomoteSPLITfilename[1]);
			
			
			// path prefixes
			if(isMobile)
			{
				pathPrefixes = [
					Ldr.FileClass.applicationStorageDirectory.url,
					xroot.appRemote,
					Ldr.FileClass.applicationDirectory.url
				];
				U.log(tname,"[Environment - local, mobile]");
			}
			else if(isStandAlone)
			{
				pathPrefixes = ['..',xroot.appRemote]; // to work standalone LOCALLY
				U.log(tname,"[Environment - local, standalone]");
			}
			else 
			{	// app loaded or network
				pathPrefixes = [];
				if(dirParameterPassed)
					pathPrefixes.push(U.dirFromUrl(xroot.loaderInfo.parameters.loadedURL) + '../');
				pathPrefixes.push(xroot.appRemote);
			}
			
			// config suffix
			NetworkSettings.configPath = NetworkSettings.configPath ||  String(fileNameNoExtension ? String('/' + fileNameNoExtension + '.xml') : "cfg.xml");
			NetworkSettings.configPath += '?cacheBust=' + String(new Date().time);
			
		}
		
		private function loadConfig():void
		{
			U.log(tname,'[load config]\n' + 
			"[]FILENAME", xroot.fileName,'\n[]APPREMOTE',xroot.appRemote, "\n[]CONFIG PATH", NetworkSettings.configPath, '\n[]DIRS:', pathPrefixes);
			Ldr.load(NetworkSettings.configPath,onConfigLoaded,null,null,pathPrefixes);
		}
		
		/** When config or initial files could not be loaded
		 * By default it displays pop-up message*/
		protected function errorHandler(e:Event):void { U.msg("Config file not loaded")  }
		
		
		/** Instantiates live arranger and sets allow domain */
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
			} catch (e:*) { U.log("SecurityError on Security.allowInsecureDomain caught",e);}
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
			U.log(tname+'[DESTROY]');
		}
	}
}