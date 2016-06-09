/**
 *
 * AXLX Framework
 * Copyright 2014-2016 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package axl.xdef.types
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.utils.setTimeout;
	
	import axl.utils.U;
	import axl.utils.binAgent.RootFinder;
	import axl.xdef.XSupport;
	import axl.xdef.xLauncher;
	import axl.xdef.interfaces.ixDef;

	/** Master class for XML DisplayList projects. Treat it as your stage */
	public class xRoot extends xSprite
	{
		private static const ver:String = '0.116';
		public static function get version():String { return ver }
		
		protected var xsourcePrefixes:Array
		protected var xsupport:XSupport;
		protected var CONFIG:XML;
		
		private var rootFinder:RootFinder;
		private var launcher:xLauncher;
		
		public var fileName:String;
		public var appRemote:String;
		public var map:Object = {};
		public var onRootAfterAttributes:Function;
		
		/** Master class for XML DisplayList projects. Treat it as your stage */
		public function xRoot(definition:XML=null)
		{
			xsupport = new XSupport();
			rootFinder = new RootFinder(this,XSupport);
			xsupport.root = this;
			this.xroot = this;
			launcher = new xLauncher(this,onReady);
			super(definition);
		}
		
		protected function onReady(v:XML):void {
			this.CONFIG = v;
			this.def = v.root[0];
		}
		
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
			if(onRootAfterAttributes!=null)
				onRootAfterAttributes();
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
		
		public function addProto(v:Object,props:Object,to:Object=null,index:int=-1,node:String='additions'):void
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
					getAdditionsByName(v as Array, gotit,node,null,true,f);
				else
					getAdditionByName(v as String, gotit,node,null,true,f);
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
		 * @param chname - depth controll -name of existing element under which addition will occur
		 * */
		public function addUnderChild(v:DisplayObject, chname:String,indexMod:int=0):void
		{
			var o:DisplayObject = getChildByName(chname);
			
			var i:int = o ? this.getChildIndex(o) : -1;
			var j:int = contains(v) ? getChildIndex(v) : int.MAX_VALUE;
			if(j < i)
			{
				U.log("Child", v, v.name, "already exists in this container and it is under child", o, o? o.name : null);
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
			if(debug) U.log('[xRoot][getAdditionByName]', v);
			if(v == null)
			{
				if(debug) U.log("[xRoot][getAdditionByName] requesting non existing element", v);
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
				if(debug) U.log('[xRoot][getAdditionByName]',v, 'already exists in xRoot.registry cache');
				if(callback) callback(registry[v]);
				return;
			}
			
			var xml:XML = getAdditionDefByName(v,node);
			if(xml== null)
			{
				if(debug) U.log('[xRoot][getAdditionByName][WARINING] REQUESTED CHILD "' + v + '" DOES NOT EXIST IN CONFIG "' + node +  '" NODE');
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
				if(callback) callback(v);
				next();
			}
		}
		
		/** Removes elements from the display list. Accepts arrays of display objects, their names and mixes of it.
		 * Skipps objects which are not part of the display list. */
		public function remove(...args):void
		{
			rmv.apply(null,args);
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
					removeChild(v as DisplayObject)
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
		 * @param onComplete callback to call when all animations are complete
		 * @param c -any animatable object that contains meta property
		 * @see axl.xdef.XSupport#animByNameExtra()
		 * */
		public function singleAnimByMetaName(objName:String, screenName:String, onComplete:Function=null,c:ixDef=null,killCurrent:Boolean=true,reset:Boolean=true,doNotDisturb:Boolean=false):void
		{
			c = c || this.getChildByName(objName) as ixDef;
			if(debug) U.log("[xRoot][singleAnimByMetaName][", screenName, '] - ', objName, c);
			if(c != null && c.meta.hasOwnProperty(screenName))
				XSupport.animByNameExtra(c, screenName, onComplete,killCurrent,reset,doNotDisturb);
			else
			{
				if(onComplete != null)
					setTimeout(onComplete, 5);
			}
		}
		/** Scans through all registered objects and executes animation on these which own <code>screenName</code>
		 * defined animation in their meta property
		 * @param screenName - name of the animation definition
		 * @param onComplete callback to call when all animations are complete
		 * @see #singleAnimByMetaName()
		 * */
		public function animateAllRegisteredToScreen(screenName:String,onComplete:Function=null,killCurrent:Boolean=true,reset:Boolean=true,doNotDisturb:Boolean=false):void
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
			if(all < 1 && onComplete != null)
				onComplete();
			function singleComplete():void
			{
				if(--all == 0 && onComplete !=null)
				{
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
			else
				U.log("Parser not available");
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
		/** Exposes animating object @see axl.utils.AO#animate()*/
		public function get animate():Function {return axl.utils.AO.animate}
	}
}