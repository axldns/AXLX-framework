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
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import axl.ui.controllers.BoundBox;
	import axl.utils.U;
	import axl.xdef.interfaces.ixDisplay;

	public class xMasked extends xSprite implements ixDisplay
	{
		private var xscrollBar:xScroll;
		
		private var vWid:Number=1;
		private var vHeight:Number=1;
		private var shapeMask:Shape;
		private var maskObject:DisplayObject;
		
		private var fakeRect:Rectangle = new Rectangle();
		private var eventChange:Event = new Event(Event.CHANGE);
		private var ctrl:BoundBox;
		private var deltaMultiply:Number=1;
		
		public var container:xSprite;
		public var wheelScrollAllowed:Boolean = true;
		private var vX:Number=0;
		private var vY:Number=0;
		
		public function xMasked(definiton:XML=null,xroot:xRoot=null)
		{
			ctrl = new BoundBox();
			shapeMask = new Shape();
			container = new xSprite(null,xroot);
			container.name = "maskContainerOf_" + String((definiton != null) ? definiton.@name : "null");
			super(definiton,xroot);
			super.addChild(container);
			super.addChild(shapeMask);
			
			redrawMask();
			ctrl.bound = shapeMask;
			ctrl.box = container;
			maskObject = shapeMask;
			addListeners();

		}
		
		public function get scrollBar():xScroll	{ return xscrollBar }
		public function set scrollBar(v:xScroll):void
		{
			xscrollBar = v;
			if(xscrollBar.controller == null)
				throw new Error("scrollBar element needs elements named 'rail' and 'train'");
			xscrollBar.controller.onChange = controller2Change;
		}

		override public function addChild(child:DisplayObject):DisplayObject
		{
			var v:xScroll = child as xScroll;
			if(v)
			{
				scrollBar = v;
				super.addChild(child);
			}
			else
				container.addChild(child);
			return child;
		}
		
		override public function addChildAt(child:DisplayObject, index:int):DisplayObject
		{
			var v:xScroll = child as xScroll;
			if(v)
			{
				scrollBar = v;
				super.addChildAt(child, index);
			}
			else
				container.addChildAt(child,index);
			return child
		}
		
		override protected function elementAdded(e:Event):void
		{
			if(!isNaN(distributeHorizontal))
				U.distribute(container,distributeHorizontal,true);
			if(!isNaN(distributeVertical))
				U.distribute(container,distributeVertical,false);
		}
		
		private function addListeners():void {
			ctrl.onChange = controller1Change;
			container.addEventListener(MouseEvent.MOUSE_WHEEL, wheelEvent) 
		}
		private function controller1Change(e:Object=null):void
		{
			if((scrollBar == null) || e==scrollBar.controller)
				return;
			scrollBar.controller.percentageCommon( 1-ctrl.percentageHorizontal,1- ctrl.percentageVertical,false,ctrl);
		}
		
		private function controller2Change (e:Object=null):void
		{
			if(e==ctrl)
				return;
			ctrl.percentageCommon(1-scrollBar.controller.percentageHorizontal, 1-scrollBar.controller.percentageVertical,false,scrollBar.controller);
		}
			
		protected function wheelEvent(e:MouseEvent):void 
		{
			if(!wheelScrollAllowed || e.delta==0)
				return;
			if(ctrl.vertical)
				ctrl.movementVer(e.delta * deltaMultiply,false,ctrl);
			else if(ctrl.horizontal)
				ctrl.movementHor(e.delta * deltaMultiply,false,ctrl);
		}
		
		private function redrawMask():void
		{
			shapeMask.graphics.clear();
			shapeMask.graphics.beginFill(0);
			shapeMask.graphics.drawRect(0,0,visibleWidth, visibleHeight);
			shapeMask.x = vX;
			shapeMask.y = vY;
			container.mask =shapeMask;
		}
		
		// -------------------------------- PUBLIC API ---------------------------------- //
		public function get visibleHeight():Number { return vHeight }
		public function set visibleHeight(value:Number):void
		{
			vHeight = value;
			redrawMask();
		}
		
		public function get visibleWidth():Number { return vWid }
		public function set visibleWidth(value:Number):void
		{
			vWid = value;
			redrawMask();
		}
		
		public function get visibleX():Number { return vX }
		public function set visibleX(v:Number):void
		{
			vX = v;
			redrawMask();
		}
		
		public function get visibleY():Number { return vY }
		public function set visibleY(v:Number):void
		{
			vY = v;
			redrawMask();
		}
		
		public function setMask(v:DisplayObject):void
		{
			if(maskObject != null && contains(maskObject))
				removeChild(maskObject);
			if(shapeMask != null && contains(shapeMask))
				removeChild(shapeMask);
			maskObject = v;
			this.addChild(maskObject);
			container.mask = maskObject;
		}
		
		/** determines scroll efficiency default 1. Passing font size + spacing */
		public function get deltaMultiplier():Number { return deltaMultiply }
		public function set deltaMultiplier(value:Number):void	{ deltaMultiply = value }
		
		/** returns controller */
		public function get controller():BoundBox { return ctrl }
		
	}
}