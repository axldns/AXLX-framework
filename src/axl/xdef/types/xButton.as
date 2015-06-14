package axl.xdef.types
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.utils.clearInterval;
	import flash.utils.clearTimeout;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	import axl.utils.U;
	
	
	public class xButton extends xSprite
	{
		public static var defaultOverProperty:String='alpha';
		public static var defaultOverValue:Object='.75';
		public static var defaultUpValue:Object='1';
		public static var defaultDisabledProperty:String='alpha';
		public static var defaultDisabledValue:Object = '.44';
		public static var defaultEnabledValue:Object = '1';
		
		private var rollProperty:String='default';
		private var vRollIdle:Object= 'default';
		private var vRollOver:Object = 'default';
		
		private var disProperty:String='default';
		private var vDisDisabled:Object = 'default';
		private var vDisEnabled:Object = 'default';
		
		private var isEnabled:Boolean;
		private var texture:DisplayObject;
		
		public var intervalValue:int=0;
		public var intervalDelay:int = 0;
		
		private var userClickHandler:Function;
		private var eventClick:Event = new Event(flash.events.Event.SELECT,true);
		private var isRotated:Boolean;
		
		
		private var trigerUrl:URLRequest;
		private var trigerEvent:Event;
		private var trigerExt:Array;
		private var trigerUrlWindow:String;
		private var isDown:Boolean;
		private var delayID:uint;
		private var intervalID:uint;
		
		
		public function xButton(definition:XML=null)
		{
			super(definition);
			enabled = true;
		}
		
		//-- internal
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
		
		private function checkProperties():void
		{
			if(rollProperty == 'default')
				rollProperty = defaultOverProperty;
			if(vRollIdle == 'default')
				vRollIdle = defaultUpValue;
			if(vRollOver == 'default')
				vRollOver = defaultOverValue;
			if(disProperty == 'default')
				disProperty = defaultDisabledProperty;
			if(vDisDisabled == 'default')
				vDisDisabled = defaultDisabledValue;
			if(vDisEnabled == 'default')
				vDisEnabled = defaultEnabledValue;
		}
		
		//--click mechanic
		protected function mouseDown(e:MouseEvent):void
		{
			isDown = true;			
			U.STG.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			U.STG.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
			if(intervalValue > 0)
				delayID = setTimeout(repeatEvent, intervalDelay);
			
			function repeatEvent():void
			{
				if(isDown)
					intervalID = setInterval(mouseClick, intervalValue,e);
				else
					clearIntervals();
			}
		}
		
		protected function mouseClick(e:MouseEvent):void
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
		}
		
		protected function mouseUp(e:MouseEvent):void { mouseMove(e) }
		protected function mouseMove(e:MouseEvent):void
		{
			if(isDown && !e.buttonDown)
				touchEnd();
		}
		
		private function touchEnd():void
		{
			isDown = false;
			U.STG.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
			U.STG.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			clearIntervals();
		}
		
		private function clearIntervals():void
		{
			flash.utils.clearInterval(intervalID);
			flash.utils.clearTimeout(delayID);
		}
		
		protected function onOut(e:MouseEvent):void{ if(rollProperty != null) {this[rollProperty] = vRollIdle} }
		protected function onOver(e:MouseEvent):void { if(rollProperty != null) {this[rollProperty] = vRollOver} }
		
		// --- --- PUBLIC API --- --- //
		public function get enabled():Boolean {	return isEnabled }
		public function set enabled(value:Boolean):void
		{
			isEnabled = value;
			checkProperties();
			if(isEnabled)
			{
				this.addEventListener(MouseEvent.CLICK, mouseClick);
				this.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
				this.addEventListener(MouseEvent.ROLL_OVER, onOver);
				this.addEventListener(MouseEvent.ROLL_OUT, onOut);
				if(disProperty != null) {this[disProperty] = vDisEnabled}
				this.buttonMode = true;
				this.useHandCursor = true;
			}
			else
			{
				this.removeEventListener(MouseEvent.CLICK, mouseClick);
				this.removeEventListener(MouseEvent.ROLL_OVER, onOver);
				this.removeEventListener(MouseEvent.ROLL_OUT, onOut);
				U.STG.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
				U.STG.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
				if(disProperty != null) {this[disProperty] = vDisDisabled}
				this.buttonMode = false;
				this.useHandCursor = false;
			}
		}
		
		public function get onClick():Function { return userClickHandler }
		public function set onClick(v:Function):void { userClickHandler = v	}
		
		//--roll over
		public function get rollOverProperty():String {	return rollProperty }
		public function set rollOverProperty(value:String):void	{ rollProperty = value }
		
		public function get rollOverValue():Object { return vRollOver }
		public function set rollOverValue(v:Object):void { vRollOver = v }
		public function get idleValue():Object { return rollProperty }
		public function set idleValue(v:Object):void { vRollIdle = v }
		
		//--disable
		public function get disableProperty():String {	return disProperty }
		public function set disableProperty(value:String):void	{ disProperty = value }
		
		public function set disableValue(v:Object):void { vDisDisabled = v }
		public function get disableValue():Object { return vDisDisabled }
		
		public function set enableValue(v:Object):void { vDisEnabled = v }
		public function get enableValue():Object { return vDisEnabled }
		
		
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
	}
}