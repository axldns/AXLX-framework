package axl.xdef
{
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.filters.BitmapFilter;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.ColorTransform;
	import flash.utils.getDefinitionByName;
	import flash.utils.setInterval;
	
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
	import axl.xdef.types.xRoot;
	import axl.xdef.types.xScroll;
	import axl.xdef.types.xSprite;
	import axl.xdef.types.xSwf;
	import axl.xdef.types.xText;

	public class XSupport
	{
		private static var ver:Number = 0.95;
		public static function get version():Number { return ver}
		
		private static var additionQueue:Vector.<Function> = new Vector.<Function>();
		private static var afterQueueVec:Vector.<Function> = new Vector.<Function>();
		
		private var smallRegistry:Object={};
		public var defaultFont:String;
		public var root:xRoot;
		
		public function get registry():Object { return smallRegistry }
		public function registered(v:String):Object { return smallRegistry[v] }
		
		public function XSupport()
		{
		}
		
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
				val = valueReadyTypeCoversion(val);
				if(key in deepTarget)
					deepTarget[key] = val;
			}
			if(def.hasOwnProperty('@meta') && target.hasOwnProperty('meta'))
			{
				try{target.meta = JSON.parse(String(target.meta))}
				catch(e:Error) {throw new Error("Invalid json for element " + target + " of definition: " + def.toXMLString()  + '\nDETAILS:\n' + e + '\n '+ e.message); }
			}
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
					if(f != null)
					{
						U.log('[XSupport] function to execute on complete]', f);
						g[3] = execFactory(f,target.xroot,g[2].onCompleteArgs, acomplete)
					}
					else
						g[3] = acomplete;
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
			switch(val)
			{
				case 'null': return null;
				case 'true': return true;
				case 'false': return false;
			}
			return val;
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
			applyAttributes(def, drawable);
			return drawable;
		}
		
		public static function filtersFromDef(xml:XML):Array
		{
			var fl:XMLList = xml.filter;
			var len:int = fl.length();
			var ar:Array = [];
			for(var i:int = 0; i < len; i++)
				ar[i] = filterFromDef(fl[i]);
			return ar.length > 0 ? ar : null;
		}
		
		public static function filterFromDef(xml:XML):BitmapFilter
		{
			var type:String = 'flash.filters.'+String(xml.@type);
			var Fclass:Class;
			try { Fclass = flash.utils.getDefinitionByName(type) as Class} catch (e:Error) {}
			if(Fclass == null)
				throw new Error("Invalid filter class in definition: " + xml.toXMLString());
			var filter:BitmapFilter = new Fclass();
			
			if(filter is ColorMatrixFilter && xml.hasOwnProperty('@matrix'))
				ColorMatrixFilter(filter).matrix = JSON.parse(String(xml.@matrix)) as Array;
			else
				applyAttributes(xml, filter);
			return filter;
		}
		
		public static function getColorTransformFromDef(xml:XML):ColorTransform
		{
			var ct:ColorTransform = new ColorTransform();
			applyAttributes(xml, ct);
			return ct;
		}
		
		
		public function pushReadyTypes2(def:XML, container:DisplayObjectContainer, command:String='addChildAt',xroot:xRoot=null):void
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
					else if(v is ColorTransform)
					{
						if(container is ixDisplay)
							container['xtransform'] = v;
						else
							container.transform.colorTransform = v as  ColorTransform;
					}
					else if(command == 'addChildAt')
					{
						if(index < container.numChildren-1)
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
					var bmp:Bitmap;
					switch(type)
					{
						case 'div': obj = new xSprite(xml,xroot);
							if(xml.hasOwnProperty('@src'))
							{
								bmp = Ldr.getBitmapCopy(String(xml.@src));
								if(bmp != null)
									obj.addChildAt(bmp, 0);
							}
							break;
						case 'form': obj = new xForm(xml,xroot);
							if(xml.hasOwnProperty('@src'))
							{
								bmp = Ldr.getBitmapCopy(String(xml.@src));
								if(bmp != null)
									obj.addChildAt(bmp, 0);
							}
							break;
						/*case 'car' : obj = new xCarouselExt(xml,xroot);
							if(xml.hasOwnProperty('@src'))
								obj.addChildAt(Ldr.getBitmapCopy(String(xml.@src)), 0);*/
							break;
						case 'txt': obj =  new xText(xml,xroot,defaultFont);	break;
						case 'scrollBar': obj = new xScroll(xml); break;
						case 'msk': obj = new xMasked(xml,xroot);
							if(xml.hasOwnProperty('@src'))
							{
								bmp = Ldr.getBitmapCopy(String(xml.@src));
								if(bmp != null)
									obj.addChildAt(bmp, 0);
							}
							break;
						case 'carousel' : obj = new xCarousel(xml,xroot);
							if(xml.hasOwnProperty('@src'))
							{
								bmp = Ldr.getBitmapCopy(String(xml.@src));
								if(bmp != null)
									obj.addChildAt(bmp, 0);
							}
							break;
						case 'carouselSelectable' : obj = new xCarouselSelectable(xml,xroot);
							if(xml.hasOwnProperty('@src'))
							{
								bmp = Ldr.getBitmapCopy(String(xml.@src));
								if(bmp != null)
									obj.addChildAt(bmp, 0);
							}
							break;
						case 'filters': obj = filtersFromDef(xml); break;
						//--- loadable
						case 'img': obj = getImageFromDef(xml,false,xroot); break;
						case 'btn': obj = getButtonFromDef(xml,null,false,xroot); break;
						case 'swf': obj = getSwfFromDef2(xml,xroot); break;
						case 'colorTransform' : obj = getColorTransformFromDef(xml)
						default : break;
					}
					if(obj is xSprite)
					{
						pushReadyTypes2(xml, obj as DisplayObjectContainer,'addChildAt',xroot);
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
					else
					{
						while(afterQueueVec.length > 0)
							afterQueueVec.shift()();
					}
				}
			}
		}
		
		private static function proxyQueue(call:Function):void
		{
			additionQueue.push(call);
			if(additionQueue.length == 1)
				call();
		}
		
		private static function afterQueue(callback:Function):void
		{
			if(callback == null)
				return;
			if(additionQueue.length < 1)
				callback();	
			else
				afterQueueVec.push(callback);
		}
		
		public static function simpleSourceFinder(initSource:Object, s:String):Object
		{
			var keys:Array = s.split('.');
			var target:Object = initSource;
			try
			{
				while(keys.length)
				{
					target = target[keys.shift()];
				}
			} catch(e:*){target=null, U.log("SOURCE NOT FOUND")}
			if(target is String && target.charAt(0) == '$')
				target = simpleSourceFinder(initSource, target as String);
			return target;
		}
		
		public static function simpleSourceFinderByArray(initSource:Object, xownerArray:Array):Object
		{
			var target:Object = initSource;
			var keys:Array = xownerArray.concat();
			try{
				while(keys.length)
				{
					U.log("trying", target, '->', keys[0]);
					target = target[keys.shift()];
				}
			} catch(e:*){target=null}
			return target;
		}
		
		/** Resolves $string to find dynamic args. If it's an array - creates a copy of that array! !*/
		public static function getDynamicArgs(v:Object,root:ixDef):Object
		{
			if(v is String && v.charAt(0) == '$' )
				return simpleSourceFinder(root, v.substr(1));
			if(v is Array)
			{
				var a:Array = v.concat();
				for(var i:int = a.length; i-->0;)
				{
					var o:Object = a[i];
					a[i] = (o is String && o.charAt(0) == '$') ? XSupport.simpleSourceFinder(root, o.substr(1)) : o;
				}
				return a;
			}
			else
				return v;
		}
	}
}
