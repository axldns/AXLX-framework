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
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.ColorTransform;
	import flash.geom.Vector3D;
	
	import axl.utils.AO;
	import axl.utils.U;
	import axl.xdef.XSupport;
	import axl.xdef.interfaces.ixDisplay;
	import axl.xdef.interfaces.ixDisplayContainer;
	
	/** 
	 * Main DisplayObjectContainer class for XML defined objects. Can contain any children.<br>
	 * Instantiated from:<h3>
	 * <code>&lt;div&gt;<br>&lt;/div&gt;</code></h3>
	 * Overrides standard addChild, addChildAt, removeChild, removeChildAt methods in order
	 * to maintain meta-keyword-defined animations before removal or after addition children to display list.
	 * Self-listens for adding and removing from stage in order to maintain meta.addedToStage defined animation
	 * and to kill all existing animations when removed.
	 * <h3>Adding children to display list of xSprite container</h3>
	 * Children of xml node will automatically become children of xSprite instance. Example:<br>
	 * <pre>&lt;div&gt;<br>&#9;&lt;img src='image1.png'/&gt;<br><br>&#9;&lt;img src='image2.png'/&gt;<br>&lt;/div&gt;</pre>
	 * @see #meta() */
	public class xSprite extends Sprite implements ixDisplayContainer
	{
		private var xdef:XML;
		private var xmeta:Object;
		private var xxroot:xRoot;
		private var xonAddedToStage:Object;
		private var xonRemovedFromStage:Object;
		private var xonChildrenCreated:Object;
		private var xonElementAdded:Object;
		private var xresetOnAddedToStage:Boolean=true;
		private var xstyles:Object;
		private var xsortZ:Boolean=false;
		
		public var debug:Boolean;
		protected var xtrans:ColorTransform;
		
		/** Portion of uncompiled code to execute when object is created and attributes are applied. 
		 * 	Runs only once. An argument for binCommand. Does not have to be dolar sign prefixed.
		 * @see axl.xdef.types.display.xRoot#binCommand() */
		public var inject:String;
		/** Distributes  children horizontaly with gap specified by this property.
		 * This can be an array of gaps or single number. If not set - no distrbution occurs.
		 *  @see axl.utils.U#distribute()  @see axl.utils.U#distributePattern()*/
		public var distributeHorizontal:Object;
		/** Distributes  children verticaly with gap specified by this property.
		 * This can be an array of gaps or single number. If not set - no distrbution occurs.
		 *  @see axl.utils.U#distribute()  @see axl.utils.U#distributePattern()*/ 
		public var distributeVertical:Object;
		
		
		/** Main DisplayObjectContainer class for XML defined objects. Can contain any children.<br>
		 * @param definition - xml definition
		 * @param xroot - reference to parent xRoot object
		 * @see axl.xdef.types.display.xSprite
		 * @see axl.xdef.interfaces.ixDef#def
		 * @see axl.xdef.interfaces.ixDef#xroot
		 * @see axl.xdef.XSupport#getReadyType2()  */
		public function xSprite(definition:XML=null,xrootObj:xRoot=null)
		{
			this.xroot = xrootObj || this.xroot;
			this.xdef = definition;
			xroot.support.register(this);
			
			addEventListener(Event.ADDED, elementAddedHandler);
			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
			addEventListener(Event.REMOVED_FROM_STAGE, removeFromStageHandler);
			
			super();
			parseDef();
		}
		//----------------------- INTERFACE METHODS -------------------- //
		/** XML definition of this object @see axl.xdef.interfaces.ixDef#def */
		public function get def():XML { return xdef }
		public function set def(value:XML):void 
		{ 
			if((value == null))
				return;
			xdef = value;
			parseDef();
		}
		/** Reference to parent xRoot object @see axl.xdef.types.display.xRoot 
		 * @see axl.xdef.interfaces.ixDef#xroot */
		public function get xroot():xRoot { return xxroot }
		public function set xroot(v:xRoot):void	{ xxroot = v }
		
		/**
		 *  Dynamic variables container. It's set up only once. Subsequent applying XML attributes
		 * or calling reset() will not have an effect. 
		 * <h3>xSprite meta keywords</h3>
		 * <ul>
		 * <li>"addedToStage" - animation(s) to execute when added to stage</li>
		 * <li>"addChild" - animation to execute when added as a child</li>
		 * <li>"removeChild" - animation to execute before removing from stage (delays removing from stage), instantiated 
		 * and added to this instance</li>
		 * </ul>
		 * @see axl.xdef.XSupport#animByNameExtra()
		 * @see axl.utils.AO#animate() */
		public function get meta():Object { return xmeta }
		public function set meta(v:Object):void 
		{
			if(v is String)
				throw new Error("Invalid json for element " +  def.localName() + ' ' +  def.@name );
			if(!v || meta) return;
			xmeta =v;
		}
		
		/** Sets name and registers object in registry 
		 * @see axl.xdef.types.display.xRoot.registry @xee axl.xdef.interfaces.ixDef#name */
		override public function set name(v:String):void
		{
			super.name = xroot.support.requestNameChange(v,this);
		}
		
		/** Kills all animations proceeding and sets initial (xml-def-attribute-defined) values to 
		 * this object
		 * @see axl.xdef.XSupport#applyAttrubutes()
		 * @see #resetOnAddedToStage */
		public function reset():void 
		{
			AO.killOff(this);
			XSupport.applyAttributes(def, this);	
		}
		
		/** Applies group of properties at once @see axl.xdef.interfaces.ixDisplay#style */
		public function get styles():Object	{ return xstyles }
		public function set styles(v:Object):void
		{
			xstyles = v;
			xroot.support.applyStyle(v,this);
		}
		
		/** Function reference or portion of uncompiled code to execute when object is removed from stage.
		 *  An argument for binCommand. @see axl.xdef.types.display.xRoot#binCommand() */
		public function get onRemovedFromStage():Object	{ return xonRemovedFromStage }
		public function set onRemovedFromStage(value:Object):void {	xonRemovedFromStage = value }
		
		/** Function or portion of uncompiled code to execute when object is added to stage. An argument for binCommand.
		 * @see axl.xdef.types.display.xRoot#binCommand() */
		public function get onAddedToStage():Object { return xonAddedToStage }
		public function set onAddedToStage(value:Object):void {	xonAddedToStage = value }
		
		/** Determines if object is going to be brought to it's original XML defined values. 
		 * @see axl.interfaces.ixDisplay#resetOnAddedToStage */
		public function get resetOnAddedToStage():Boolean {	return xresetOnAddedToStage }
		public function set resetOnAddedToStage(value:Boolean):void { xresetOnAddedToStage = value}
		
		/** Function or portion of uncompiled code to execute when all original structure xml children are
		 * added to container's display list. An argument for binCommand.
		 * @see axl.xdef.types.display.xRoot#binCommand() */
		public function get onChildrenCreated():Object { return xonChildrenCreated }
		public function set onChildrenCreated(value:Object):void { xonChildrenCreated = value }
		
		/** Function or portion of uncompiled code to execute when any DisplayObject is added to
		 * this instance display list. An argument for binCommand.
		 * @see axl.xdef.types.display.xRoot#binCommand() */
		public function get onElementAdded():Object { return xonElementAdded }
		public function set onElementAdded(value:Object):void { xonElementAdded = value }
		
		
		//----------------------- INTERFACE METHODS -------------------- //
		//----------------------- INTERFACE SUPPORT -------------------- //
		/** Draws graphic commands  */
		protected function parseDef():void
		{
			if(xdef==null)
				return;
			XSupport.drawFromDef(def.graphics[0], this);
		}
		
		/** Executes defaultAddedToStageSequence +  Starts listening to ENTER_FRAME events 
		 * if <code>sortZ=true</code> @see axl.xdef.types.XSuppot#defaultAddedToStageSequence() */
		protected function addedToStageHandler(e:Event):void
		{
			xroot.support.defaultAddedToStageSequence(this);
			if(this.sortZ)
				this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		/**Removes ENTER_FRAME event listener if assigned +  Executes defaultRemovedFromStage
		 *  @see axl.xdef.types.XSuppot#defaultRemovedFromStageSequence() */
		protected function removeFromStageHandler(e:Event):void
		{ 
			this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			xroot.support.defaultRemovedFromStageSequence(this);
		}
		/** Executes <code>onElementAdded</code> if defined and redistributes children if 
		 * <code>distributeHorizontal</code> or <code>distrubuteVertical</code> defined*/
		protected function elementAddedHandler(e:Event):void 
		{ 
			if(onElementAdded is String)
				xroot.binCommand(onElementAdded,this);
			else if(onElementAdded is Function)
				onElementAdded();
			redistribute();
		}
		//----------------------- INTERFACE SUPPORT -------------------- //
		//----------------------- OVERRIDEN METHODS -------------------- //
		override public function addChild(child:DisplayObject):DisplayObject
		{
			super.addChild(child);
			var c:ixDisplay = child as ixDisplay;
			if(!c) return child;
			if(c.meta && c.meta.addChild != null)
			{
				XSupport.animByNameExtra(c, 'addChild');
			}
			return child;
		}
		
		override public function addChildAt(child:DisplayObject, index:int):DisplayObject
		{
			super.addChildAt(child, index);
			var c:ixDisplay = child as ixDisplay;
			if(!c) return child;
			if(c.meta && c.meta.addChild != null)
			{
				XSupport.animByNameExtra(c, 'addChildAt');
			}
			return child;
		}
		
		override public function removeChild(child:DisplayObject):DisplayObject
		{
			if(child == null)
				return child;
			var f:Function = super.removeChild;
			var c:ixDisplay = child as ixDisplay;
			if(!c) return child;
			if(c.meta && c.meta.removeChild != null)
			{
				AO.killOff(c);
				XSupport.animByNameExtra(c, 'removeChild', acomplete);
			} else { acomplete() }
			function acomplete():void { f(child); }
			return child;
		}
		
		override public function removeChildAt(index:int):DisplayObject
		{
			var f:Function = super.removeChildAt;
			var c:ixDisplay = super.getChildAt(index) as ixDisplay;
			if(!c) return null;
			if(c.meta && c.meta.removeChildAt != null)
			{
				AO.killOff(c);
				XSupport.animByNameExtra(c, 'removeChildAt', acomplete);
			} else { acomplete() } 
			function acomplete():void { f(index) }
			return c as DisplayObject;
		}
		//----------------------- OVERRIDEN METHODS -------------------- //
		//----------------------- INTERNAL METHODS -------------------- //
		private function onEnterFrame(e:Event):void
		{
			sort();
		}
		//----------------------- INTERNAL METHODS -------------------- //
		//----------------------- OTHER PUBLIC API -------------------- //
		/** Enables or disables depth sorting  */
		public function get sortZ():Boolean { return xsortZ;}
		public function set sortZ(v:Boolean):void
		{
			if(xsortZ == v)
				return
			xsortZ = v;
			if(!v)
				this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			else if(v && this.stage != null)
				this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		public function sort():void 
		{
			var i:int;
			var distArray:Array=[];
			var curMid:Vector3D;
			var curDist:Number;
			var observerPos:Vector3D=new Vector3D();
			observerPos.x=root.transform.perspectiveProjection.projectionCenter.x;
			observerPos.y=root.transform.perspectiveProjection.projectionCenter.y;
			observerPos.z=-root.transform.perspectiveProjection.focalLength;
			var numc:int = this.numChildren;
			var c:DisplayObject;
			for(i=0;i<numc;i++)
			{
				c = this.getChildAt(i);
				curMid=c.transform.getRelativeMatrix3D(root).position.clone();
				curDist=Math.sqrt(Math.pow(curMid.x-observerPos.x,2)+Math.pow(curMid.y-observerPos.y,2)+Math.pow(curMid.z-observerPos.z,2));
				distArray[i] = {distance:curDist,child:c}
			}
			
			distArray.sortOn("distance", Array.NUMERIC | Array.DESCENDING);
			i = distArray.length;
			while(i-->0)
			{
				this.setChildIndex(distArray[i].child, i);
			}
		}
		
		/** Combined scaleX and scaleY properties. Useful for maintaining aspect ratio whilst animations */
		public function set scale(v:Number):void{	scaleX = scaleY = v }
		public function get scale():Number { return (scaleX + scaleY)/2 }
		
		/** If <code>distributeHorizontal</code> or <code>distributeVertical</code> specified,
		 * runs through every child of this container and distributes it horizontally and/or 
		 * vertically. Called automatically on every Evetn.ADDED. @see #distributeHorizontal  
		 * @see #distributeVertical @see axl.utils.U#distribute()  @see axl.utils.U#distributePattern()*/
		public function redistribute():void
		{
			if(distributeHorizontal != null)
			{
				if(distributeHorizontal is Array)
					U.distributePattern(this,distributeHorizontal,true);
				else if(!isNaN(Number(distributeHorizontal)))
					U.distribute(this,Number(distributeHorizontal),true);
			}
			if(distributeVertical != null)
			{
				if(distributeVertical is Array)
					U.distributePattern(this,distributeVertical,false);
				else if(!isNaN(Number(distributeVertical)))
					U.distribute(this,Number(distributeVertical),false);
			}
		}
	}
}