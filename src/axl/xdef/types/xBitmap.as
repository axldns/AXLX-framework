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
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.geom.ColorTransform;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
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
		private var intervalID:uint;
		public var resetOnAddedToStage:Boolean = true;
		public var reparseMetaEverytime:Boolean=false;
		public var reparsDefinitionEverytime:Boolean=false;
		private var metaAlreadySet:Boolean;
		
		public function xBitmap(bitmapData:BitmapData=null, pixelSnapping:String="auto", smoothing:Boolean=true,xrootObj:xRoot=null)
		{
			this.xroot = xrootObj || xroot;
			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
			addEventListener(Event.REMOVED_FROM_STAGE, removeFromStageHandler);
			super(bitmapData, pixelSnapping, smoothing);
			
		}
		public function get xroot():xRoot { return xxroot }
		public function set xroot(v:xRoot):void	{ xxroot = v }
		
		protected function removeFromStageHandler(e:Event):void
		{
			AO.killOff(this);
			clearInterval(intervalID);
		}
		
		protected function addedToStageHandler(e:Event):void
		{
			if(resetOnAddedToStage)
				this.reset();
			if(meta.addedToStage != null)
			{
				intervalID = XSupport.animByNameExtra(this, 'addedToStage');
			}
		}
	
		public function get meta():Object { return xmeta }
		public function set meta(v:Object):void { 
			if(metaAlreadySet && !reparseMetaEverytime)
				return;
			if(v is String)
				return
			xmeta =v;
			metaAlreadySet = true;
		}
		
		
		public function get def():XML { return xdef }
		public function set def(value:XML):void { 
			if(value == null)
				return;
			else if(xdef != null && xdef is XML && !reparsDefinitionEverytime)
				return;
			xdef = value;
			parseDef();
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