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
		private var addedToRail:xAction;
		
		private var xdef:XML;
		private var xmeta:Object = {}
		private var xxroot:xRoot;
		
		public var resetOnAddedToStage:Boolean = true;
		public var reparseMetaEverytime:Boolean=false;
		public var reparsDefinitionEverytime:Boolean=false;
		private var metaAlreadySet:Boolean;
		private var addedToStageActions:Vector.<xAction>;
		private var childrenCreatedAction:Vector.<xAction>;
		
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
			if(addedToStageActions != null)
			{	for(var i:int = 0, j:int = addedToStageActions.length; i<j; i++)
				addedToStageActions[i].execute();
				if(debug) U.log(this, this.name, '[addedToStage]', j, 'actions');
			}
		}
		
		public function onChildrenCreated():void
		{
			if(childrenCreatedAction != null)
			{	for(var i:int = 0, j:int = childrenCreatedAction.length; i<j; i++)
					childrenCreatedAction[i].execute();
				if(debug) U.log(this, this.name, '[childrenCreatedAction]', j, 'actions');
			}
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