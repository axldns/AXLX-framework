package axl.xdef.types
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.ColorTransform;
	
	import axl.utils.AO;
	import axl.xdef.XSupport;
	import axl.xdef.interfaces.ixDisplay;
	
	public class xSprite extends Sprite implements ixDisplay
	{
		protected var xdef:XML;
		protected var xmeta:Object={};
		private var ct:ColorTransform = new ColorTransform();
		public var onAnimationComplete:Function;
		private var eventAnimComplete:Event = new Event(Event.COMPLETE);
		public function xSprite(definition:XML=null)
		{
			xdef = definition;
			super();
			parseDef();
			
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
			if(xdef==null)
				return;
			drawGraphics();
			XSupport.pushReadyTypes(def, this);
			XSupport.applyAttributes(def, this);
		}
		
		protected function drawGraphics():void
		{
			if(!def.hasOwnProperty('graphics')) return
			XSupport.drawFromDef(def.graphics[0], this);
		}
		
		public function get roffset():Number {	return ct.redOffset }
		public function set roffset(v:Number):void
		{
			ct.redOffset = v;
			this.transform.colorTransform = ct;
		}
		public function get goffset():Number {	return ct.greenOffset }
		public function set goffset(v:Number):void
		{
			ct.greenOffset = v;
			this.transform.colorTransform = ct;
		}
		public function get boffset():Number {	return ct.blueOffset }
		public function set boffset(v:Number):void
		{
			ct.blueOffset = v;
			this.transform.colorTransform = ct;
		}
		public function get aoffset():Number {	return ct.alphaOffset }
		public function set aoffset(v:Number):void
		{
			ct.alphaOffset = v;
			this.transform.colorTransform = ct;
		}
		public function get rmulti():Number {	return ct.redMultiplier }
		public function set rmulti(v:Number):void
		{
			ct.redMultiplier = v;
			this.transform.colorTransform = ct;
		}
		public function get gmulti():Number {	return ct.greenMultiplier }
		public function set gmulti(v:Number):void
		{
			ct.greenMultiplier = v;
			this.transform.colorTransform = ct;
		}
		
		public function get bmulti():Number {	return ct.blueMultiplier }
		public function set bmulti(v:Number):void
		{
			ct.blueMultiplier = v;
			this.transform.colorTransform = ct;
		}
		
	}
}