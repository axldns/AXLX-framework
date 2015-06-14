package axl.xdef.types
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import axl.ui.controllers.BoundBox;

	public class xScroll extends xSprite
	{
		
		private var rail:DisplayObject;
		private var train:DisplayObject;
		private var boxControll:BoundBox;
		private var btnUp:xButton;
		private var btnRight:xButton;
		private var btnLeft:xButton;
		private var btnDown:xButton;
		private var eventChange:Event;
		private var percentButtonMovemnt:Boolean;
		private var deltaMultiply:int=1;
		
		
		public function xScroll(def:XML)
		{
			makeBox();
			eventChange = new Event(Event.CHANGE);
			this.addEventListener(Event.ADDED, elementAdded);
			this.addEventListener(MouseEvent.MOUSE_WHEEL, wheelEvent);
			super(def);
		}
		
		protected function wheelEvent(e:MouseEvent):void
		{
			boxControll.movementVer((e.delta * deltaMultiply) * -1);
			boxControll.dispatchEvent(eventChange);
		}
		
		private function makeBox():void
		{
			boxControll = new BoundBox();
			boxControll.bound = rail;
			boxControll.box = train;
			//boxControll.verticalBehavior = BoundBox.inscribed;
		}
		
		override protected function elementAdded(e:Event):void
		{
			trace("XSCROLL ELEMENT", e.target.name);
			switch (e.target.name)
			{
				case 'rail': rail = boxControll.bound = e.target as DisplayObject; break;
				case 'train': train = boxControll.box = e.target as DisplayObject; break;
				
				case 'btnUp': btnUp = this.linkButton('btnUp', buttonHandler); break;
				case 'btnDown': btnDown = this.linkButton('btnDown', buttonHandler); break;
				case 'btnLeft': btnLeft = this.linkButton('btnLeft', buttonHandler); break;
				case 'btnRight': btnRight = this.linkButton('btnRight', buttonHandler); break;
			}
		}
		
		private function buttonHandler(e:Event):void
		{
			if(boxControll == null)
				return;
			if(percentButtonMovemnt)
			{
				switch(e.target)
				{
					case btnUp: boxControll.percentageVertical -= deltaMultiply; break;
					case btnDown: boxControll.percentageVertical += deltaMultiply; break;
					case btnLeft: boxControll.percentageHorizontal -= deltaMultiply; break;
					case btnRight: boxControll.percentageHorizontal += deltaMultiply; break;
				}
			}
			else
			{
				switch(e.target)
				{
					case btnUp: boxControll.movementVer(-deltaMultiply); break;
					case btnDown: boxControll.movementVer(deltaMultiply); break;
					case btnLeft: boxControll.movementHor(-deltaMultiply); break;
					case btnRight: boxControll.movementHor(deltaMultiply); break;
				}
			}
			boxControll.dispatchChange();
		}
			
		public function get controller():BoundBox { return boxControll }
		
		/** determines scroll efficiency default 1. Passing font size + spacing */
		public function get deltaMultiplier():int { return deltaMultiply }
		public function set deltaMultiplier(value:int):void	{ deltaMultiply = value }
	}
}