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
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.filters.BitmapFilter;
	import flash.geom.ColorTransform;
	import flash.utils.getDefinitionByName;
	
	import axl.utils.AO;
	import axl.utils.Ldr;
	import axl.utils.U;
	import axl.xdef.interfaces.ixDef;
	import axl.xdef.interfaces.ixDisplay;
	import axl.xdef.interfaces.ixDisplayContainer;
	import axl.xdef.types.xAction;
	import axl.xdef.types.xObject;
	import axl.xdef.types.xScript;
	import axl.xdef.types.xTimer;
	import axl.xdef.types.display.xBitmap;
	import axl.xdef.types.display.xButton;
	import axl.xdef.types.display.xCarousel;
	import axl.xdef.types.display.xCarouselSelectable;
	import axl.xdef.types.display.xForm;
	import axl.xdef.types.display.xMasked;
	import axl.xdef.types.display.xRoot;
	import axl.xdef.types.display.xScroll;
	import axl.xdef.types.display.xSprite;
	import axl.xdef.types.display.xSwf;
	import axl.xdef.types.display.xText;
	import axl.xdef.types.display.xVOD;

	/** Factory and decorator class for XML defined elements.<br>
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
		/** @see axl.xdef.types.display.xRoot */
		public var root:xRoot;
		private static var reservedAttributes:Array = ['src'];
		/** Object that contains references to all instantiated and <b>uniquely</b> named objects 
		 * created within <code>getReadyType</code> method (all auto xml additions and executions).
		 * <br>Object without name property defined are not registered.
		 * <br>Multiple object registered under the same name will cause registry to return only the 
		 * most recent ones*/
		public function get registry():Object { return smallRegistry }
		
		/** Factory and decorator class for XML defined elements.<br>
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
				if(reservedAttributes.indexOf(key) > -1)
					continue;
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
				output = target.xroot.binCommand(val.substr(1),target);
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
		public static function animByNameExtra(target:ixDef, animName:String, onComplete:Object=null, killCurrent:Boolean=true,reset:Boolean=false,doNotDisturb:Boolean=false):int
		{
			if(target.meta && target.meta.hasOwnProperty(animName))
			{
				if(doNotDisturb && AO.contains(target))
					return 0;
				if(reset)
					target.reset();
				if(killCurrent)
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
					//assemble
					var g:Array = [target].concat(ag[i]);
					//dynamic properties
					if(g[2] is String && g[2].charAt(0) == "$")
						g[2] = target.xroot.binCommand(g[2].substr(1),target);
					//on complete
					var f:Object = g[3];
					if(f is String && f.charAt(0) == "$")
						f = target.xroot.binCommand(f.substr(1),target);
					
					if(f is String)
						g[3] = delayedBinCommand(f,target, groupCallback);
					else if (f is Function)
						g[3] = delayedComplete(f as Function,target,groupCallback,g[2].onCompleteArgs);
					else
						g[3] = groupCallback;
					//proceed
					AO.animate.apply(null, g);
				}
			}
			if(ag.length < 1)
				groupCallback();
			function groupCallback():void
			{
				if(--atocomplete < 1 && onComplete != null)
				{
					if(onComplete is String)
						target.xroot.binCommand(onComplete,target);
					if(onComplete is Function)
						onComplete();
				}
			}
			return 0;
		}
		
		private static function delayedComplete(f:Function, target:ixDef, groupCallback:Function,onCompleteArgs:Object=null):Function
		{
			var delayed:Function = function():void
			{
				f.apply(null, onCompleteArgs);
				groupCallback();
			}
			return delayed;
		}
		
		private static function delayedBinCommand(f:Object, target:ixDef, groupCallback:Function):Function
		{
			var delayed:Function = function():void
			{
				target.xroot.binCommand(f,target);
				groupCallback();
			}
			return delayed;
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
		 * @param decorator - Function that each and every instantiated object (all descendands) will be passed to as an argument
		 * @param xroot - root of all XML based objects (stage equivalent)
		 * @see #getReadyType2()
		 * */
		public function pushReadyTypes2(def:XML, container:Object, decorator:Function=null,xroot:xRoot=null):void
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
				getReadyType2(xml, readyTypeCallback,decorator,++i,xroot);
			}
			function readyTypeCallback(v:Object, index:int):void
			{
				numC-=1;
				if(v != null)
				{
					if(v is Array)
						container.filters = v as Array;
					else if(v is xObject)
					{
						U.log("[XSupport]DataObject registered", v.name);
						xObject(v).parent = container;
					}
					else if(v is ColorTransform)
					{
						container.transform.colorTransform = v as  ColorTransform;
					}
					else
					{
						if(!(container is DisplayObjectContainer) || !(v is DisplayObject))
						{
							finishPushing();
							return;
						}
						if(index < container['numChildren']-1)
							container['addChildAt'](v, index);
						else
							container['addChild'](v);
					}
					
				}
				finishPushing();
			}
			function finishPushing():void
			{
				if(numC != 0)
					return;
				var cont:ixDisplayContainer = container as ixDisplayContainer;
				if(cont == null) return;
				if(cont['debug'])
					xroot.log("Children created for", container.name);
				if(cont.onChildrenCreated is Function)
					cont.onChildrenCreated();
				else if(cont.onChildrenCreated is String)
					xroot.binCommand(cont.onChildrenCreated,cont);
			}
		}
		/** Loads resource specified as "src" attribute of xml object. Executes callback with xml as attribute.
		 * <ul><li>If xml does not have "src" attribute - callback is executed right away</li>
		 * <li>If resource is already loaded (available <code>Ldr</code> class pool - callback is executed right away</li>
		 * </ul> */
		private static function checkSource(xml:XML, callBack:Function,sourcePrefixes:Object=null,overwriteInLib:Boolean=false,xroot:xRoot=null):void
		{
			if(xml.hasOwnProperty('@src'))
			{
				//U.log(xml.@name, "HAS SOURCE")
				var source:String = String(xml.@src);
				while(source.charAt(0) == '$' && xroot != null)
				{
					source = String(xroot.binCommand(source.substr(1),xroot,2));
				}
				var inLib:Object = Ldr.getAny(source);
				if((inLib != null) && (overwriteInLib == false))
				{
					//U.log('[CHECK SOURCE]', xml.@name, xml.@src, "ALREADY IN LIBRARY");
					callBack(source);
				}
				else
				{
					if(xml.hasOwnProperty('@cachebust') && xml.@cachebust != 'false')
						source = source + (source.indexOf('?') > -1 ? "&" : "?") + "cachebust=" + String(new Date().time); 
					Ldr.load(source, function():void{callBack(source)},null,null,sourcePrefixes, overwriteInLib ? Ldr.behaviours.loadOverwrite : Ldr.behaviours.loadSkip);
				}
			}
			else
				callBack(null);
		}
		/** Translates xml node to an ActionScript object within predefined types and their equivalents:
		 * <ul>
		 * <li><b>img</b> - <code>axl.xdef.types.display.xBitmap</code> extends flash Bitmap </li>
		 * <li><b>div</b> - <code>axl.xdef.types.display.xSprite</code> - extends flash Sprite </li>
		 * <li><b>txt</b> - <code>axl.xdef.types.display.xText</code> - extends flash TextField </li>
		 * <li><b>btn</b> - <code>axl.xdef.types.display.xButton</code>- extends xSprite </li>
		 * <li><b>act</b> - <code>axl.xdef.types.xAction</code>- function equivalent - lightweight code container </li>
		 * <li><b>msk</b> - <code>axl.xdef.types.display.xMasked</code> - extends xSprite </li>
		 * <li><b>swf</b> - <code>axl.xdef.types.display.xSwf</code> - loaded flash DisplayObject is added to xSwf as a child</li>
		 * <li><b>data</b> - <code>axl.xdef.types.xObject</code> - loaded data is being analyzed and can be instantiated as XML 
		 * ('xml'), Object ('json'), Sound ('mp3','mpeg'), DisplayObject ('jpg','png','gif','swf') or raw data (ByteArray, String). 
		 * Regardles of it's contents, instantiated axl.xdef.types.xObject assigns the result to it's own <code> data </code> property.</li>
		 * <li><b>scrollBar</b> - <code>axl.xdef.types.display.xScroll</code> - extends xSprite </li>
		 * <li><b>carousel</b> - <code>axl.ui.Carusele</code> extends flash Sprite </li>
		 * <li><b>script</b> - <code>axl.xdef.xScript</code> extends xObject - allows to load and merge external config files</li>
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
		 * @param decorator - Function that each and every instantiated object (all descendands) will be passed to as an argument
		 * @param callBack2argument - optional second argument for callback. It is in use to <code>pushReadyTypes</code> children order.
		 * @param xroot - xRoot reference that result of this function will belong to
		 * @see axl.xdef.types.display.xRoot#getAdditionByName()
		 * */
		public function getReadyType2(xml:XML,callBack:Function=null,decorator:Function=null,callBack2argument:Object=null,xroot:xRoot=null):void
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
				checkSource(xml, readyTypeCallback, xroot ? xroot.sourcePrefixes : null, xml.hasOwnProperty('@forceReload'),xroot) ;
				
				function readyTypeCallback(sourceTest:String=null):void
				{
					//U.log("OBJECT BUILD", type, xml.@name, sourceTest);
					// INSTANTIATION
					switch(type)
					{
						case 'div': obj = new xSprite(xml,xroot); break;
						case 'form': obj = new xForm(xml,xroot); break;
						case 'txt': obj =  new xText(xml,xroot); break;
						case 'scrollBar': obj = new xScroll(xml,xroot); break;
						case 'msk': obj = new xMasked(xml,xroot); break;
						case 'btn': obj = new xButton(xml,xroot); break;
						case 'data' : obj = new xObject(xml, xroot);break;
						case 'img': obj = new xBitmap(null,'auto',true,xroot,xml); break;
						case 'carousel' : obj = new xCarousel(xml,xroot); break;
						case 'carouselSelectable' : obj = new xCarouselSelectable(xml,xroot);break;
						case 'swf': obj = new xSwf(null,xroot); break;
						case 'act' : obj = new xAction(xml,xroot);break;
						case 'filters': obj = filtersFromDef(xml); break;
						case 'colorTransform' : obj = getColorTransformFromDef(xml); break;
						case 'script': obj = new xScript(xml,xroot); break;
						case 'vod' : obj = new xVOD(xml,xroot); break;
						case 'timer' : obj = new xTimer(xml,xroot); break;
						default: 
							if(userTypes[type] is Function)
								obj = userTypes[type](xml,xroot);
							break;
					}
					if(obj != null)
					{
						//objects suppose to add themselves to registry inside constructor function
					// ATTACHING SRC
						if(sourceTest != null)
						{
							var b:Object = Ldr.getAny(sourceTest); 
							
							if(obj is DisplayObjectContainer)
							{
								if(b is Bitmap)
									obj.addChildAt(Ldr.getBitmapCopy(sourceTest),0);
								else if(b is DisplayObject)
									obj.addChildAt(b as DisplayObject,0);
							}
							else if(obj is Bitmap)
							{
								obj.bitmapData = U.getBitmapData(Ldr.getBitmap(sourceTest));
								obj.smoothing = true;
							}
							else if(obj is xObject)
							{
								obj.data = b;
							}
						}
						
						//APPLYING ATTRIBUTES 1
						applyAttributes(xml, obj);
						// decorating parent and children by the same decorator
						if(decorator != null && obj is ixDef)
							decorator(obj);
						if(obj is xScript && obj.autoInclude)
							obj.includeScript();
						//code inject
						if(obj.hasOwnProperty("inject") && obj.inject != null)
						{
							xroot.binCommand(obj.inject, obj);
						}
						// PUSHING CHILDREN
						pushReadyTypes2(xml, obj as DisplayObject,decorator,xroot);
					}
					
					// notify
					if(callBack2argument != null)
						callBack(obj, callBack2argument);
					else if (callBack != null)
						callBack(obj);
					additionQueue.shift();
					if(additionQueue.length > 0)
						additionQueue[0]();
				}
			}
		}
		/** Registers any ixDef implementator in registry under certain name. Called automatically
		 * from constructor by most instances. */
		public function register(v:ixDef):void 
		{	
			var d:XML = v.def;
			if(d != null)
			{
				var vname:String = String(d.@name);
				if(vname.charAt(0) == '$' )
					vname = root.binCommand(vname.substr(1), v);
				v.name = vname;
				smallRegistry[vname] = v;
			}
			else if (!(v is xRoot))
				U.log(v, v.name, "[WARINING] ELEMENT HAS no def')");
		}
		/** Registers any ixDef implementator in registry under certain name and deletes previous entry. */
		public function requestNameChange(newName:String,requester:ixDef):String
		{
			if(newName != requester.name)
			{
				delete smallRegistry[requester.name];
				if(newName.charAt(0) == '$' )
					newName = root.binCommand(newName.substr(1), requester);
				smallRegistry[newName] = requester;
			}
			return newName;
		}
		/** Assignes all available properties from style provider to style receiver (key match, value assign).<br>
		 * If key of provider does not match property of receiver, no assignment is made, algorithm continues.
		 * @param v - style provider: an Object or array of Objects containing key-value pairs
		 * @param t - style receiver: any ixDef implementator.*/
		public function applyStyle(v:Object,t:ixDef):void
		{
			if(v is Array)
				for(var i:int = 0,j:int= v.length;i<j;i++)
					applyStyle(v[i],t);
			else if(v is Object)
				for(var p:String in v)
					if(t['hasOwnProperty'](p))
						t[p] = ((v[p] is String && v[p].charAt(0) == "$") ? root.binCommand(v[p].substr(1),t) : v[p]);
		}
		
		/**Resets instance to original XML values if <code>resetOnAddedToSage=true</code>.<br>
		 * Executes <i>meta.addedToStage</i> defined animations if any.<br>
		 * Executes function or evaluates code assigned to <code>onAddedToStage</code> property.<br>*/
		public function defaultAddedToStageSequence(t:ixDisplay):void
		{
			if(!t) return;
			if(t.resetOnAddedToStage)
				t.reset();
			if(t.meta && t.meta.addedToStage != null)
				animByNameExtra(t, 'addedToStage');
			if(t.onAddedToStage is String)
				root.binCommand(t.onAddedToStage,t);
			else if(t.onAddedToStage is Function)
				t.onAddedToStage();
		}
		/** Stops all proceeding and scheduled animations on target, 
		 * Executes function or evaluates code assigned to <code>onRemovedFromStage</code> property.<br>*/
		public function defaultRemovedFromStageSequence(t:ixDisplay):void
		{
			AO.killOff(t);
			if(t.onRemovedFromStage is String)
				root.binCommand(t.onRemovedFromStage,t);
			else if(t.onRemovedFromStage is Function)
				t.onRemovedFromStage();
		}
		
		/** Private function to support objects instantiation in order. Hold's delegates 
		 * in <code>additionQueue</code> */
		private static function proxyQueue(qcall:Function):void
		{
			additionQueue.push(qcall);
			if(additionQueue.length == 1)
				qcall();
		}
	}
}
