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
	import axl.utils.U;
	import axl.xdef.XSupport;
	import axl.xdef.interfaces.ixDef;
	
	public class xCarousel extends Carusele implements ixDef
	{
		private var xdef:XML;
		private var xmeta:Object = {}
		private var xxroot:xRoot;
		private var metaAlreadySet:Boolean;
		
		public var resetOnAddedToStage:Boolean = true;
		public var reparseMetaEverytime:Boolean=false;
		public var reparsDefinitionEverytime:Boolean=false;
		
		/** Function or portion of uncompiled code to execute when all original structure xml children are
		 * added to container's display list. An argument for binCommand.
		 * Does not have to be dolar sign prefixed.
		 * @see axl.xdef.types.xRoot#binCommand() */
		public var onChildrenCreated:Object;
		
		/** Function or portion of uncompiled code to execute when object is added to stage. An argument for binCommand.
		 * Does not have to be dolar sign prefixed.
		 * @see axl.xdef.types.xRoot#binCommand() */
		public var onAddedToStage:Object;
		/** Function or portion of uncompiled code to execute when object is removed from stage. An argument for binCommand.
		 * Does not have to be dolar sign prefixed.
		 * @see axl.xdef.types.xRoot#binCommand() */
		public var onRemovedFromStage:Object;
		
		/** Portion of uncompiled code to execute when object is created and attributes are applied. 
		 * 	Runs only once. An argument for binCommand. Does not have to be dolar sign prefixed.
		 * @see axl.xdef.types.xRoot#binCommand() */
		public var inject:String;
		
		public function xCarousel(definition:XML,xrootObj:xRoot=null)
		{
			xdef = definition;
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
				U.log("WARNING - ELEMENT HAS NO ROOT",xroot, 'OR NO DEF', definition? definition.name() + ' - ' + definition.@name : "NO DEF")
			super();
			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
			addEventListener(Event.REMOVED_FROM_STAGE, removeFromStageHandler);
			parseDef();
		}
		public function get xroot():xRoot { return xxroot }
		public function set xroot(v:xRoot):void	{ xxroot = v }
		protected function addedToStageHandler(e:Event):void
		{
			if(resetOnAddedToStage)
				this.reset();
			if(meta.addedToStage != null)
				XSupport.animByNameExtra(this, 'addedToStage');
			if(onAddedToStage is String)
				xroot.binCommand(onAddedToStage,this);
			else if(onAddedToStage is Function)
				onAddedToStage();
		}
		protected function removeFromStageHandler(e:Event):void
		{
			AO.killOff(this);
			if(onRemovedFromStage is String)
				xroot.binCommand(onRemovedFromStage,this);
			else if(onRemovedFromStage is Function)
				onRemovedFromStage();
		}
				
		/** sets both scaleX and scaleY to the same value*/
		public function set scale(v:Number):void{	scaleX = scaleY = v }
		/** returns average of scaleX and scaleY */
		public function get scale():Number { return scaleX + scaleY>>1 }
		
		public function get def():XML { return xdef }
		public function get meta():Object { return xmeta }
		public function set meta(v:Object):void {
			if(v is String)
				throw new Error("Invalid json for element " +  def.localName() + ' ' +  def.@name );
			if((metaAlreadySet && !reparseMetaEverytime))
				return;
			xmeta =v;
			metaAlreadySet = true;
			var a:Object, b:Array, i:int, j:int;
		}
		public function reset():void { 
			AO.killOff(this);
			XSupport.applyAttributes(def, this);	
		}
		
		public function set def(value:XML):void {
			if(xdef != null || value == null)
				return;
			xdef = value;
			parseDef();
		}
		
		override public function set name(v:String):void
		{
			super.name = v;
			if(this.xroot != null)
				this.xroot.registry.v = this;
		}
		
		protected function parseDef():void
		{
			if(xdef==null)
				return;
			XSupport.drawFromDef(def.graphics[0], this);
			movementBit(0);
		}
	}
}