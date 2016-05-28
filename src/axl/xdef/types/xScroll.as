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
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import axl.ui.controllers.BoundBox;

	public class xScroll extends xSprite
	{
		private var boxControll:BoundBox;
		private var deltaMultiply:Number=1;
		public var rail:DisplayObject;
		public var train:DisplayObject;
		public var btnUp:xButton;
		public var btnRight:xButton;
		public var btnLeft:xButton;
		public var btnDown:xButton;
		
		public var wheelScrollAllowed:Boolean=true;
		
		public function xScroll(def:XML,rootObj:xRoot)
		{
			makeBox();
			this.addEventListener(MouseEvent.MOUSE_WHEEL, wheelEvent);
			super(def,rootObj);
		}
		
		protected function wheelEvent(e:MouseEvent):void
		{
			if(!wheelScrollAllowed || e.delta==0) 
				return;
			//U.log(this, this.name,boxControll.vertical ? 'vertical': "", boxControll.horizontal ? "horizontal" :"", 'delta:', e.delta,  'multply:', deltaMultiply, 'v:',  e.delta * deltaMultiply );
			if(boxControll.vertical)
				boxControll.movementVer((e.delta * deltaMultiply) * -1,false,boxControll);
			else if(boxControll.horizontal)
				boxControll.movementHor((e.delta * deltaMultiply) * -1,false,boxControll);
		}
		
		private function makeBox():void
		{
			boxControll = new BoundBox();
			boxControll.bound = rail;
			boxControll.box = train;
		}
		
		override protected function elementAddedHandler(e:Event):void
		{
			super.elementAddedHandler(e);
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
			
			switch(e.target)
			{
				case btnUp: boxControll.movementVer(-deltaMultiply,false,this); break;
				case btnDown: boxControll.movementVer(deltaMultiply,false,this); break;
				case btnLeft: boxControll.movementHor(-deltaMultiply,false,this); break;
				case btnRight: boxControll.movementHor(deltaMultiply,false,this); break;
			}
			boxControll.dispatchChange();
		}
			
		public function get controller():BoundBox { return boxControll }
		
		/** determines scroll efficiency default 1. Passing font size + spacing */
		public function get deltaMultiplier():Number { return deltaMultiply }
		public function set deltaMultiplier(value:Number):void	{ deltaMultiply = value }
		
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