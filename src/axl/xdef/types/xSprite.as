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
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.ColorTransform;
	
	import axl.utils.AO;
	import axl.utils.U;
	import axl.xdef.XSupport;
	import axl.xdef.interfaces.ixDisplay;
	
	/** Main DisplayObjectContainer class for XML defined objects. Can contain any children.
	 * Overrides standard addChild, addChildAt, removeChild, removeChildAt methods in order
	 * to maintain meta-keyword-defined animations before removing children or after adding them to display list.
	 * Self-listens for adding and removing from stage in order to maintain meta.addedToStage defined animation
	 * and to kill all existing animations when removed.
	 * @see #meta() */
	public class xSprite extends Sprite implements ixDisplay
	{
		protected var xdef:XML;
		protected var xmeta:Object={};
		private var xxroot:xRoot;
		public var debug:Boolean;
		
		protected var xfilters:Array
		protected var xtrans:ColorTransform;
		private var intervalID:uint;
		
		private var metaAlreadySet:Boolean;
		private var addedToStageActions:Vector.<xAction>;
		private var childrenCreatedAction:Vector.<xAction>;
		
		/** Every time META object is set (directly or indirectly - via <code>reset - XSupport.applyAttributes</code>
		 * method) object can be rebuild or set just once per existence @default false @see #reset() */
		public var reparseMetaEverytime:Boolean;
		/** Every time object XML definition is set definition can be re-read. For <code>xSprite</code> it 
		 * affects graphics drawing only. Pushing children inside happens only once per existence in
		 *  <code>XSupport.getReadyType2 - pushReadyTypes2</code>  @default false 
		 * @see axl.xdef.XSupport#getReadyType2() @see axl.xdef.XSupport#pushReadyTypes2() */
		public var reparsDefinitionEverytime:Boolean;
		/** Every time object is (re)added to stage method <code>reset</code> can be called. 
		 * Aim of method reset is to bring object to its initial state (defined by xml) by reparsing it's attributes
		 * and killing all animations @see #reset() */
		public var resetOnAddedToStage:Boolean=true;
		/** Distributes  children horizontaly with gap specified by this property. 
		 * If not set - no distrbution occur @see axl.utils.U#distribute() */
		public var distributeHorizontal:Number;
		/** Distributes  children verticaly with gap specified by this property. 
		 * If not set - no distrbution occur @see axl.utils.U#distribute() */
		public var distributeVertical:Number;
		
		/** Main DisplayObjectContainer class for XML defined objects. Can contain any children.
		 * Overrides standard addChild, addChildAt, removeChild, removeChildAt methods in order
		 * to maintain meta-keyword-defined animations before removing children or after adding them to display list.
		 * Self-listens for adding and removing from stage in order to maintain meta.addedToStage defined animation
		 * and to kill all existing animations when removed.
		 * @see #meta() */
		public function xSprite(definition:XML=null,xrootObj:xRoot=null)
		{
			addEventListener(Event.ADDED, elementAdded);
			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
			addEventListener(Event.REMOVED_FROM_STAGE, removeFromStageHandler);
			this.xroot = xrootObj || this.xroot;
			if(this.xroot != null && definition != null)
				xroot.registry[String(definition.@name)] = this;
			else if (!(this is xRoot))
				U.log(this, this.name, "[WARINING] ELEMENT HAS" ,xroot,  'as root and ', definition? definition.name() : "null", 'node as def.', this is xRoot)
			xdef = definition;
			super();
			parseDef();
		}
		/** reference to parent xRoot object @see axl.xdef.types.xRoot */
		public function get xroot():xRoot { return xxroot }
		public function set xroot(v:xRoot):void	{ xxroot = v }
		
		/** Sets name and registers object in registry @see axl.xdef.types.xRoot.registry */
		override public function set name(v:String):void
		{
			super.name = v;
			if(this.xroot != null)
				this.xroot.registry.v = this;
		}
		
		protected function removeFromStageHandler(e:Event):void	{ AO.killOff(this) }
		
		protected function addedToStageHandler(e:Event):void
		{
			if(resetOnAddedToStage)
				this.reset();
			if(meta.addedToStage != null)
				XSupport.animByNameExtra(this, 'addedToStage');
			if(addedToStageActions != null)
			{	for(var i:int = 0, j:int = addedToStageActions.length; i<j; i++)
				addedToStageActions[i].execute();
				if(debug) U.log(this, this.name, '[addedToStage]', j, 'actions');
			}
		}
		
		protected function elementAdded(e:Event):void
		{
			if(!isNaN(distributeHorizontal))
				U.distribute(this,distributeHorizontal,true);
			if(!isNaN(distributeVertical))
				U.distribute(this,distributeVertical,false);
		}
		
		public function onChildrenCreated():void
		{
			if(childrenCreatedAction != null)
			{	for(var i:int = 0, j:int = childrenCreatedAction.length; i<j; i++)
					childrenCreatedAction[i].execute();
				if(debug) U.log(this, this.name, '[childrenCreatedAction]', j, 'actions');
			}
		}
		/**
		 * <h3>xSprite meta keywords</h3>
		 * <ul>
		 * <li>"addedToStage" - animation(s) to execute when added to stage</li>
		 * <li>"addChild" - animation to execute when added as a child</li>
		 * <li>"removeChild" - animation to execute before removing from stage (delays removing from stage)</li>
		 * <li>"addedToStageAction" - action(s) to execute when added to stage</li>
		 * <li>"childrenCreatedAction" - acction(s) to execute when all initial children (from xml children nodes) are
		 * instantiated and added to this instance</li>
		 * </ul>
		 * @see axl.xdef.types.xAction
		 * @see axl.xdef.XSupport#animByNameExtra()
		 * @see axl.utils.AO#animate()
		 */
		public function get meta():Object { return xmeta }
		public function set meta(v:Object):void 
		{
			if(v is String)
				throw new Error("Invalid json for element " +  def.localName() + ' ' +  def.@name );
			if(!v || (metaAlreadySet && !reparseMetaEverytime))
				return;
			xmeta =v;
			metaAlreadySet = true;
			var a:Object, b:Array, i:int, j:int;
			if(meta.hasOwnProperty('addedToStageAction'))
			{
				addedToStageActions = new Vector.<xAction>();
				a = meta.addedToStageAction;
				b = (a is Array) ? a as Array : [a];
				for(i = 0, j = b.length; i<j; i++)
					addedToStageActions[i] = new xAction(b[i],xroot,this);
			}
			
			if(meta.hasOwnProperty('childrenCreatedAction'))
			{
				childrenCreatedAction = new Vector.<xAction>();
				a = meta.childrenCreatedAction;
				b = (a is Array) ? a as Array : [a];
				for(i = 0, j = b.length; i<j; i++)
					childrenCreatedAction[i] = new xAction(b[i],xroot,this);
			}
		}
		/** Kills all animations proceeding and sets initial (xml-def-attribute-defined) values to 
		 * this object
		 * @see axl.xdef.XSupport#applyAttrubutes()
		 * @see #resetOnAddedToStage
		 * @see #reparseMetaEverytime
		 * */
		public function reset():void {
			AO.killOff(this);
			XSupport.applyAttributes(def, this);	
		}
		/** XML definition of this object*/
		public function get def():XML { return xdef }
		public function set def(value:XML):void 
		{ 
			if((value == null) || (xdef != null && xdef is XML && !reparsDefinitionEverytime))
				return;
			xdef = value;
			parseDef();
		}
		
		override public function addChild(child:DisplayObject):DisplayObject
		{
			super.addChild(child);
			var c:ixDisplay = child as ixDisplay;
			if(c != null && c.meta.addChild != null)
			{
				c.reset();
				XSupport.animByNameExtra(c, 'addChild');
			}
			return child;
		}
		override public function addChildAt(child:DisplayObject, index:int):DisplayObject
		{
			super.addChildAt(child, index);
			var c:ixDisplay = child as ixDisplay;
			if(c != null && c.meta.addChild != null)
			{
				c.reset();
				XSupport.animByNameExtra(c, 'addChild');
			}
			return child;
		}
		
		override public function removeChild(child:DisplayObject):DisplayObject
		{
			if(child == null)
				return child;
			var f:Function = super.removeChild;
			var c:ixDisplay = child as ixDisplay;
			if(c != null)
			{
				AO.killOff(c);
				XSupport.animByNameExtra(c, 'removeChild', acomplete);
			} else { acomplete() }
			function acomplete():void { f(child) }
			return child;
		}
		
		override public function removeChildAt(index:int):DisplayObject
		{
			var f:Function = super.removeChildAt;
			var c:ixDisplay = super.getChildAt(index) as ixDisplay;
			if(c != null)
			{
				AO.killOff(c);
				XSupport.animByNameExtra(c, 'removeChild', acomplete);
			} else { acomplete() } 
			function acomplete():void { f(index) }
			return c as DisplayObject;
		}
		
		protected function parseDef():void
		{
			if(xdef==null)
				return;
			XSupport.drawFromDef(def.graphics[0], this);
		}
		
		override public function set filters(v:Array):void
		{
			xfilters = v;
			super.filters=v;
		}
		/** Sets assigned  filters on or off @see #filters */
		public function set filtersOn(v:Boolean):void {	super.filters = (v ? xfilters : null) }
		public function get filtersOn():Boolean { return filters != null }
	}
}