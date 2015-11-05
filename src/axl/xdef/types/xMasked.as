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
		public var scrollBar:xScroll;
		
		private var vWid:Number=1;
		private var vHeight:Number=1;
		private var shapeMask:Shape;
		private var maskObject:DisplayObject;
		
		private var fakeRect:Rectangle = new Rectangle();
		private var eventChange:Event = new Event(Event.CHANGE);
		private var ctrl:BoundBox;
		private var deltaMultiply:int=1;
		
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
			//container.mask = shapeMask;
			super(definiton,xroot);
			super.addChild(container);
			super.addChild(shapeMask);
			
			redrawMask();
			ctrl.bound = shapeMask;
			ctrl.box = container;
			maskObject = shapeMask;
			addListeners();

		}
		
		override public function addChild(child:DisplayObject):DisplayObject
		{
			if(child is xScroll)
			{
				scrollBar = child as xScroll;
				if(scrollBar.controller == null)
					throw new Error("scrollBar element needs elements named 'rail' and 'train'");
				scrollBar.controller.addEventListener(Event.CHANGE, scrollBarMovement);
				super.addChild(child);
			}
			else
				container.addChild(child);
			return child;
		}
		
		override protected function elementAdded(e:Event):void
		{
			if(!isNaN(distributeHorizontal))
				U.distribute(container,distributeHorizontal,true);
			if(!isNaN(distributeVertical))
				U.distribute(container,distributeVertical,false);
			if(onElementAdded != null)
				onElementAdded(e);
		}
		
		private function addListeners():void {
			ctrl.addEventListener(Event.CHANGE, maskedMovement);
			this.addEventListener(MouseEvent.MOUSE_WHEEL, wheelEvent) }
		
		protected function wheelEvent(e:MouseEvent):void {
			U.log(this, this.name, e,  wheelScrollAllowed);
			if(!wheelScrollAllowed) return;
			ctrl.movementVer(e.delta * deltaMultiply);
			ctrl.dispatchEvent(eventChange);
		}
		
		protected function scrollBarMovement(e:Event=null):void
		{
			ctrl.percentageVertical = 1 - scrollBar.controller.percentageVertical;
		}
		
		protected function maskedMovement(e:Event=null):void
		{
			if(scrollBar != null)
				scrollBar.controller.percentageVertical = 1 - ctrl.percentageVertical;
		}
		
		public function refreshToScrollBar():void
		{
			scrollBarMovement();
		}
		public function refreshToContent():void
		{
			maskedMovement()
		}
		
		override public function addChildAt(child:DisplayObject, index:int):DisplayObject
		{
			if(child is xScroll)
			{
				scrollBar = child as xScroll;
				if(scrollBar.controller == null)
					throw new Error("scrollBar element needs elements named 'rail' and 'train'");
				scrollBar.controller.addEventListener(Event.CHANGE, scrollBarMovement);
				super.addChildAt(child, index);
			}
			else
				container.addChildAt(child,index);
			return child
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
		public function get deltaMultiplier():int { return deltaMultiply }
		public function set deltaMultiplier(value:int):void	{ deltaMultiply = value }
		
		/** returns controller */
		public function get controller():BoundBox { return ctrl }
		
	}
}