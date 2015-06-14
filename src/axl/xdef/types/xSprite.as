package axl.xdef.types
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	
	import axl.utils.AO;
	import axl.xdef.XSupport;
	import axl.xdef.interfaces.ixDisplay;
	
	public class xSprite extends Sprite implements ixDisplay
	{
		public var onElementAdded:Function;
		
		protected var xdef:XML;
		protected var xmeta:Object={};
		public var onAnimationComplete:Function;
		private var eventAnimComplete:Event = new Event(Event.COMPLETE);
		
		public function xSprite(definition:XML=null)
		{
			addEventListener(Event.ADDED, elementAdded);
			xdef = definition;
			super();
			parseDef();
		}
		
		protected function elementAdded(e:Event):void
		{
			if(onElementAdded != null)
				onElementAdded(e);
		}
		
		public function get def():XML { return xdef }
		public function get meta():Object { return xmeta }
		public function set meta(v:Object):void { xmeta =v }
		public function get eventAnimationComplete():Event {return eventAnimComplete }
		public function reset():void { 
			AO.killOff(this);
			XSupport.applyAttributes(def, this);	
		}

		public function set def(value:XML):void { 
			xdef = value;
			parseDef();
		}
		
		private function animComplete():void {	this.dispatchEvent(this.eventAnimationComplete) }
		
		override public function addChild(child:DisplayObject):DisplayObject
		{
			super.addChild(child);
			var c:ixDisplay = child as ixDisplay;
			if(c != null)
			{
				c.reset();
				XSupport.animByName(c, 'addChild', animComplete);
			}
			return child;
		}
		
		override public function addChildAt(child:DisplayObject, index:int):DisplayObject
		{
			super.addChildAt(child, index);
			var c:ixDisplay = child as ixDisplay;
			if(c != null)
			{
				c.reset();
				XSupport.animByName(c, 'addChild');
			}
			return child;
		}
		
		override public function removeChild(child:DisplayObject):DisplayObject
		{
			var f:Function = super.removeChild;
			var c:ixDisplay = child as ixDisplay;
			if(c != null)
			{
				AO.killOff(c);
				XSupport.animByName(c, 'removeChild', acomplete);
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
				XSupport.animByName(c, 'removeChild', acomplete);
			} else { acomplete() } 
			function acomplete():void { f(index) }
			return c as DisplayObject;
		}
		
		protected function parseDef():void
		{
			trace('parse def', xdef != null);
			if(xdef==null)
				return;
			trace(this, "PARSING DEF");
			drawGraphics();
			XSupport.pushReadyTypes(def, this);
			XSupport.applyAttributes(def, this);
		}
		
		protected function drawGraphics():void
		{
			if(!def.hasOwnProperty('graphics')) return
			XSupport.drawFromDef(def.graphics[0], this);
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