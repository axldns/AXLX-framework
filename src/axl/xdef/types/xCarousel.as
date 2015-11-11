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
	import flash.events.Event;
	
	import axl.ui.Carusele;
	import axl.utils.AO;
	import axl.utils.U;
	import axl.xdef.XSupport;
	import axl.xdef.interfaces.ixDef;
	
	public class xCarousel extends Carusele implements ixDef
	{
		public var onElementAdded:Function;
		private var addedToRail:xAction;
		
		private var xdef:XML;
		private var xmeta:Object = {}
		private var xxroot:xRoot;
		
		public var resetOnAddedToStage:Boolean = true;
		public var reparseMetaEverytime:Boolean=false;
		public var reparsDefinitionEverytime:Boolean=false;
		private var metaAlreadySet:Boolean;
		
		public function xCarousel(definition:XML,xrootObj:xRoot=null)
		{
			xdef = definition;
			this.xroot = xrootObj || xroot;
			super();
			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
			parseDef();
		}
		public function get xroot():xRoot { return xxroot }
		public function set xroot(v:xRoot):void	{ xxroot = v }
		protected function addedToStageHandler(e:Event):void
		{
			if(resetOnAddedToStage)
				this.reset();
			if(meta.addedToStage == null)
				return;
			XSupport.animByNameExtra(this, 'addedToStage');
		}
		
		public function get def():XML { return xdef }
		public function get meta():Object { return xmeta }
		public function set meta(v:Object):void {
			if(metaAlreadySet && !reparseMetaEverytime)
				return;
			if(v is String)
				return;
			xmeta =v;
			metaAlreadySet = true;
			
		}
		public function reset():void { 
			AO.killOff(this);
			XSupport.applyAttributes(def, this);	
		}
		
		public function set def(value:XML):void { 
			xdef = value;
			parseDef();
		}
		
		protected function parseDef():void
		{
			if(xdef==null)
				return;
			XSupport.drawFromDef(def.graphics[0], this);
			// this is exceptional where attributes are being applied before pushed types
			//moved to XSupport
			/*XSupport.applyAttributes(def, this);
			XSupport.pushReadyTypes(def, this, 'addToRail');*/
			movementBit(0);
		}

	

		
	}
}