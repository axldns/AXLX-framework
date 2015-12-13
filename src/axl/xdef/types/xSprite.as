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
	import flash.utils.clearInterval;
	
	import axl.utils.AO;
	import axl.utils.U;
	import axl.xdef.XSupport;
	import axl.xdef.interfaces.ixDisplay;
	
	public class xSprite extends Sprite implements ixDisplay
	{
		public var onElementAdded:Function;
		
		protected var xdef:XML;
		protected var xmeta:Object={};
		private var xxroot:xRoot;
		
		public var onAnimationComplete:Function;
		private var eventAnimComplete:Event = new Event(Event.COMPLETE);
		
		protected var xfilters:Array
		protected var xtrans:ColorTransform;
		protected var xtransDef:ColorTransform;
		private var intervalID:uint;
		public var distributeHorizontal:Number;
		public var distributeVertical:Number;
		private var metaAlreadySet:Boolean;
		public var reparseMetaEverytime:Boolean;
		public var reparsDefinitionEverytime:Boolean;
		public var resetOnAddedToStage:Boolean=true;
		private var addedToStageActions:Vector.<xAction>;
		private var childrenCreatedAction:Vector.<xAction>;
		
		public function xSprite(definition:XML=null,xrootObj:xRoot=null)
		{
			addEventListener(Event.ADDED, elementAdded);
			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
			addEventListener(Event.REMOVED_FROM_STAGE, removeFromStageHandler);
			this.xroot = xrootObj || this.xroot;
			if(this.xroot != null && definition != null)
				xroot.registry[String(definition.@name)] = this;
			else
				U.log("WARNING - ELEMENT HAS NO ROOT",xroot, 'OR NO DEF', definition? definition.name() + ' - ' + definition.@name : "NO DEF")
			xdef = definition;
			super();
			parseDef();
		}
		
		public function get xroot():xRoot { return xxroot }
		public function set xroot(v:xRoot):void	{ xxroot = v }
		
		override public function set name(v:String):void
		{
			super.name = v;
			if(this.xroot != null)
				this.xroot.registry.v = this;
		}
		
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
				intervalID = XSupport.animByNameExtra(this, 'addedToStage', animComplete);
			}
			if(addedToStageActions != null)
			{	for(var i:int = 0, j:int = addedToStageActions.length; i<j; i++)
				addedToStageActions[i].execute();
				U.log(this, this.name, '[addedToStage]', j, 'actions');
			}
		}
		
		protected function elementAdded(e:Event):void
		{
			if(!isNaN(distributeHorizontal))
				U.distribute(this,distributeHorizontal,true);
			if(!isNaN(distributeVertical))
				U.distribute(this,distributeVertical,false);
			if(onElementAdded != null)
				onElementAdded(e);
		}
		
		public function onChildrenCreated():void
		{
			if(childrenCreatedAction != null)
			{	for(var i:int = 0, j:int = childrenCreatedAction.length; i<j; i++)
					childrenCreatedAction[i].execute();
				U.log(this, this.name, '[childrenCreatedAction]', j, 'actions');
			}
		}
		
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
		
		
		public function get eventAnimationComplete():Event {return eventAnimComplete }
		public function reset():void {
			AO.killOff(this);
			XSupport.applyAttributes(def, this);	
		}
		public function get def():XML { return xdef }
		public function set def(value:XML):void 
		{ 
			if((value == null) || (xdef != null && xdef is XML && !reparsDefinitionEverytime))
				return;
			xdef = value;
			parseDef();
		}
		
		private function animComplete():void {	this.dispatchEvent(this.eventAnimationComplete) }
		
		override public function addChild(child:DisplayObject):DisplayObject
		{
			super.addChild(child);
			var c:ixDisplay = child as ixDisplay;
			if(c != null && c.meta.addChild != null)
			{
				c.reset();
				XSupport.animByNameExtra(c, 'addChild', animComplete);
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
				XSupport.animByNameExtra(c, 'addChild',animComplete);
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
		
		public function linkButton(xmlName:String, onClick:Function):xButton
		{
			var b:xButton = getChildByName(xmlName) as xButton;
			if(b != null)
			{
				b.onClick = onClick;
				this.setChildIndex(b, this.numChildren-1);
			}
			return b;
		}
	}
}