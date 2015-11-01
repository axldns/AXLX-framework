package axl.xdef
{
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.filters.BitmapFilter;
	import flash.geom.ColorTransform;
	import flash.utils.getDefinitionByName;
	
	import axl.ui.Carusele;
	import axl.utils.AO;
	import axl.utils.Ldr;
	import axl.utils.U;
	import axl.xdef.interfaces.ixDef;
	import axl.xdef.interfaces.ixDisplay;
	import axl.xdef.types.xBitmap;
	import axl.xdef.types.xButton;
	import axl.xdef.types.xCarousel;
	import axl.xdef.types.xCarouselSelectable;
	import axl.xdef.types.xForm;
	import axl.xdef.types.xMasked;
	import axl.xdef.types.xObject;
	import axl.xdef.types.xRoot;
	import axl.xdef.types.xScroll;
	import axl.xdef.types.xSprite;
	import axl.xdef.types.xSwf;
	import axl.xdef.types.xText;

	public class XSupport
	{
		private static var ver:Number = 0.95;
		private static var additionQueue:Vector.<Function> = new Vector.<Function>();
		private static var userTypes:Object={};
		public static function get version():Number { return ver}
			
		private var smallRegistry:Object={};
		public var defaultFont:String;
		public var root:xRoot;
		
		
		public function get registry():Object { return smallRegistry }
		public function registered(v:String):Object { return smallRegistry[v] }
		
		public function XSupport()
		{
		}
		public static function registerUserType(xmlTagName:String, instantiator:Function):void { userTypes[xmlTagName] = instantiator }
		public static function applyAttributes(def:XML, target:Object):Object
		{
			if(def == null)
				return target; 
			var attribs:XMLList = def.attributes();
			var al:int = attribs.length();
			var val:*;
			var key:String;
			var keyArray:Array;
			var deepTarget:Object;
			for(var i:int = 0; i < al; i++)
			{
				keyArray = String(attribs[i].name()).split('.');
				key = keyArray.pop();
				deepTarget = target;
				while(keyArray.length)
					deepTarget = deepTarget[keyArray.shift()];
				val = attribs[i].valueOf();
				if(target.hasOwnProperty('xroot') && val.charAt(0) == '$' )
				{
					val = target.xroot.binCommand(val.substr(1));
					U.log(target, target.hasOwnProperty('name') ? target.name : '','applying', val, '<==', attribs[i].valueOf());
				}
				else
					val = valueReadyTypeCoversion(val);
				if(key in deepTarget)
					deepTarget[key] = val;
			}
			if(target.hasOwnProperty('meta') && target.meta is String)
				throw new Error("Invalid json for element " +  def.localName() + ' ' +  def.@name );
			return target;
		}
		
		public static function animByNameExtra(target:ixDef, animName:String, onComplete:Function=null, killCurrent:Boolean=true,reset:Boolean=false):uint
		{
			if(reset)
				target.reset();
			else if(killCurrent);
			AO.killOff(target);
			if(target.meta.hasOwnProperty(animName))
			{
				var animNameArray:Array = target.meta[animName];
				var ag:Array = [];
				if(!(animNameArray[0] is Array))
					ag[0] =  animNameArray;
				else
					ag = animNameArray;
				var atocomplete:uint = ag.length;
				for(var i:int = 0; i < ag.length; i++)
				{
					var g:Array = [target].concat(ag[i]);
					var f:Object = XSupport.getDynamicArgs(g[3],target.xroot);
					
					g[3] = (f != null) ?  execFactory(f,target.xroot,g[2].onCompleteArgs, acomplete) : acomplete;
					if(g[2].hasOwnProperty('onUpdate'))
					{
						var onUpdate:Function =  (g[2].onUpdate is Function) ? g[2].onUpdate : XSupport.simpleSourceFinder(target.xroot, g[2].onUpdate) as Function;
						g[2].onUpdate = onUpdate;
						if(g[2].hasOwnProperty('onUpdateArgs'))
							g[2].onUpdateArgs =  XSupport.getDynamicArgs(g[2].onUpdateArgs,target.xroot);
					}
					AO.animate.apply(null, g);
				}
			}
			else if(onComplete != null)
				onComplete();
			function acomplete():void
			{
				if(--atocomplete < 1 && onComplete != null)
					onComplete();
			}
			return 0;
		}
		
		private static function execFactory(f:Object, xrootObject:ixDisplay, args:Array=null, callback:Function=null):Function
		{
			var anonymous:Function = function():void
			{
				var dargs:Array =  XSupport.getDynamicArgs(args, xrootObject) as Array;
				if(!(f is Array))
					f = [f];
				var fl:int = f.length;
				for(var g:int =0; g < fl;g++)
					if(f[g] is Function)
						(args != null) ? f[g].apply(null, dargs) : f[g]();
				if(callback != null)
				{
					callback();
					callback=null
				}
			}
			return anonymous;
		}
		
		public static function valueReadyTypeCoversion(val:String):*
		{
			var ret:*;
			try{ret = JSON.parse(String(val))}
			catch(e:Error) {ret=val}
			return ret;
		}
		
		public static function getTextFieldFromDef(def:XML):xText
		{
			if(def == null)
				return null;
			var tf:xText = new xText(def);
			return tf;
		}
		
		public static function getButtonFromDef(xml:XML, handler:Function,dynamicSourceLoad:Boolean=true,xroot:xRoot=null):xButton
		{
			var btn:xButton = new xButton(xml,xroot);
				btn.onClick = handler;
			if(dynamicSourceLoad)
				checkSource(xml, buttonCallback,true);
			else 
				return buttonCallback();
			function buttonCallback():xButton
			{
				btn.upstate = Ldr.getBitmapCopy(String(xml.@src));
				return btn;
			}
			return btn;
		}
		
		public static function getImageFromDef(xml:XML, dynamicSourceLoad:Boolean=true,xroot:xRoot=null):xBitmap
		{
			var xb:xBitmap = new xBitmap(null,'auto',true,xroot);
			if(dynamicSourceLoad)
				checkSource(xml, imageCallback,true);
			else 
				return imageCallback();
			function imageCallback():xBitmap
			{
				xb.bitmapData = U.getBitmapData(Ldr.getBitmap(String(xml.@src)));
				xb.smoothing = true;
				xb.def = xml;
				return xb;
			}
			return xb;
		}	
		
		public function getSwfFromDef2(xml:XML, dynamicSourceLoad:Boolean=true,xroot:xRoot=null):xSwf
		{
			var spr:xSwf = new xSwf(null,xroot);
			if(dynamicSourceLoad)
				checkSource(xml, swfCallback,true);
			else 
				return swfCallback();
			function swfCallback():xSwf
			{
				spr.addSwf(Ldr.getAny(String(xml.@src)) as DisplayObject);
				pushReadyTypes2(xml, spr);
				spr.def = xml;
				return spr;
			}
			return spr;
		}
		/**
		 * XML tag name <b><code>data</code></b> expects no children.<br>
		 * By attribute "src" allows to load any type of data
		 *  <pre>
		 * &lt;graphics&gt;
		 * 	&lt;command color='0x9bde43' alpha='0.7'&gt;beginFill&lt;/command&gt;
		 * 	&lt;command x='0' y='0' width='148' height='44'&gt;drawRect&lt;/command&gt;
		 * &lt;/graphics&gt;
		 * </pre>
		 * is equivalent of
		 * <pre>
		 * drawable.graphics.beginFill(0x9bde43,0.7);
		 * drawable.graphics.drawRect(0,0,148,44);
		 * </pre> */
		private function getDataFromDef(xml:XML, xroot:xRoot,dynamicSourceLoad:Boolean=true):xObject
		{
			var o:xObject = new xObject(xml, xroot);
			if(dynamicSourceLoad)
				checkSource(xml, objCallback,true);
			else 
				return objCallback();
			function objCallback():xObject
			{
				o.data = Ldr.getAny(String(xml.@src))
				return o;
			}
			return o;
		}
		/**
		 * XML tag name <b><code>graphics</code></b> expects <code>command</code> children only.<br>
		 * Draws on canvas of drawable DisplayObject (if flash.display.graphics Class is in its scope).
		 * Each <code>command</code> node represents one instruction to flash.display.Graphics class instance
		 * where node's value is the name of the class function and node's attrubutes are arguments for that function Eg.
		 *  <pre>
		 * &lt;graphics&gt;
		 * 	&lt;command color='0x9bde43' alpha='0.7'&gt;beginFill&lt;/command&gt;
		 * 	&lt;command x='0' y='0' width='148' height='44'&gt;drawRect&lt;/command&gt;
		 * &lt;/graphics&gt;
		 * </pre>
		 * is equivalent of
		 * <pre>
		 * drawable.graphics.beginFill(0x9bde43,0.7);
		 * drawable.graphics.drawRect(0,0,148,44);
		 * </pre> */
		public static function drawFromDef(def:XML, drawable:Sprite=null):DisplayObject
		{
			if(def == null)
				return null;
			if(drawable == null)
				drawable= new Sprite();
			var commands:XMLList = def.command;
			var command:XML;
			var cl:int = commands.length();
			var vals:Array
			var directive:String;
			for(var c:int = 0; c < cl; c++)
			{
				command = commands[c];
				directive = command.toString();
				var attribs:XMLList = command.attributes();
				var al:int = attribs.length();
				var val:String;
				var key:String;
				vals = [];
				for(var i:int = 0; i < al; i++)
				{
					key = attribs[i].name();
					val = attribs[i].valueOf();
					vals[i] = val;
				}
				drawable.graphics[directive].apply(null, vals);
			}
			//applyAttributes(def, drawable);
			return drawable;
		}
		
		/**
		 * XML tag name <b><code>filters</code></b> expects only <code>filter</code> children.<br>
		 * Returns array of BitmapFilters from XML definiton. 
		 * Name of the BitmapFilter class descendand shoould be specified as "type" attribute Eg.
		 *  <pre>
		 * &lt;filters&gt;
		 *	&lt;filter type="DropShadowFilter" alpha="0.4" angle="45" /&gt;
		 *	&lt;filter type="ColorMatrixFilter" matrix="[0.33,0.33,0.33,0,0,0.33,0.33,0.33,0,0,0.33,0.33,0.33,0,0,0,0,0,1,0]" /&gt;
		 * &lt;/filters&gt;
		 * </pre>
		 */
		public static function filtersFromDef(xml:XML):Array
		{
			var fl:XMLList = xml.filter;
			var len:int = fl.length();
			var ar:Array = [];
			for(var i:int = 0; i < len; i++)
				ar[i] = filterFromDef(fl[i]);
			return ar.length > 0 ? ar : null;
		}
		
		/**
		 * XML tag name <b><code>filter</code></b><br>
		 * Returns BitmapFilter object from XML definiton.
		 * Name of the BitmapFilter class descendand shoould be specified as "type" attribute Eg.
		 *  <pre>&lt;filter type="DropShadowFilter" alpha="0.4" angle="45"/&gt;</pre> */
		public static function filterFromDef(xml:XML):BitmapFilter
		{
			var type:String = 'flash.filters.'+String(xml.@type);
			var Fclass:Class;
			try { Fclass = flash.utils.getDefinitionByName(type) as Class} catch (e:Error) {}
			if(Fclass == null)
				throw new Error("Invalid filter class in definition: " + xml.toXMLString());
			var filter:BitmapFilter = new Fclass();
			
			if(xml.hasOwnProperty('@matrix'))
				filter['matrix'] = JSON.parse(String(xml.@matrix)) as Array;
			else
				applyAttributes(xml, filter);
			return filter;
		}
		
		/**
		 * Returns ColorTransform object from XML definiton Eg.
		 *  <pre>&lt;colorTransform greenOffset="-50" alphaMultiplier="0.4"/&gt;</pre> */
		public static function getColorTransformFromDef(xml:XML):ColorTransform
		{
			var ct:ColorTransform = new ColorTransform();
			applyAttributes(xml, ct);
			return ct;
		}
		
		/** 
		 * Processes children of the XML parent node;
		 * <ul><li>Creates DisplayObjects and DisplayObjectContainers and adds it to the <b>container</b>'s display list</li>
		 * <li>Applies filters and ColorTransforms on <b>container</b></li>
		 * </ul>
		 * @param def - XML node which children are to be parsed
		 * @param container - DisplayObject to process (DisplayObjectContainer for adding children)
		 * @command - for DisplayObjectContainer its typically 'addChild', for axl.ui.Carousel it's 'addToRail'
		 * @xroot - root of all XML based objects (stage equivalent)
		 * */
		public function pushReadyTypes2(def:XML, container:DisplayObject, command:String='addChildAt',xroot:xRoot=null):void
		{
			if(def == null)
				return;
			var celements:XMLList = def.children();
			var type:String;
			var i:int = -1;
			var numC:int = celements.children().length();
			for each(var xml:XML in celements)
				getReadyType2(xml, readyTypeCallback,true, ++i,xroot);
			function readyTypeCallback(v:Object, index:int):void
			{
				if(v != null)
				{
					if(v is Array)
						container.filters = v as Array;
					else if(v is xObject)
						U.log("[XSupport]DataObject registered", v.name);
					else if(v is ColorTransform)
					{
						if(container is ixDisplay)
							container['xtransform'] = v;
						else
							container.transform.colorTransform = v as  ColorTransform;
					}
					else if(command == 'addChildAt' || command == 'addChild')
					{
						if(!(container is DisplayObjectContainer))
							return
						if(command == 'addChildAt' && index < container['numChildren']-1)
							container[command](v, index);
						else
							container['addChild'](v);
					}
					else if(command == 'addToRail')
						container[command](v,false);
					else
						container[command](v);
				}
			}
		}
		/** Loads resource specified as "src" attribute of xml object. Executes callback with xml as attribute.
		 * <ul><li>If xml does not have "src" attribute - callback is executed right away</li>
		 * <li>If resource is already loaded (available <code>Ldr</code> class pool - callback is executed right away</li>
		 * <li>If xml has "src" attribute but <code>dynamicLoad=false</code> - calback is executed right away</li>
		 * <li>If xml has "src" attribute and <code>dynamicLoad=true</code> - callback is executed only when resource is loaded or failed loading.</li>
		 * </ul> */
		private static function checkSource(xml:XML, callBack:Function, dynamicLoad:Boolean=true,sourcePrefixes:Object=null):void
		{
			if(xml.hasOwnProperty('@src'))
			{
				var source:String = String(xml.@src);
				var inLib:Object = Ldr.getAny(source);
				if(inLib != null)
					callBack(xml);
				else if(dynamicLoad)
				{
					Ldr.load(source, function():void{callBack(xml)},null,null,sourcePrefixes);
				}
				else
					callBack(xml);
			}
			else
				callBack(xml);
		}
		/** Translates xml node to an ActionScript object within predefined types and their equivalents:
		 * <ul>
		 * <li><b>img</b> - <code>axl.xdef.xBitmap</code> extends flash Bitmap </li>
		 * <li><b>div</b> - <code>axl.xdef.xSprite</code> - extends flash Sprite </li>
		 * <li><b>txt</b> - <code>axl.xdef.xText</code> - extends flash TextField </li>
		 * <li><b>btn</b> - <code>axl.xdef.xButton</code>- extends xSprite </li>
		 * <li><b>msk</b> - <code>axl.xdef.xMasked</code> - extends xSprite </li>
		 * <li><b>swf</b> - <code>axl.xdef.xSprite</code> - loaded flash DisplayObject is added to xSprite as a child </li>
		 * <li><b>scrollBar</b> - <code>axl.xdef.xScroll</code> - extends xSprite </li>
		 * <li><b>carousel</b> - <code>axl.ui.Carusele</code> extends flash Sprite </li>
		 * </ul>
		 * @param xml - XML object  which tag name matches one of the listed elements.
		 * <br>Attribute <code>src</code> will delay calling callback to the moment resource is available.
		 * Resources are being loaded by <code>axl.utils.Ldr.load()</code> method. If resource is already loaded, and 
		 * available within Ldr.getAny - no reloading is performed and callback called quicker. All Bitmap related
		 * objects requested within this method are being re-drawn from originaly loaded resource (copy).
		 * <br>To avoid duplicating objects use <code>getAdditionByName</code> function, which controlls cache of loaded elements
		 * and groups.
		 * @param callback - function to execute once element is available.
		 * <br> It should accept one parameter - loaded element, or two arguments if <code>callBack2argument</code> is specified.
		 * @param dynamicLoad - if true - checks for attribute <code>src</code> if false - no loading will occur.
		 * @param callBack2argument - optional second argument for callback. It is in use to <code>pushReadyTypes</code> children order.
		 * @see webFlow.MainCallback#getAdditionByName()
		 * */
		public function getReadyType2(xml:XML, callBack:Function, dynamicLoad:Boolean=true,callBack2argument:Object=null,xroot:xRoot=null):void
		{
			if(xml == null)
				throw new Error("Undefined XML definition");
			proxyQueue(proceed);
			function proceed():void
			{
				var type:String = xml.name();
				var obj:Object;
				if(dynamicLoad)
					checkSource(xml, readyTypeCallback, true, xroot ? xroot.sourcePrefixes : null);
				else
					readyTypeCallback();
				function readyTypeCallback():void
				{
					var bmp:Bitmap = xml.hasOwnProperty('@src') ? Ldr.getBitmapCopy(String(xml.@src)) : null;
					switch(type)
					{
						case 'div': obj = new xSprite(xml,xroot); break;
						case 'form': obj = new xForm(xml,xroot); break;
						case 'txt': obj =  new xText(xml,xroot,defaultFont); break;
						case 'scrollBar': obj = new xScroll(xml); break;
						case 'msk': obj = new xMasked(xml,xroot); break;
						case 'carousel' : obj = new xCarousel(xml,xroot); break;
						case 'carouselSelectable' : obj = new xCarouselSelectable(xml,xroot);break;
						case 'filters': obj = filtersFromDef(xml); break;
						case 'img': obj = getImageFromDef(xml,false,xroot); break;
						case 'btn': obj = getButtonFromDef(xml,null,false,xroot); break;
						case 'swf': obj = getSwfFromDef2(xml,xroot); break;
						case 'data' : obj = getDataFromDef(xml,xroot);break;
						case 'colorTransform' : obj = getColorTransformFromDef(xml); break;
						default: 
							if(userTypes[type] is Function)
								obj = userTypes[type](xml,xroot);
							break;
					}
					if(obj is DisplayObjectContainer &&  xml.hasOwnProperty('@src'))
					{
						var n:String = String(xml.@src);
						var b:Object = Ldr.getAny(n); 
						if(b is Bitmap)
							obj.addChildAt(Ldr.getBitmapCopy(n),0);
					}
					if(obj is xSprite)
					{
						pushReadyTypes2(xml, obj as DisplayObjectContainer,'addChild',xroot);
						applyAttributes(xml, obj);
					}
					else if(obj is Carusele)
					{
						XSupport.applyAttributes(xml, obj);
						pushReadyTypes2(xml, obj as DisplayObjectContainer, 'addToRail',xroot);
						Carusele(obj).movementBit(0);
					}
					if(obj != null)
					{
						if(obj.hasOwnProperty('name'))
							smallRegistry[obj.name] = obj;
						if(obj.hasOwnProperty('xroot'))
							obj.xroot = xroot;
					}
					
					// notify
					if(callBack2argument != null)
						callBack(obj, callBack2argument);
					else
						callBack(obj);
					additionQueue.shift();
					if(additionQueue.length > 0)
						additionQueue[0]();
				}
			}
		}
		
		/** Private function to support objects instantiation in order. Hold's delegates 
		 * in <code>additionQueue</code> */
		private static function proxyQueue(call:Function):void
		{
			additionQueue.push(call);
			if(additionQueue.length == 1)
				call();
		}
		
		/** Resolves address/reference string [starting with $ (dolar symbol)] in order to return object. AS3 hierarchy.
		 * @param initSource - first element of the chain from which inner properties are being looked for. Typically your "xroot".
		 * @param s - dot-style address - refference to your object. E.g.:
		 * <br><code> $stage.align.length </code> would return string length of your
		 * stage align mode. <br>Array's and Vector's elements can be accesed by wraping element index with dots. 
		 * <br> E.g. <code>$stage.stageVideos.0.viewPort</code> would return viewPort Rectangle of first stageVideo element if available.
		 * @return <ul><li><code>null</code> if init string is null</li>
		 * <li>Your <code>s:String</code> param if it doesn't start with "$" symbol</li>
		 * <li><code>null</code> and logs SOURCE NOT FOUND if address can not be resolved</li>
		 * <li>referenced object if address is resolved. If referenced object is also a $ reference string - function processes recursively
		 * and returns object from last recursion.
		 * </ul>
		 *  */
		public static function simpleSourceFinder(initSource:Object, s:String):Object
		{
			if(s == null)
				return null;
			//U.log('[XSupport][simpleSourceFinder]', initSource, initSource.hasOwnProperty('name') ? ('['+ initSource.name +']') : '', s);
			var keys:Array;
			if(s.charAt(0) == '$')
				keys= s.substr(1).split('.');
			else
				return s;
			var target:Object = initSource;
			//U.log("KEYS", keys);
			try
			{
				//U.log("KEYS.len", keys.length);
				while(keys.length)
				{
					U.log("trying:", target, '->',  keys[0]);
					target = target[keys.shift()];
				}
			} catch(e:*){target=null, U.log("[XSupport] SOURCE NOT FOUND",s)}
			if(target is String && target.charAt(0) == '$')
				target = simpleSourceFinder(initSource, String(target));
			//U.log("[XSupport][simpleSourceFinder] returning:", target);
			return target;
		}
		
		/** Resolves  reference to object usign ordered address chunks in an array.
		 *  For optimizaiton purposes you may want to keep your address paths already split in array.
		 * @see #simpleSourceFinder() */
		public static function simpleSourceFinderByArray(initSource:Object, xownerArray:Array):Object
		{
			var target:Object = initSource;
			var keys:Array = xownerArray.concat();
			try{
				while(keys.length)
				{
					//U.log("trying:", target, '->',  keys[0]);
					target = target[keys.shift()];
				}
			} catch(e:*){target=null,U.log("[XSupport] SOURCE NOT FOUND",xownerArray)}
			if(target is String && target.charAt(0) == '$')
				target = simpleSourceFinder(initSource, String(target));
			return target;
		}
		
		/**  Resolves one ore more address/reference strings [starting with $ (dolar symbol)] in order to return object. AS3 hierarchy.
		 * @param v - string or array
		 * @param root - initial resource - first element of chain to look from for deeper references.
		 * @return <ul>
		 * <li><code>simpleSourceFinder</code> result if v is String</li>
		 * <li><code>Array</code> of resolved elements accodrding to <code>simpleSourceFinder</code> rules. 
		 * (non-reference array elements remain untouched, reference strings are resolved)</li>
		 * <li>your <code>v</code> parameter if it's neither string nor array</li></ul>
		 * @see #simpleSourceFinder() */
		public static function getDynamicArgs(v:Object,root:Object):Object
		{
			if(v is String && v.charAt(0) == '$' )
				return simpleSourceFinder(root, String(v));
			if(v is Array)
			{
				var a:Array = v.concat();
				for(var i:int = a.length; i-->0;)
				{
					var o:Object = a[i];
					a[i] = (o is String && o.charAt(0) == '$') ? XSupport.simpleSourceFinder(root, String(o)) : o;
				}
				return a;
			}
			else
				return v;
		}
	}
}
