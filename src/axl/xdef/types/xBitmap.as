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
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.geom.ColorTransform;
	
	import axl.utils.AO;
	import axl.utils.U;
	import axl.xdef.XSupport;
	import axl.xdef.interfaces.ixDisplay;
	
	
	public class xBitmap extends Bitmap implements ixDisplay
	{
		protected var xdef:XML;
		protected var xmeta:Object={};
		private var xxroot:xRoot;
		private var xtrans:ColorTransform;
		private var xtransDef:ColorTransform;
		private var xfilters:Array;
		private var metaAlreadySet:Boolean;
		private var addedToStageActions:Vector.<xAction>;
		
		/** Every time object is (re)added to stage method <code>reset</code> can be called. 
		 * Aim of method reset is to bring object to its initial state (defined by xml) by reparsing it's attributes
		 * and killing all animations @see #reset() */
		public var resetOnAddedToStage:Boolean = true;
		/** Every time META object is set (directly or indirectly - via <code>reset - XSupport.applyAttributes</code>
		 * method) object can be rebuild or set just once per existence @default false @see #reset() */
		public var reparseMetaEverytime:Boolean=false;
		/** Every time object XML definition is set definition can be re-read. For <code>xSprite</code> it 
		 * affects graphics drawing only. Pushing children inside happens only once per existence in
		 *  <code>XSupport.getReadyType2 - pushReadyTypes2</code>  @default false 
		 * @see axl.xdef.XSupport#getReadyType2() @see axl.xdef.XSupport#pushReadyTypes2() */
		public var reparsDefinitionEverytime:Boolean=false;
		/** Determines if debugging info is printed to consle*/
		public var debug:Boolean;
		/** Portion of uncompiled code to execute when object is added to stage. An argument for binCommand.
		 * Does not have to be dolar sign prefixed.
		 * @see axl.xdef.types.xRoot#binCommand() */
		public var onAddedToStage:String;
		/** Portion of uncompiled code to execute when object isremoved from stage. An argument for binCommand.
		 * Does not have to be dolar sign prefixed.
		 * @see axl.xdef.types.xRoot#binCommand() */
		public var onRemovedFromStage:String;
		
		public function xBitmap(bitmapData:BitmapData=null, pixelSnapping:String="auto", smoothing:Boolean=true,xrootObj:xRoot=null,definition:XML=null)
		{
			this.xroot = xrootObj || xroot;
			if(this.xroot != null && definition != null)
			{
				var v:String = String(definition.@name);
				if(v.charAt(0) == '$' )
					v = xroot.binCommand(v.substr(1), this);
				this.name = v;
				xroot.registry[this.name] = this;
			}
			else
				U.log("WARNING - ELEMENT HAS NO ROOT",xroot, 'OR NO DEF', definition? definition.name() + ' - ' + definition.@name : "NO DEF");
			
			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
			addEventListener(Event.REMOVED_FROM_STAGE, removeFromStageHandler);
			super(bitmapData, pixelSnapping, smoothing);
		}
		public function get xroot():xRoot { return xxroot }
		public function set xroot(v:xRoot):void	{ xxroot = v }
		
		protected function removeFromStageHandler(e:Event):void
		{
			AO.killOff(this);
			if(onRemovedFromStage != null)
				xroot.binCommand(onRemovedFromStage,this);
		}
		
		/** sets both scaleX and scaleY to the same value*/
		public function set scale(v:Number):void{	scaleX = scaleY = v }
		/** returns average of scaleX and scaleY */
		public function get scale():Number { return scaleX + scaleY>>1 }
		
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
			if(onAddedToStage != null)
				xroot.binCommand(onAddedToStage,this);
		}
	
		public function get meta():Object { return xmeta }
		public function set meta(v:Object):void { 
			if(v is String)
				throw new Error("Invalid json for element " +  def.localName() + ' ' +  def.@name );
			if((metaAlreadySet && !reparseMetaEverytime))
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
		}
		
		override public function set name(v:String):void
		{
			super.name = v;
			if(this.xroot != null)
				this.xroot.registry.v = this;
		}
		
		public function get def():XML { return xdef }
		public function set def(value:XML):void { 
			if(value == null)
				return;
			else if(xdef != null && xdef is XML && !reparsDefinitionEverytime)
				return;
			xdef = value;
		}
		public function reset():void { 
			AO.killOff(this);
			parseDef()
		}
		
		protected function parseDef():void 
		{ 
			XSupport.applyAttributes(def, this);
		}
		
		public function get xtransform():ColorTransform { return xtrans }
		public function set xtransform(v:ColorTransform):void { xtrans =v; this.transform.colorTransform = v;
			if(xtransDef == null)
				xtransDef = new ColorTransform();
		}
		public function set transformOn(v:Boolean):void { this.transform.colorTransform = (v ? xtrans : xtransDef ) }
		
		override public function set filters(v:Array):void
		{
			xfilters = v;
			super.filters=v;
		}
		
		public function set filtersOn(v:Boolean):void {	super.filters = (v ? xfilters : null) }
		public function get filtersOn():Boolean { return filters != null }
		
		
		public function ctransform(prop:String,val:Number):void {
			if(!xtrans)
				xtrans = new ColorTransform();
			xtrans[prop] = val;
			this.transform.colorTransform = xtrans;
		}
		
	}
}