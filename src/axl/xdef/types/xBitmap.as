package axl.xdef.types
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	
	import axl.xdef.XSupport;
	import axl.xdef.interfaces.ixDisplay;
	
	
	public class xBitmap extends Bitmap implements ixDisplay
	{
		protected var xdef:XML;
		protected var xmeta:Object={};
		public function xBitmap(bitmapData:BitmapData=null, pixelSnapping:String="auto", smoothing:Boolean=true)
		{
			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
			super(bitmapData, pixelSnapping, smoothing);
		}
		
		protected function addedToStageHandler(e:Event):void
		{
			
			if(meta.addedToStage != null)
			{
				this.reset();
				XSupport.animByName(this, 'addedToStage');
			}
		}
	
		public function get meta():Object { return xmeta }
		public function set meta(v:Object):void { xmeta =v }
		
		public function get def():XML { return xdef }
		public function set def(value:XML):void { 
			xdef = value;
			parseDef();
		}
		public function reset():void { parseDef()}
		
		protected function parseDef():void { XSupport.applyAttributes(def, this)}
		
	}
}