package axl.xdef.types
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import axl.utils.U;
	
	
	public class xButton extends xSprite
	{
		public static var defaultOverProperty:String='alpha';
		public static var defaultOverValue:Object='.75';
		public static var defaultUpValue:Object='1';
		public static var defaultDisabledValue:Object = '.44';
		private var vProperty:String='default';
		private var vIdle:Object= 'default';
		private var vOver:Object = 'default';
		private var vDisabled:Object = 'default';
		private var isEnabled:Boolean;
		private var texture:DisplayObject;
		
		private var userClickHandler:Function;
		private var eventClick:Event = new Event(flash.events.Event.SELECT,true);
		private var isRotated:Boolean;
		
		private var trigerUrl:URLRequest;
		private var trigerEvent:Event;
		private var trigerExt:Array;
		private var trigerUrlWindow:String;
		
		public function xButton(definition:XML=null)
		{
			super(definition);
			enabled = true;
		}
		
		public function get rotated():Boolean { return isRotated }
		public function set rotated(v:Boolean):void
		{
			isRotated = v;
			if(!texture)
				return;
			if(isRotated)
			{
				texture.rotation = 180;
				texture.x = texture.width;
				texture.y = texture.height;
			}
			else
			{
				texture.rotation = 0;
				texture.x = 0;
				texture.y =0;
			}
		}
		
		override public function set meta(v:Object):void
		{
			super.meta = v;
			if(meta.hasOwnProperty('url'))
			{
				
				if(meta.url is Array)
				{
					trigerUrl = meta.url[0]
					trigerUrlWindow = meta.url[1];
				}
				else
					trigerUrl = new URLRequest(meta.url);
			}
			if(meta.hasOwnProperty('event'))
				trigerEvent  = new Event(meta.event);
			if(meta.hasOwnProperty('js'))
				trigerExt = meta.js;
		}
		
		
		public function get enabled():Boolean {	return isEnabled }
		public function set enabled(value:Boolean):void
		{
			isEnabled = value;
			checkProperties();
			if(isEnabled)
			{
				this.addEventListener(MouseEvent.CLICK, clickHandler);
				this.addEventListener(MouseEvent.ROLL_OVER, onOver);
				this.addEventListener(MouseEvent.ROLL_OUT, onOut);
				if(vProperty != null) {this[vProperty] = vIdle}
				this.buttonMode = true;
				this.useHandCursor = true;
			}
			else
			{
				this.removeEventListener(MouseEvent.CLICK, clickHandler);
				this.removeEventListener(MouseEvent.ROLL_OVER, onOver);
				this.removeEventListener(MouseEvent.ROLL_OUT, onOut);
				if(vProperty != null) {this[vProperty] = vDisabled}
				this.buttonMode = false;
				this.useHandCursor = false;
			}
		}
		
		private function checkProperties():void
		{
			if(vProperty == 'default')
				vProperty = defaultOverProperty;
			if(vIdle == 'default')
				vIdle = defaultUpValue;
			if(vOver == 'default')
				vOver = defaultOverValue;
			if(vDisabled == 'default')
				vDisabled = defaultDisabledValue;
		}
		
		public function get upstate():DisplayObject { return texture }
		public function set upstate(v:DisplayObject):void
		{
			if(texture != null && contains(texture) && texture != v)
				this.removeChild(texture);
			texture = v;
			if(upstate !=null)
				this.addChild(texture);
			rotated = rotated;
		}
		
		
		public function get rollOverProperty():String {	return vProperty }
		public function set rollOverProperty(value:String):void	{ vProperty = value }
		
		public function get rollOverValue():Object { return vOver }
		public function set rollOverValue(v:Object):void { vOver = v }
		public function get idleValue():Object { return vProperty }
		public function set idleValue(v:Object):void { vIdle = v }
		public function set disableValue(v:Object):void { vDisabled = v }
		public function get disableValue():Object { return vDisabled }
		
		protected function onOut(e:MouseEvent):void{ if(vProperty != null) {this[vProperty] = vIdle} }
		protected function onOver(e:MouseEvent):void { if(vProperty != null) {this[vProperty] = vOver} }
		protected function clickHandler(e:MouseEvent):void
		{
			this.dispatchEvent(eventClick);
			if(userClickHandler != null) 
			{
				if(userClickHandler.length > 0)
					userClickHandler(e);
				else
					userClickHandler();
			}
			
			if(trigerUrl)
				navigateToURL(trigerUrl, trigerUrlWindow);
			if(trigerEvent != null)
				this.dispatchEvent(this.trigerEvent);
			if(this.trigerExt && ExternalInterface.available)
				ExternalInterface.call.apply(null, trigerExt);
			if((userClickHandler == null) &&  trigerUrl == null && trigerEvent == null && trigerExt == null) 
				U.log("UNDEFINED CLICK FOR", def.toXMLString());
		}
		
		public function get onClick():Function { return userClickHandler }
		public function set onClick(v:Function):void { userClickHandler = v	}
	}
}