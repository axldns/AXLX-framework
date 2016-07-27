/**
 *
 * AXLX Framework
 * Copyright 2014-2016 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package axl.xdef.types.display
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.SyncEvent;
	
	import axl.utils.U;
	import axl.utils.binAgent.RootFinder;
	import axl.xdef.XSupport;
	import axl.xdef.xLauncher;
	import axl.xdef.interfaces.ixDef;

	/** Master class for XML DisplayList projects.<br>
	 * Launches the project, holds the config, provides top level API for DisplayObjects manipulation:
	 * <ul>
	 * <li>instantiating, adding and removing objects to/from display list</li>
	 * <li>animating existing objects (single and groupped)</li>
	 * <li>interpreting and executing XML defined functions</li>
	 * </ul>
	 * Top chain context of code within XML. */
	public class xRoot extends xSprite
	{
		private static const ver:String = '0.123';
		public static function get version():String { return ver }
		
		protected var xsourcePrefixes:Array
		protected var xsupport:XSupport;
		protected var CONFIG:XML;
		
		private var rootFinder:RootFinder;
		private var launcher:xLauncher;
		/** Defines config name and partially its location. If set -changes config file name deduction to this value.
		 * By default, fileName value is attempted to deduct automatically. Priorities:
		 * <ol>
		 * <li>manual assignment to this property</li>
		 * <li>parameters.fileName passed to xRoot constructor (use for RSL)</li>
		 * <li>loaderInfo.parameters.fileName (use when you load project from bigger application) | native locaton on mobile projects</li>
		 * <li>parsing loaderInfo.parameters.loadedURL</li>
		 * <li>parsing xroot.loaderInfo.url</li>
		 * </ol>
		 * Do not change if you require full automation. Pass it when you use AXLX as a RSL, from stub or from other loadings
		 * where fileName auto deduction may fail.
		 * @see #appRemote
		 * */
		public var fileName:String;
		/** Determines network location that contains config file. <code>fileName</code> is going to be concatenated in to appRemote according to 
		 * axl.xdef.xLauncher.appReomoteSPLITfilename rules.<br><br>
		 * If appRemote is not set (default), there's an attempt to deduct it automatically but then appReomoteSPLITfilename does not apply.
		 * Priorities:
		 * <ol>
		 * <li>manual assignment to this property</li>
		 * <li>parameters.loadedURL + one dir up, passed to xRoot constructor (use for RSL)</li>
		 * <li>loaderInfo.parameters.loadedURL + one dir up (use when you load project from bigger application) | native locaton on mobile projects</li>
		 * <li>xroot.loaderInfo.ur + one dir upl</li>
		 * </ol>
		 * @see axl.xdef.xLauncher#appReomoteSPLITfilename*/
		public var appRemote:String;
		
		/** Master class for XML DisplayList projects. Treat it as your stage.
		 * @param definition - XML definition of root, kept as it extends xSprite. 
		 * Real definiton is passed when config is loaded.
		 * @param parameters - can contain fileName and loadedURL to modify location of config file. 
		 * Can be used with RSL, when deduction gives not relevant results. fileName has lower 
		 * priority than set-able public property fileName. If present, loadedURL has higher priority
		 * than one passed in loaderInfo.parameters.loadedURL but lower than assigned appRemote in
		 * non-local runs.
		 * @see #fileName @see #appRemote */
		public function xRoot(definition:XML=null,parameters:Object=null)
		{
			xsupport = new XSupport();
			rootFinder = new RootFinder(this,XSupport);
			xsupport.root = this;
			this.xroot = this;
			launcher = new xLauncher(this,onReady,parameters);
			super(definition);
		}
		
		override protected function addedToStageHandler(e:Event):void
		{
			super.addedToStageHandler(e);
			stage.loaderInfo.sharedEvents.dispatchEvent(new SyncEvent("requestContextChange",true,false,[this]));
		}
		
		protected function onReady(v:XML):void {
			this.CONFIG = v;
			this.def = v.root[0];
		}
		/** Context / root path for elements using "src" attribute */
		public function get sourcePrefixes():Array {return xsourcePrefixes }
		public function set sourcePrefixes(v:Array):void { xsourcePrefixes = v}
		/** Returns reference to XML config - the project definition */
		public function get config():XML { return CONFIG }
		/** &lt;root> element definition. Setting it up for the first time fires up chain
		 * of instantiation all sub elements 
		 * @see axl.xdef.XSupport#pushReadyTypes2() 
		 * @see axl.xdef.XSupport#applyAttributes() */
		override public function set def(value:XML):void
		{
			// as xRoot is not called via XSupport.getReadyType
			// it must take care of parsing definition itself
			if(value == null || super.def != null)
				return;
			super.def = value;
			XSupport.applyAttributes(value, this);
			xsupport.pushReadyTypes2(value, this,null,this);
		}
		
		// ADD - REMOVE
		/** Adds or removes one or more elements (config xml nodes) to stage (xml root node).
		 * @param v - String or Array of Strings - must reffer to <code>name</code> attribute of requested config node
		 * @param underChild - depth controll -name of existing element under which addition will occur
		 * @param onNotExist - Function to execute if one or more elements does not exist
		 * in specified node. By default it throws Error. Passiong function helps treat it gracefully
		 * @param indexModificator - depth controll - modifes addition index when "underChild" specified
		 * @param node - config xml node within which elements of <code>v</code> name are searched for
		 * @param forceNewElement - if object(s) of v name are already instantiated (available within <code>registry</code>),
		 * no new object will be instantiated unless <code>forceNewElement</code> flag is set to <code>true</code>
		 * */
		public function add(v:Object,underChild:String=null,onNotExist:Function=null,indexModificator:int=0,node:String='additions',forceNewElement:Boolean=false):void
		{
			if(v is Array)
				getAdditionsByName(v as Array, gotit,node,onNotExist,forceNewElement);
			else
				getAdditionByName(v as String, gotit,node,onNotExist,forceNewElement);
			function gotit(d:Object):void
			{
				if(!(d is DisplayObject))
				{
					if(debug) U.log('[WARNING]', d, d && d.hasOwnProperty('name') ? d.name : v, "IS NOT A DISPLAY OBJECT");
					return
				}
				if(underChild != null)
					addUnderChild(d as DisplayObject,underChild,indexModificator);
				else
					addChild(d as DisplayObject);
			}
		}
		/** (Experimental) Works the same as <code>add</code> and <code>addTo</code> method, but on instantiation
		 * passes every element and all its sub-elements on all depth levels through decorator function.
		 * Instead of function, key-value pairs object can be provided - co-exisisting properties will be matched
		 * and values assigned. If its function - must accept one argument.
		 * Already existing (registry) objects are not being passed through decorator again.<br>
		 * Another difference is that element specified as container for target object does not have to be neccesairly
		 * instantiated at request time. If it doesn't - one will be created, but not added to stage. In this case target won't be on stage too.
		 * @param v - String (name of registered object or child of additions with name attribute of such), DisplayObject, or array of both
		 * @param props - decorator function or key-value object for v and all its descendands.
		 * @param to -  String (name of registered object or child of additions with name attribute of such), DisplayObject, or array of both to which
		 * target (v) display list will be added
		 * @param forceNew - if true - regardless of existance object of the same name in registry, new object will be instantiated, otherwise
		 * last registered object of name v will be added
		 * @param index display list depth controll
		 * @param node - objects (v) can be defined also outside additions node
		 * @see #add() @see #addTo() @see #registry
		 * */
		public function addProto(v:Object,props:Object,to:Object=null,forceNew:Boolean=false,index:int=-1,node:String='additions'):void
		{
			var f:Function = (props as Function) || decorator;
			var c:DisplayObjectContainer = this;
			if(to!=null)
				getContainer(to,gotContainer,node);
			else
				getObject();
			function gotContainer(cont:Object):void
			{
				c = cont as DisplayObjectContainer;
				if(c == null)
				{
					if(debug) U.log(this, "[addProto][ERROR] 'intoChild' (" + to +")");
					return
				}
				getObject();
			}
			
			function getObject():void
			{
				if(v is DisplayObject)
				{
					f(v as ixDef);
					gotit(v);
				}
				else if(v is Array)
					getAdditionsByName(v as Array, gotit,node,null,forceNew,f);
				else
					getAdditionByName(v as String, gotit,node,null,forceNew,f);
			}
			
			function gotit(o:Object):void
			{
				if(debug) U.log(this, o, o.name, '[addProto]', c, c.name);
				if(index >= 0 && index < c.numChildren-1)
					c.addChildAt(DisplayObject(o),index);
				else
					c.addChild(DisplayObject(o));
			}
			function decorator(v:ixDef):void
			{
				if(debug) log("decorating", v, v.name);
				if(!v || !v.meta) return;
				for(var s:String in props)
					v.meta[s] = props[s];
			}
		}
		
		private function getContainer(container:Object,callback:Function,node:String):void
		{
			var c:DisplayObjectContainer = container as DisplayObjectContainer;
			if(!c)
			{
				c =  xsupport.registry[String(container)] as DisplayObjectContainer;
				if(!c)
				{
					c = binCommand(container,this) as DisplayObjectContainer;
					if(!c)
						this.getAdditionByName(String(container), callback,node);
					else
						callback(c);
				}
				else
					callback(c);
			}
			else
				callback(c);
		}
		/** Adds or removes one or more elements (config xml nodes) to any instantiated DisplayObjectContainer descendants.
		 * @param v - String or Array of Strings - must reffer to <code>name</code> attribute of requested config node
		 * @param intoChild - target DisplayObjectContainer ("name", "$refference" or DisplayObjectContainer itself) to add "v" to.
		 * @param onNotExist - Function to execute if one or more elements does not exist
		 * in specified node. By default it throws Error. Passiong function helps treat it gracefully
		 * @param node - config xml node within which elements of <code>v</code> name are searched for
		 * @param forceNewElement - if object(s) of v name are already instantiated (available within <code>registry</code>),
		 * no new object will be instantiated unless <code>forceNewElement</code> flag is set to <code>true</code>
		 * */
		public function addTo(v:Object,intoChild:Object,command:String='addChild',onNotExist:Function=null,node:String='additions',forceNewElement:Boolean=false):void
		{
			if(intoChild is String && intoChild.charAt(0) == "$")
				intoChild = binCommand(intoChild.substr(1),this);//should be calee
			if(intoChild is String)
				intoChild =  xsupport.registry[String(intoChild)];
				
			var c:DisplayObjectContainer = intoChild as DisplayObjectContainer;
			if(c == null)
			{
				if(debug) U.log(this, "[addTo][ERROR] 'intoChild' (" + intoChild +") parameter refers to non existing object or it's not a DisplayObjectContainer descendant");
				return
			}
				
			if(v is Array)
				getAdditionsByName(v as Array, gotIt,node,onNotExist,forceNewElement);
			else
				getAdditionByName(v as String, gotIt,node,onNotExist,forceNewElement);
			function gotIt(o:Object):void {
				if(debug) U.log(this, o, o.name, '[addTo]', c, c.name, 'via', command);
				c[command](o);
			}
		}
		/** Adds DisplayObject underneath another child specified by it's name
		 * @v - DisplayObject to add
		 * @param chname - depth controll -name of existing element under which addition will occur		 * */
		public function addUnderChild(v:DisplayObject, chname:String,indexMod:int=0):void
		{
			var o:DisplayObject = getChildByName(chname);
			
			var i:int = o ? this.getChildIndex(o) : -1;
			var j:int = contains(v) ? getChildIndex(v) : int.MAX_VALUE;
			if(j < i)
			{
				if(debug) U.log("Child", v, v.name, "already exists in this container and it is under child", o, o? o.name : null);
				return;
			}
			if(i > -1)
			{
				i+= indexMod;
				if(i<0)
					i=0;
				if(i < this.numChildren)
					this.addChildAt(v,i);
				else
					this.addChild(v);
			}
			else this.addChild(v);
		}
		
		/** Returns first XML child of Config[node] which matches it name */
		public function getAdditionDefByName(v:String,node:String='additions'):XML
		{
			return this.CONFIG[node].*.(@name==v)[0];
		}
		/** Finds child node by name*/
		public function getXMLNodeByName(xml:XML,v:String):XML
		{
			return xml.*.(@name==v)[0];
		}
		/** Instantiates element from loaded config node. Instantiated / loaded / cached object
		 * is an argument for callback. 
		 * <br>All objects are being created within <code>XSupport.getReadyType2</code> function. 
		 * <br>All objects are being cached within <code>registry</code> dictionary where
		 * xml attribute <b>name</b> is key for it. 
		 * @param v - name of the object (must match any child of <code>node</code>). Objects
		 * are being looked up by <b>name</b> attribute. E.g. v= 'foo' for
		 *  <pre>
		 * &lt;node>&lt;div name="foo"/>&lt;/node>
		 * </pre> 
		 * @param callback - Function of one argument - loaded element. Function will be executed 
		 * once element is available (elements with <code>src</code> attribute may need to require loading of their contents).
		 * @param node - name of the XML tag (not an attrubute!) that is a parent for searched element to instantiate.
		 * @see axl.xdef.XSupport#getReadyType2()
		 */
		public function getAdditionByName(v:String, callback:Function=null, node:String='additions',onError:Function=null,
										  forceNewElement:Boolean=false,decorator:Function=null):void
		{
			var tn:String = '[xRoot][getAdditionByName]';
			if(debug) U.log(tn, v);
			if(v == null)
			{
				if(debug) U.log(tn + " requesting non existing element", v);
				return;
			}
			if(v.charAt(0) == '$')
			{
				v = binCommand(v.substr(1),this) as String;
				if(v == null)
					v='ERROR';
			}
			else if((registry[v] != null ) && !forceNewElement)
			{
				if(debug) U.log(tn,v, 'already exists in xRoot.registry cache');
				if(callback != null) callback(registry[v]);
				return;
			}
			
			var xml:XML = getAdditionDefByName(v,node);
			if(xml== null)
			{
				if(debug) U.log(tn+'[WARINING] REQUESTED CHILD "' + v + '" DOES NOT EXIST IN CONFIG "' + node +  '" NODE');
				if(onError == null) 
					throw new Error(v + ' does not exist in additions node');
				else
				{
					if(onError.length > 0)
						onError(v);
					else
						onError()
					return;
				}
			}
			xsupport.getReadyType2(xml, callback,decorator,null,this);
		}
		
		/** Executes <code>getAdditionByName</code> in a loop. @see #getAdditionByName() */
		public function getAdditionsByName(v:Array, callback:Function=null,node:String='additions',onError:Function=null,
										   forceNewElement:Boolean=false,decorator:Function=null):void
		{
			var i:int = 0, j:int = v.length;
			next();
			function next():void
			{
				if(i<j)
					getAdditionByName(v[i++], ready,node,onError,forceNewElement,decorator);
			}
			
			function ready(v:Object):void
			{
				if(callback != null) callback(v);
				next();
			}
		}
		
		/**  Uses registry to define child to remove. This can reach inside containers to remove specific element.
		 * The last registered element of name defined in V will be removed */
		public function removeRegistered(v:String):void
		{
			var dobj:DisplayObject = registry[v] as DisplayObject;
			if(debug) U.log('removeRegistered', v, dobj, dobj ? dobj.parent != null : null)
			if(dobj != null && dobj.parent != null)
				dobj.parent.removeChild(dobj);
		}
		/** executes <code>removeRegistered</code> in a loop */
		public function removeRegisteredGroup(v:Array):void
		{
			for(var i:int = 0; i < v.length; i++)
				removeRegistered(v[i]);
		}
		
		/** Removes elements from the display list. Accepts arrays of display objects, their names and mixes of it.
		 * Skipps objects which are not part of the display list. */
		public function rmv(...args):void
		{
			for(var i:int = 0,j:int = args.length, v:Object; i < j; i++)
			{	
				v = args[i]
				if(v is String)
					removeRegistered(v as String);
				else if(v is Array)
					removeRegisteredGroup(v as Array);
				else if(v is DisplayObject)
					v.parent.removeChild(v as DisplayObject)
				else
					U.log("[xRoot][rmv][WARNING] - Can't remove: " + v + " - is unknow type");
			}
		}
		/** Dictionary of all <b>instantiated</b> objects which can be identified by <code>name</code> attribute*/
		public function get registry():Object { return xsupport.registry }
		/** Returns decorator of XML project */
		public function get support():XSupport{ return xsupport } 

		/** Animates an object if it owns an animation definition defined by <code>screenName</code> 
		 * @param objName - name of animatable object on the displaylist if param <code>c</code> is null
		 * @param screenName - name of the animation definition
		 * @param onComplete callback to call when all animations are complete - function or portion of uncompiled code
		 * @param c -any animatable object that contains meta property
		 * @see axl.xdef.XSupport#animByNameExtra()
		 * */
		public function singleAnimByMetaName(objName:String, screenName:String, onComplete:Object=null,c:ixDef=null,killCurrent:Boolean=true,reset:Boolean=true,doNotDisturb:Boolean=false):void
		{
			c = c || this.getChildByName(objName) as ixDef || xsupport.registry[objName] as ixDef;
			if(debug) U.log("[xRoot][singleAnimByMetaName][", screenName, '] - ', objName, c);
			if(c != null && c.meta.hasOwnProperty(screenName))
				XSupport.animByNameExtra(c, screenName, onComplete,killCurrent,reset,doNotDisturb);
			else
			{
				if(onComplete is String)
					binCommand(onComplete,c);
				if(onComplete is Function)
					onComplete();
			}
		}
		/** Scans through all registered objects and executes animation on these which own <code>screenName</code>
		 * defined animation in their meta property
		 * @param screenName - name of the animation definition
		 * @param onComplete callback to call when all animations are complete - function or portion of uncompiled code
		 * @see #singleAnimByMetaName()
		 * */
		public function animateAllRegisteredToScreen(screenName:String,onComplete:Object=null,killCurrent:Boolean=true,reset:Boolean=true,doNotDisturb:Boolean=false):void
		{
			var all:int=0;
			var reg:Object = xsupport.registry;
			for(var s:String in reg)
			{
				var c:ixDef = reg[s] as ixDef;
				if(c != null && c.meta && c.meta.hasOwnProperty(screenName))
				{
					all++;
					singleAnimByMetaName(c.name,screenName,singleComplete,c,killCurrent,reset,doNotDisturb);
				}
			}
			function singleComplete():void
			{
				if(--all <= 0 && onComplete !=null)
				{
					if(onComplete is String)
						binCommand(onComplete,this) //how to get c?
					if(onComplete is Function)
						onComplete();
				}
			}
		}
		
		/** Executes function(s) from string (eval style)
		 * @param v - string or array of strings to evaluate
		 * @param debug <ul>
		 * <li>1 -logs errors only</li>
		 * <li>2 -logs result of every command</li>
		 * <li>other -no logging at all</li>
		 * </ul>
		 * @return - latest result of evaluation (last element of array if so)
		 * @see axl.utils.binAgent.RootFinder#parseInput()
		 * */
		public function binCommand(v:Object,thisContext:Object,debug:int=1):*
		{
			if(rootFinder != null)
			{
				var i:int =0,r:*,a:Array = (v is Array) ? v as Array: [v],j:int = a.length;
				switch (debug)
				{
					case 1:
						for(;i<j;i++)
						{
							r = rootFinder.parseInput(a[i],thisContext);
							if(r is Error)
								U.log("ERROR BIN COMMAND", a[i], '\n' + r);
						}
						return r;
					case 2:
						for(;i<j;i++)
						{
							r=rootFinder.parseInput(a[i],thisContext)
							U.log("binCommand", r, 'result of:', a[i]);
						}
						return r;
					default:
						for(;i<j;i++)
							r = rootFinder.parseInput(a[i],thisContext);
						return r;
				}
			}
			return r;
		}
		
		/** If Regexp(regexp) matches <code>sel</code> executes <code>add</code> with <code>onTrue</code> as an argument, otherwise
		 * executes it with onFalse. @see #add() */
		public function addIfMatches(sel:String,regexp:String='.*',onTrue:Object=null,onFalse:Object=null):void
		{
			if(sel && sel.match(new RegExp(regexp)))
			{
				try { add.apply(null, (onTrue is Array) ? onTrue : [onTrue]) }
				catch(e:*) { U.log(this, "[addIfMatches]ERROR: invalid argument onTrue:", onTrue) }
			}
			else
			{
				try { add.apply(null, (onFalse is Array) ? onFalse : [onFalse]) }
				catch(e:*) { U.log(this, "[addIfMatches]ERROR: invalid argument onFalse:", onFalse) }
			}
		}
		/** Depending on if Regexp(regexp) matches <code>sel</code> executes <code>executeFromXML</code> 
		 * with onTrue or onFalse arguments @see #executeFromXML() */
		public function executeIfMatches(sel:String,regexp:String,onTrue:String,onFalse:String,node:String='additions'):void
		{
			if(sel && sel.match(new RegExp(regexp)))
				executeFromXML(onTrue,node)
			else
				executeFromXML(onFalse,node)
		}
		/** Gets instantiated object from registry or instantiates new from <code>node</code> and
		 * calls <code>execute()</code> method on it if objects owns it (<code>&lt;btn>, &lt;act></code>)*/
		public function executeFromXML(name:String,node:String='additions'):void
		{
			this.getAdditionByName(name, gotIt,node, gotIt);
			function gotIt(v:*):void
			{
				if(v && v.hasOwnProperty('execute'))
					v.execute();
				else
					U.log("EXECUTE >>"+name+"<< NOT AVAILABLE", node);
			}
		}
		
		/** Exposes logging to console @see axl.utils.U#log()*/
		public function get log():Function { return U.log}
		/** Exposes tweening engine AO.animate object @see axl.utils.AO#animate()*/
		public function get animate():Function {return axl.utils.AO.animate}
	}
}