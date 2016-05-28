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
	import flash.events.Event;
	
	import axl.ui.Carusele;
	import axl.utils.AO;
	import axl.xdef.XSupport;
	import axl.xdef.interfaces.ixDisplayContainer;
	
	public class xCarousel extends Carusele implements ixDisplayContainer
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
		
		/** Portion of uncompiled code to execute when object is created and attributes are applied. 
		 * 	Runs only once. An argument for binCommand. Does not have to be dolar sign prefixed.
		 * @see axl.xdef.types.xRoot#binCommand() */
		public var inject:String;
		
		public function xCarousel(definition:XML,xrootObj:xRoot=null)
		{
			this.xroot = xrootObj || this.xroot;
			this.xdef = definition;
			xroot.support.register(this);
			
			super();
			rail.addEventListener(Event.ADDED, elementAddedHandler);
			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
			addEventListener(Event.REMOVED_FROM_STAGE, removeFromStageHandler);
			
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
		/** Reference to parent xRoot object @see axl.xdef.types.xRoot 
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
		 * <li>"removeChild" - animation to execute before removing from stage (delays removing from stage)</li>
		 * instantiated and added to this instance</li>
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
		 * @see axl.xdef.types.xRoot.registry @xee axl.xdef.interfaces.ixDef#name */
		override public function set name(v:String):void
		{
			super.name = xroot.support.requestNameChange(v,this);
		}
		
		/** Kills all animations proceeding and sets initial (xml-def-attribute-defined) values to 
		 * this object
		 * @see axl.xdef.XSupport#applyAttrubutes()
		 * @see #resetOnAddedToStage
		 * @see #reparseMetaEverytime */
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
		 *  An argument for binCommand. @see axl.xdef.types.xRoot#binCommand() */
		public function get onRemovedFromStage():Object	{ return xonRemovedFromStage }
		public function set onRemovedFromStage(value:Object):void {	xonRemovedFromStage = value }
		
		/** Function or portion of uncompiled code to execute when object is added to stage. An argument for binCommand.
		 * @see axl.xdef.types.xRoot#binCommand() */
		public function get onAddedToStage():Object { return xonAddedToStage }
		public function set onAddedToStage(value:Object):void {	xonAddedToStage = value }
		
		/** Determines if object is going to be brought to it's original XML defined values. 
		 * @see axl.interfaces.ixDisplay#resetOnAddedToStage */
		public function get resetOnAddedToStage():Boolean {	return xresetOnAddedToStage }
		public function set resetOnAddedToStage(value:Boolean):void { xresetOnAddedToStage = value}
		
		/** Function or portion of uncompiled code to execute when all original structure xml children are
		 * added to container's display list. An argument for binCommand.
		 * @see axl.xdef.types.xRoot#binCommand() */
		public function get onChildrenCreated():Object { return xonChildrenCreated }
		public function set onChildrenCreated(value:Object):void { xonChildrenCreated = value }
		
		/** Function or portion of uncompiled code to execute when any DisplayObject is added to
		 * this instance display list. An argument for binCommand.
		 * @see axl.xdef.types.xRoot#binCommand() */
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
			this.movementBit(0);
		}
		/** Resets instance to original XML values if <code>resetOnAddedToSage=true</code>.<br>
		 * Executes <i>meta.addedToStage</i> defined animations if any.<br>
		 * Executes function or evaluates code assigned to <code>onAddedToStage</code> property.<br>
		 * Starts listening to ENTER_FRAME events if <code>sortZ=true</code>*/
		protected function addedToStageHandler(e:Event):void
		{
			xroot.support.defaultAddedToStageSequence(this);
		}
		
		/** Removes ENTER_FRAME event listener if assigned, stops all proceeding and scheduled animations
		 * on this instance, Executes function or evaluates code assigned to <code>onRemovedFromStage</code> property.<br>*/
		protected function removeFromStageHandler(e:Event):void
		{ 
			xroot.support.defaultRemovedFromStageSequence(this);
		}
		
		protected function elementAddedHandler(e:Event):void 
		{ 
			if(onElementAdded is String)
				xroot.binCommand(onElementAdded,this);
			else if(onElementAdded is Function)
				onElementAdded();
			this.movementBit(0);
		}
		//----------------------- INTERFACE SUPPORT -------------------- //
		//----------------------- OTHER PUBLIC API -------------------- //
		/** sets both scaleX and scaleY to the same value*/
		public function set scale(v:Number):void{	scaleX = scaleY = v }
		/** returns average of scaleX and scaleY */
		public function get scale():Number { return scaleX + scaleY>>1 }
	}
}