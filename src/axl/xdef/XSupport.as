/**
 *
 * AXLX Framework
 * Copyright 2014-2015 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
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
	import axl.xdef.types.xActionSet;
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
	
	/** Factory class for XML defined elements.<br>
	 * <ul>
	 * <li> Creates, registers, decorates and animates all objects</li>
	 * <li> Allows to extend functionality by registering user defined elements.</li>
	 * <li> Provides set of utility functions to work with xml nodes / xml defined objects.</li>
	 * </ul>
	 * */
	public class XSupport
	{
		private static var additionQueue:Vector.<Function> = new Vector.<Function>();
		private static var userTypes:Object={};
			
		private var smallRegistry:Object={};
		/** Default font to apply on xText if <code>font</code> attribute is not specifed @see axl.xdef.types.xText */
		public var defaultFont:String;
		/** @see axl.xdef.types.xRoot */
		public var root:xRoot;
		/** Object that contains references to all instantiated and <b>uniquely</b> named objects 
		 * created within <code>getReadyType</code> method (all auto xml additions and executions).
		 * <br>Object without name property defined are not registered.
		 * <br>Multiple object registered under the same name will cause registry to return only the 
		 * most recent ones*/
		public function get registry():Object { return smallRegistry }
		/** @param v - name of the object (xml "name" attribute) @see #registry() */
		public function registered(v:String):Object { return smallRegistry[v] }
		
		/** Factory class for XML defined elements.<br>
		 * <ul>
		 * <li> Creates, registers, decorates and animates all objects</li>
		 * <li> Allows to extend functionality by registering user defined elements.</li>
		 * <li> Provides set of utility functions to work with xml nodes / xml defined objects.</li>
		 * </ul>
		 * */
		public function XSupport()
		{
		}
		public static function registerUserType(xmlTagName:String, instantiator:Function):void { userTypes[xmlTagName] = instantiator }
		/** 
		 * Maps XML attributes to <code><b>target</b></code> properties.
		 * If target (any object) does not own property specified as attribute in XML definition,
		 * then property is not assigned.
		 * If it does, value of attribute is *parsed* and assigned to the target's property.
		 * If object is dynamic and property of given attribute name does not exist, new property on target
		 * <b>is not created</b>.
		 * Parsing attribute values is proceed by <code>resolveValue</code> function
		 * The order of the attributes matters - they're being processed from left to right.<br>
		 * Attributes can reffer to object's deeper properties.
		 * @see #resolveValue()
		 * */
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
				val = resolveValue(val,target);
				if(key in deepTarget)
				{
					//U.log('[applyAttributes]', target, target.hasOwnProperty('name') ? target.name : '','applying', key, '<==', val, '\t from', attribs[i].valueOf());
					deepTarget[key] = val;
				}
				else
				{
					//U.log('[applyAttributes]',target, target.hasOwnProperty('name') ? target.name : '','does not have ', key, 'property. Value', val, '\t from', attribs[i].valueOf(), 'not assigned');
				}
			}
			return target;
		}
		/**
		 * Generally all XML attribute values are recoginzed as String values (ActionScript),<br>
		 * and this is an ultimate value returned <b>IF</b> parsing fails.<br>
		 * There are two ways of parsing <code>val</code> available:
		 * <ul>
		 * <li><b>dolar sign prefixed parsing</b> - value is evaluated by 
		 * <code>axl.utils.RootFinder.parseInput</code> method</li>
		 * <li><b>JSON parsing</b> - value assigned to a target is an output of JSON.parse on attribute value </li>
		 * </ul>
		 * <pre>
		 * &lt;div name='sample' x='10' y='$stage.stageHeight/2' mouseChildren='false'/>
		 * </pre>
		 * is equivalent of
		 * <pre>
		 * var any:xSprite = new xSprite()
		 * any.name = 'sample';
		 * any.x = 10;
		 * any.u = stage.stageHeight/2;
		 * any.mouseChildren = false;
		 * </pre>
		 * @see #valueReadyTypeCoversion()
		 * @see axl.utils.binAgent.RootFinder#parseInput()
		 * */
		public static function resolveValue(val:String, target:Object=null):*
		{
			var output:*;
			if(val.charAt(0) == '$' && target && target.hasOwnProperty('xroot') && target.xroot != null )
			{
				//U.log("[resolveValue][", target.hasOwnProperty('name') ? target.name : null, target,']:', val);
				output = target.xroot.binCommand(val.substr(1));
				//U.log(target, target.hasOwnProperty('name') ? target.name : '','applying', key, '<==', val, '\t from', attribs[i].valueOf());
			}
			else
				output = valueReadyTypeCoversion(val);
			//U.log("[resolveValue]["+val+"]:", output);
			return output;
		}
		/** Executes animation on <code>meta[animName]</code> owners. Lenient.
		 * General format of an animation is an array of arguments for <code>axl.utils.AO.animate</code>
		 * function with difference that first parameter (target) is ommited, as it is passed to this function
		 * directly. Following example is the shortest example of animating object from whichever position to x 10 in 0.3sec every
		 * time object is added to stage.
		 * <pre>
		 * &lt;div name='a' meta='{addedToStage:[0.3,{"x":10}]}'/>
		 * </pre>
		 * <br> Mapped properties of inner animation object: onUpdate, onUpdateArgs
		 * @param target - object to animate and look <code>meta[animName]</code> for
		 * @param animName - animation key/identifier
		 * @param onComplete - callback to execute once animation is completd
		 * @param killCurrent - kills ANY existing animations proceeding on <code>target</code> befeore executing this one
		 * @param reset can execute ixDef <code>reset</code> interface function before animation
		 * @see axl.utils.AO#animate() 
		 * @see axl.xdef.interfaces.ixDef#reset() */
		public static function animByNameExtra(target:ixDef, animName:String, onComplete:Function=null, killCurrent:Boolean=true,reset:Boolean=false):uint
		{
			if(target.meta.hasOwnProperty(animName))
			{
				if(reset)
					target.reset();
				else if(killCurrent)
					AO.killOff(target);
				
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
		/** used for onComplete + onCompleteArgs animByNameExtra args
		 * @see #animByNameExtra() */
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
				}
			}
			return anonymous;
		}
		/** Parses String via JSON parse method, returns its result if successful 
		 * or back input <code>val</code> if it failed @see JSON#parse() */
		public static function valueReadyTypeCoversion(val:String):*
		{
			var ret:*;
			try{ret = JSON.parse(String(val))}
			catch(e:Error) {ret=val}
			return ret;
		}
		
		/**
		 * XML tag name <b><code>txt</code></b> can't contain any children<br>
		 * Allows to instantiate <code>axl.xdef.types.xText</code> which is descendandt of merged flash TextField and 
		 * TextFormat classes.
		 * If <code>html</code> flag is set to true, you may need to wrap contents inside CDATA block in order to use html tags.
		 * <pre>
		 * &lt;txt name='btnTerms' embedFonts='true' multiline='true' html='true'>Terms&lt;br>and&lt;br>Conditions>&lt;/txt>
		 * </pre>
		 * If fontName is not set, related xsupport instance default font is applied.
		 * @see axl.xdef.types.xText
		 * */
		public static function getTextFieldFromDef(def:XML):xText
		{
			if(def == null)
				return null;
			var tf:xText = new xText(def);
			return tf;
		}
		
		/**
		 * XML tag name <b><code>btn</code></b> can contain children<br>
		 * Allows to instantiate <code>axl.xdef.types.xButton</code>. 
		 * Buttons as a common use-case can have no <code>src</code> attribute no <code>graphics</code>nodes defined
		 *  and still be valid and handy action holders.
		 * <pre>
		 * &lt;btn name='COMPLETE' meta='{"action":[{"type":"rmv","value":"anything"},{"type":"add","value":"anything2"}]}'/>
		 * &lt;img name='1' src='1.jpg' meta='{"addedToStage":[25,{"y":500},"$registry.COMPLETE.execute"]}'/>
		 * </pre>
		 * @see axl.xdef.types.xButton
		 * */
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
		
		/**
		 * XML tag name <b><code>img</code></b> can contain children<br>
		 * Allows to instantiate <code>axl.xdef.types.xBitmap</code> class whcich is equivalent of regular flash Bitmap.
		 * Method returns xBitmap instance immediately but actual drawing into it is done when available. 
		 * Displaying more than one image of the same src does not cause subsequent loadings.
		 * Once bitmap source is loaded, all other requests to that source are being re-drawn (copy) from root one.
		 * <pre>
		 *	&lt;img name='tick1'  x='5' src='../tick.png'/>
		 *	&lt;img name='tick2' x='10'  src='../tick.png'/>
		 *	&lt;img name='tick3' x='15' src='../tick.png'/>
		 *	&lt;img name='tick4' x='20' src='../tick.png'/>
		 *	&lt;img name='tick5' x='25' src='../tick.png'/>
		 * </pre>
		 * This will display five differently positioned Bitmaps. Loading of tick.png occures just once. 
		 * @see axl.xdef.types.xBitmap
		 * */
		public static function getImageFromDef(xml:XML, dynamicSourceLoad:Boolean=true,xroot:xRoot=null):xBitmap
		{
			var xb:xBitmap = new xBitmap(null,'auto',true,xroot,xml);
			if(dynamicSourceLoad)
				checkSource(xml, imageCallback,true);
			else
				return imageCallback();
			function imageCallback():xBitmap
			{
				xb.bitmapData = U.getBitmapData(Ldr.getBitmap(String(xml.@src)));
				xb.smoothing = true;
				return xb;
			}
			return xb;
		}	
		/**
		 * XML tag name <b><code>swf</code></b> can contain children<br>
		 * Allows to instantiate <code>axl.xdef.types.xSwf</code> class whcich supports controlling MovieClips.
		 * Method returns xSwf instance immediately but actual swf is being added once loaded.
		 * <pre>
		 *&lt;swf name='animation src='../anim.swf' addStarts='true' stopOnEnd='true' />;
		 * </pre>
		 * @see axl.xdef.types.xSwf
		 * */
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
				spr.def = xml;
				return spr;
			}
			return spr;
		}
		/**
		 * XML tag name <b><code>data</code></b> expects no children.<br>
		 * By attribute "src" allows to load any type of data - XML, JSON, MP3, JPG, PNG, SWF, other.<br>
		 * Loaded data is attempted to turn it to usable type (according to <code>axl.utils.Ldr</code>)
		 * and asigned to <code>data</code> property of freshly instantiated <code><b>xObject</b></code> .
		 *<pre>
		 *&lt;data name='myMp3 src='../audio.mp3'/>;
		 * </pre>
		 * Can be then refferenced
		 * <pre>
		 * &lt;btn name='btnPlay meta='{"action":[{"type":"binCommand","value":"registry.myMp3.data.play()"}]}'/>
		 * </pre> 
		 * @see axl.xdef.types.xObject
		 * @see axl.utils.Ldr
		 * */
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
		 * </pre> 
		 * <strong>Attribute names are not important, unlike it's order.</strong>
		 * */
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
				var val:*;
				var key:String;
				vals = [];
				for(var i:int = 0; i < al; i++)
				{
					key = attribs[i].name();
					val = resolveValue(attribs[i].valueOf(), drawable);
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
		
		/** XML tag name <b><code>act</code></b> expects no children.<br>
		 * Returns lightweight, non-displayable Function equivalent, ready to call "execute" on
		 * @see axl.xdef.xtypes.xActionSet
		 * @see axl.xdef.xtypes.xAction */
		private function getActionFromDef(xml:XML, xroot:xRoot):xActionSet
		{
			return new xActionSet(xml,xroot);
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
		 * @param command - for DisplayObjectContainer its typically 'addChild', for axl.ui.Carousel it's 'addToRail'
		 * @param xroot - root of all XML based objects (stage equivalent)
		 * @see #getReadyType2()
		 * */
		public function pushReadyTypes2(def:XML, container:DisplayObject, command:String='addChildAt',xroot:xRoot=null,onChildrenCreated:Function=null):void
		{
			
			if(def == null)
			{
				 finishPushing();
				 return
			}
			var celements:XMLList = def.children();
			var type:String;
			var i:int = -1;
			var numC:int = celements.length();
			//U.log('[XSupport]'+container+'[' + container.name + '][pushReadyTypes2] PUSHING:',numC, "children");
			if(numC < 1)
			{
				finishPushing();
				return;
			}
			for each(var xml:XML in celements)
			{
				//U.log('[XSupport]'+container+'[' + container.name + '][pushReadyTypes2] pushing', xml.@name, 'now');
				getReadyType2(xml, readyTypeCallback,true, ++i,xroot);
			}
			function readyTypeCallback(v:Object, index:int):void
			{
				numC-=1;
				//U.log('[XSupport]'+container+'[' + container.name + '][pushReadyTypes2]',numC);
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
						if(!(container is DisplayObjectContainer) || !(v is DisplayObject))
						{
							finishPushing();
							return;
						}
						if(command == 'addChildAt' && index < container['numChildren']-1)
							container[command](v, index);
						else
							container['addChild'](v);
					}
					else if(command == 'addToRail')
					{
						container[command](v,false);
					}
					else
						container[command](v);
				}
				finishPushing();
			}
			function finishPushing():void
			{
				if(numC != 0)
					return
				if(container && container.hasOwnProperty('onChildrenCreated') && container['onChildrenCreated'] is Function)
					container['onChildrenCreated']();
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
		 * <li><b>img</b> - <code>axl.xdef.types.xBitmap</code> extends flash Bitmap </li>
		 * <li><b>div</b> - <code>axl.xdef.types.xSprite</code> - extends flash Sprite </li>
		 * <li><b>txt</b> - <code>axl.xdef.types.xText</code> - extends flash TextField </li>
		 * <li><b>btn</b> - <code>axl.xdef.types.xButton</code>- extends xSprite </li>
		 * <li><b>msk</b> - <code>axl.xdef.types.xMasked</code> - extends xSprite </li>
		 * <li><b>swf</b> - <code>axl.xdef.types.xSwf</code> - loaded flash DisplayObject is added to xSwf as a child</li>
		 * <li><b>data</b> - <code>axl.xdef.types.xObject</code> - loaded data is being analyzed and can be instantiated as XML 
		 * ('xml'), Object ('json'), Sound ('mp3','mpeg'), DisplayObject ('jpg','png','gif','swf') or raw data (ByteArray, String). 
		 * Regardles of it's contents, instantiated axl.xdef.types.xObject assigns the result to it's own <code> data </code> property.</li>
		 * <li><b>scrollBar</b> - <code>axl.xdef.types.xScroll</code> - extends xSprite </li>
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
			//U.log("OBJECT REQUEST", xml.name(), xml.@name);
			proxyQueue(proceed);
			function proceed():void
			{
				//U.log("OBJECT PROCEED", xml.name(), xml.@name);
				var type:String = xml.name();
				var obj:Object;
				if(dynamicLoad)
					checkSource(xml, readyTypeCallback, true, xroot ? xroot.sourcePrefixes : null);
				else
					readyTypeCallback();
				function readyTypeCallback():void
				{
					var bmp:Bitmap = xml.hasOwnProperty('@src') ? Ldr.getBitmapCopy(String(xml.@src)) : null;
					//U.log("OBJECT BUILD", type, xml.@name);
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
						case 'swf': obj = getSwfFromDef2(xml,false,xroot); break;
						case 'data' : obj = getDataFromDef(xml,xroot);break;
						case 'act' : obj = getActionFromDef(xml,xroot);break;
						case 'colorTransform' : obj = getColorTransformFromDef(xml); break;
						default: 
							if(userTypes[type] is Function)
								obj = userTypes[type](xml,xroot);
							break;
					}
					if(obj != null)
					{
						if(obj.hasOwnProperty('name') && xml.hasOwnProperty('@name'))
						{
							obj.name = String(xml.@name);
							smallRegistry[obj.name] = obj;
						}
						if(obj.hasOwnProperty('xroot'))
							obj.xroot = xroot;
					}
					
					if(obj is DisplayObjectContainer &&  xml.hasOwnProperty('@src'))
					{
						var n:String = String(xml.@src);
						var b:Object = Ldr.getAny(n); 
						if(b is Bitmap)
							obj.addChildAt(Ldr.getBitmapCopy(n),0);
					}
					applyAttributes(xml, obj);
					
					if(obj is xSprite)
					{
						pushReadyTypes2(xml, obj as DisplayObjectContainer,'addChild',xroot);
					}
					else if(obj is Carusele)
					{
						pushReadyTypes2(xml, obj as DisplayObjectContainer, 'addToRail',xroot);
						Carusele(obj).movementBit(0);
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
		private static function proxyQueue(qcall:Function):void
		{
			additionQueue.push(qcall);
			if(additionQueue.length == 1)
				qcall();
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
		 * and returns object from last recursion.</li>
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
					//U.log("trying:", target, '->',  keys[0]);
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
