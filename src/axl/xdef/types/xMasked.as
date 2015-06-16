package axl.xdef.types
{
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import axl.ui.controllers.BoundBox;
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
		
		public var container:Sprite;
		public var wheelScrollAllowed:Boolean = true;
		
		public function xMasked(definiton:XML=null)
		{
			ctrl = new BoundBox();
			shapeMask = new Shape();
			container = new Sprite();
			//container.mask = shapeMask;
			super(definiton);
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
		
		private function addListeners():void {
			ctrl.addEventListener(Event.CHANGE, maskedMovement);
				this.addEventListener(MouseEvent.MOUSE_WHEEL, wheelEvent) }
		
		protected function wheelEvent(e:MouseEvent):void {
			if(!wheelScrollAllowed) return;
			ctrl.movementVer(e.delta * deltaMultiply);
			ctrl.dispatchEvent(eventChange);
		}
		
		protected function scrollBarMovement(e:Event):void
		{
			ctrl.percentageVertical = 1 - scrollBar.controller.percentageVertical;
		}
		
		protected function maskedMovement(e:Event):void
		{
			if(scrollBar != null)
				scrollBar.controller.percentageVertical = 1 - ctrl.percentageVertical;
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
		
		/** determines scroll efficiency default 1. Passing font size + spacing */
		public function get deltaMultiplier():int { return deltaMultiply }
		public function set deltaMultiplier(value:int):void	{ deltaMultiply = value }
		
		/** returns controller */
		public function get controller():BoundBox { return ctrl }
		
	}
}