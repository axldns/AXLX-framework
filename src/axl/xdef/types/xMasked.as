package axl.xdef.types
{
	import flash.events.Event;
	
	import axl.ui.MaskedScrollable;

	public class xMasked extends xSprite
	{
		public var scrollBar:xScroll;
		public var masked:MaskedScrollable;
		public function xMasked(definiton:XML=null)
		{
			super(definiton);
		}
		
		override protected function elementAdded(e:Event):void
		{
			if(e.target is xScroll)
			{
				scrollBar = e.target as xScroll;
				if(scrollBar.controler == null)
					throw new Error("scrollBar element needs elements named 'rail' and 'train'");
				scrollBar.controler.addEventListener(Event.CHANGE, scrollBarMovement);
			}
			else if(e.target is MaskedScrollable)
			{
				masked = e.target as MaskedScrollable;
				masked.controler.refresh();
				masked.controler.addEventListener(Event.CHANGE, maskedMovement);
			}
		}
		
		protected function maskedMovement(e:Event):void
		{
			if(scrollBar != null)
				scrollBar.controler.percentageVertical = 1 - masked.controler.percentageVertical;
		}
		
		protected function scrollBarMovement(e:Event):void
		{
			if(masked != null)
				masked.controler.percentageVertical = 1 - scrollBar.controler.percentageVertical;
		}
	}
}