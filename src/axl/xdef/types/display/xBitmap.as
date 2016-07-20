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
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	
	import axl.utils.AO;
	import axl.xdef.XSupport;
	import axl.xdef.interfaces.ixDisplay;
	/** Most basic object for displaying images. Since this class extends flash.display.Bitmap -
	 * it does not dispatch/receive mouse events. 
	 * Instantiated from:<h3><code>&lt;img/&gt;<br></code></h3>
	 * Img nodes can not consist sub-nodes translatable to other display object (can't contain children).
	 * Allowed sub-nodes:<pre><ul><li>&lt;act/&gt;</li><li>&lt;data/&gt;</li><li>&lt;script/&gt;</li><li>&lt;timer/&gt;</li><li>&lt;filters/&gt;</li><li>&lt;colorTransform/&gt;</li></ul></pre>
	 * @see axl.xdef.XSupport#getReadyType2() */
	public class xBitmap extends Bitmap implements ixDisplay
	{
		private var xdef:XML;
		private var xmeta:Object;
		private var xxroot:xRoot;
		private var xonAddedToStage:Object;
		private var xonRemovedFromStage:Object;
		private var xresetOnAddedToStage:Boolean = true;
		private var xstyles:Object;
		
		/** Most basic Class for displaying images, instantiated from: <code>&lt;img/&gt;<br></code>
		 * @param definition - xml definition
		 * @param xroot - reference to parent xRoot object
		 * @see axl.xdef.types.display.xBitmap
		 * @see axl.xdef.interfaces.ixDef#def
		 * @see axl.xdef.interfaces.ixDef#xroot
		 * @see axl.xdef.XSupport#getReadyType2()  */
		public function xBitmap(bitmapData:BitmapData=null, pixelSnapping:String="auto", smoothing:Boolean=true,xrootObj:xRoot=null,definition:XML=null)
		{
			this.xroot = xrootObj || xroot;
			xdef = definition;
			xroot.support.register(this);
			
			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
			addEventListener(Event.REMOVED_FROM_STAGE, removeFromStageHandler);
			super(bitmapData, pixelSnapping, smoothing);
		}
		
		//----------------------- INTERFACE METHODS -------------------- //
		/** XML definition of this object @see axl.xdef.interfaces.ixDef#def */
		public function get def():XML { return xdef }
		public function set def(value:XML):void 
		{ 
			if((value == null))
				return;
			xdef = value;
			XSupport.applyAttributes(def, this);
		}
		/** Reference to parent xRoot object @see axl.xdef.types.display.xRoot 
		 *  @see axl.xdef.interfaces.ixDef#xroot*/
		public function get xroot():xRoot { return xxroot }
		public function set xroot(v:xRoot):void	{ xxroot = v }
		
		/**
		 * Dynamic variables container. It's set up only once. Subsequent applying XML attributes
		 * or calling reset() will not have an effect. 
		 * <h3>xBitmap meta keywords</h3>
		 * <ul>
		 * <li>"addedToStage" - animation(s) to execute when added to stage</li>
		 * <li>"addChild" - animation to execute when added as a child</li>
		 * <li>"removeChild" - animation to execute before removing from stage (delays removing from stage)
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
		 * @see axl.xdef.types.display.xRoot.registry @xee axl.xdef.interfaces.ixDef#name */
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
		
		//----------------------- INTERFACE METHODS -------------------- //
		//----------------------- INTERFACE SUPPORT -------------------- //
		/** Executes defaultAddedToStageSequence +  Starts listening to ENTER_FRAME events 
		 * if <code>sortZ=true</code> @see axl.xdef.types.XSuppot#defaultAddedToStageSequence() */
		protected function addedToStageHandler(e:Event):void
		{
			xroot.support.defaultAddedToStageSequence(this);
		}
		
		/**Removes ENTER_FRAME event listener if assigned +  Executes defaultRemovedFromStage
		 *  @see axl.xdef.types.XSuppot#defaultRemovedFromStageSequence() */
		protected function removeFromStageHandler(e:Event):void
		{ 
			xroot.support.defaultRemovedFromStageSequence(this);
		}
		//----------------------- INTERFACE SUPPORT -------------------- //
		/** sets both scaleX and scaleY to the same value*/
		public function set scale(v:Number):void{	scaleX = scaleY = v }
		/** returns average of scaleX and scaleY */
		public function get scale():Number { return (scaleX + scaleY)/2 }
	}
}