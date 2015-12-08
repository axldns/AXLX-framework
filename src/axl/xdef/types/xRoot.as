/**
 *
 * AXLX Framework
 * Copyright 2014-2015 Denis Aleksandrowicz. All Rights Reserved.
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
	
	import axl.utils.Ldr;
	import axl.utils.U;
	import axl.utils.binAgent.RootFinder;
	import axl.xdef.XSupport;
	import axl.xdef.interfaces.ixDef;

	/** Master class for XML DisplayList projects. Treat it as your stage */
	public class xRoot extends xSprite
	{
		public var elements:Object = {};
		protected var xsupport:XSupport;
		protected var CONFIG:XML;
		public var sourcePrefixes:Array;
		private var rootFinder:RootFinder;
		
		
		/** Master class for XML DisplayList projects. Treat it as your stage */
		public function xRoot(definition:XML=null)
		{
			if(xsupport == null)
				xsupport = new XSupport();
			if(xsupport.root == null)
				xsupport.root = this;
			this.xroot = this;
			
			if(rootFinder == null)
				rootFinder = new RootFinder(this,XSupport);
			super(definition);
		}
		
		public function get config():XML { return CONFIG }
		
		override public function set def(value:XML):void
		{
			// as xRoot is not called via XSupport.getReadyType
			// it must take care of parsing definition itself
			if(value == null || super.def != null)
				return;
			super.def = value;
			xsupport.pushReadyTypes2(value, this,'addChildAt',this);
			XSupport.applyAttributes(value, this);
		}
		
		
		// ADD - REMOVE
		public function add(v:Object,underChild:String=null,onNotExist:Function=null,indexModificator:int=0,node:String='additions',forceNewElement:Boolean=false):void
		{
			if(v is Array)
				getAdditionsByName(v as Array, gotit,node,onNotExist,forceNewElement);
			else
				getAdditionByName(v as String, gotit,node,onNotExist,forceNewElement)
			function gotit(d:DisplayObject):void{
				
				if(underChild != null)
					addUnderChild(d,underChild,indexModificator);
				else
					addChild(d);
			}
		}
		
		public function addTo(v:Object,intoChild:String,command:String='addChild',onNotExist:Function=null,node:String='additions',forceNewElement:Boolean=false):void
		{
			if(intoChild.charAt(0) == "$")
				intoChild = XSupport.simpleSourceFinder(this,intoChild) as String;
			var c:DisplayObjectContainer = xsupport.registered(intoChild) as DisplayObjectContainer;
			if(c == null)
			{
				U.log(this, "[addTo][ERROR] 'intoChild' (" + intoChild +") parameter refers to non existing object or it's not a DisplayObjectContainer descendant");
				return
			}
				
			if(v is Array)
				getAdditionsByName(v as Array, gotIt,node,onNotExist,forceNewElement);
			else
				getAdditionByName(v as String, gotIt,node,onNotExist,forceNewElement);
			function gotIt(o:Object):void {
				U.log(this, o, o.name, '[addTo]', c, c.name, 'via', command);
				c[command](o);
			}
		}
		
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
		/** Instantiates element from loaded config node. Instantiated / loaded / cached object
		 * is an argument for callback. 
		 * <br>All objects are being created within <code>XSupport.getReadyType</code> function. 
		 * <br>All objects are being cached within <code>XSupport.elements</code> dictionary where
		 * xml attribute <b>name</b> is key for it. 
		 * @param v - name of the object (must match any child of <code>node</code>). Objects
		 * are being looked up by <b>name</b> attribute. E.g. v= 'foo' for
		 *  <pre> < node>< div name="foo"/>< /node>  </pre> 
		 * @param callback - Function of one argument - loaded element. Function will be executed 
		 * once element is available (elements with <code>src</code> attribute may need to require loading of their contents).
		 * @param node - name of the XML tag (not an attrubute!) that is a parent for searched element to instantiate.
		 * @see axl.xdef.XSupport#getReadyType()
		 */
		public function getAdditionByName(v:String, callback:Function, node:String='additions',onError:Function=null,forceNewElement:Boolean=false):void
		{
			U.log('[xRoot][getAdditionByName]', v);
			if(v == null)
				return U.log("[xRoot][getAdditionByName] requesting non existing element", v);
			if(v.charAt(0) == '$')
			{
				v = XSupport.simpleSourceFinder(this,v) as String;
				if(v == null)
					v='ERROR';
			}
			if((elements[v] is DisplayObject) && !forceNewElement)
			{
				U.log('[xRoot][getAdditionByName]',v, 'already exists in xRoot.elements cache');
				callback(elements[v]);
				return;
			}
			else if((registry[v] is DisplayObject) && !forceNewElement)
			{
				U.log('[xRoot][getAdditionByName]',v, 'already exists in xRoot.registry cache');
				callback(registry[v]);
				return;
			}
			
			var xml:XML = getAdditionDefByName(v,node);
			if(xml== null)
			{
				U.log('[xRoot][getAdditionByName][WARINING] REQUESTED CHILD "' + v + '" DOES NOT EXIST IN CONFIG "' + node +  '" NODE');
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
			
			xsupport.getReadyType2(xml, loaded,true,null,this);
			function loaded(dob:DisplayObject):void
			{
				elements[v] =  dob;
				callback(dob);
			}
		}
		
		/** Executes <code>getAdditionByName</code> in a loop. @see #getAdditionByName() */
		public function getAdditionsByName(v:Array, callback:Function,node:String='additions',onError:Function=null,forceNewElement:Boolean=false):void
		{
			var i:int = 0, j:int = v.length;
			next();
			function next():void
			{
				if(i<j)
					getAdditionByName(v[i++], ready,node,onError,forceNewElement);
			}
			
			function ready(v:DisplayObject):void
			{
				callback(v);
				next()
			}
		}
		
		/** Removes elements from display list. Accepts arrays of display objects, their names and
		 * mixes of it. Skipps objects which are not part of the display list. */
		public function remove(...args):void
		{
			for(var i:int = 0,j:int = args.length, v:Object; i < j; i++)
			{	
				v = args[i]
				if(v is Array)
					removeElements(v as Array);
				else if(v is String)
					removeByName(v as String);
				else if(v is DisplayObject)
					removeChild(v as DisplayObject)
				else
					throw new Error("Can't remove: " + v + " - is unknow type");
			}
		}
		/** If child of name specified in argument exists - removes it. All animtions are performed
		 * based on individual class settings (xBitmap, xSprite, xText, etc)*/
		public function removeByName(v:String):void	{ removeChild(getChildByName(v)) }
		
		/**  removes array of objects from displaylist. can be actual displayObjects or their names */
		public function removeElements(args:Array):void
		{
			for(var i:int = args.length; i-->0;)
				args[i] is String ? removeByName(args[i]) : removeChild(args[i]);
		}
		
		/**  Uses registry to define child to remove. This can reach inside containers to remove specific element.
		 * The last registered element of name defined in V will be removed */
		public function removeRegistered(v:String):void
		{
			var dobj:DisplayObject = xsupport.registered(v) as DisplayObject;
			U.log('removeRegistered', v, dobj, dobj ? dobj.parent != null : null)
			if(dobj != null && dobj.parent != null)
				dobj.parent.removeChild(dobj);
		}
		/** executes <code>removeRegistered</code> in a loop */
		public function removeRegisteredGroup(v:Array):void
		{
			for(var i:int = 0; i < v.length; i++)
				removeRegistered(v[i]);
		}
		
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
		
		public function get registry():Object { return xsupport.registry }
		public function registered(v:String):Object { return  xsupport.registered(v) }

		// ANIMATION UTILITIES - to comment
		public function singleAnimByMetaName(objName:String, screenName:String, onComplete:Function=null,c:ixDef=null):void
		{
			c = c || this.getChildByName(objName) as ixDef;
			U.log("[xRoot][singleAnimByMetaName][", screenName, '] - ', objName, c);
			if(c != null && c.meta.hasOwnProperty(screenName))
				XSupport.animByNameExtra(c, screenName, onComplete);
			else
			{
				if(onComplete != null)
					setTimeout(onComplete, 5);
			}
		}
		
		public function animateAllRegisteredToScreen(screenName:String,onComplete:Function=null):void
		{
			var all:int=0;
			var reg:Object = xsupport.registry;
			for(var s:String in reg)
			{
				var c:ixDef = reg[s] as ixDef;
				if(c != null && c.meta.hasOwnProperty(screenName))
				{
					all++;
					singleAnimByMetaName(c.name,screenName,singleComplete,c);
				}
			}
			if(all < 1 && onComplete != null)
				onComplete();
			function singleComplete():void
			{
				if(--all == 0 && onComplete !=null)
					onComplete();
			}
		}
		
		public function animAllMetaToScreen(screenName:String,onComplete:Function=null):void
		{
			var all:int=0;
			for(var i:int = 0; i < this.numChildren; i++)
			{
				var c:ixDef = this.getChildAt(i) as ixDef;
				if(c != null && c.meta.hasOwnProperty(screenName))
				{
					all++;
					singleAnimByMetaName(c.name,screenName,singleComplete,c);
				}
			}
			if(all < 1 && onComplete != null)
				onComplete();
			function singleComplete():void
			{
				if(--all == 0 && onComplete !=null)
					onComplete();
			}
		}
		public function get files():Object { return Ldr.objects }
		
	
		
		public function binCommand(v:Object):*
		{
			if(rootFinder != null)
			{
				if(!(v is Array))
					return rootFinder.parseInput(v as String);
				for(var i:int =0,j:int=v.length;i<j;i++)
					U.log("binCommand", rootFinder.parseInput(v[i]), 'result of:', v[i]);
			}
			else
				U.log("Parser not available");
			return null;
		}
		
		
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
		
		public function executeIfMatches(sel:String,regexp:String,onTrue:String,onFalse:String,node:String='additions'):void
		{
			if(sel && sel.match(new RegExp(regexp)))
				executeFromXML(onTrue)
			else
				executeFromXML(onFalse)
		}
		
		public function executeFromXML(name:String,node:String='additions'):void
		{
			this.getAdditionByName(name, gotIt,node, gotIt);
			function gotIt(v:*):void
			{
				if(v && v is xButton)
					v.execute();
				else
					U.log("NO >>"+name+"<< btn defined in", node);
			}
		}
	}
}