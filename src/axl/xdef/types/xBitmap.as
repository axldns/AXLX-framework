package axl.xdef.types
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	
	import axl.xdef.XSupport;
	import axl.xdef.interfaces.ixDisplay;
	
	
	public class xBitmap extends Bitmap implements ixDisplay
	{
		
		protected var xname:String='';
		protected var xdef:XML;
		protected var xmeta:Object={};
		public function xBitmap(bitmapData:BitmapData=null, pixelSnapping:String="auto", smoothing:Boolean=false)
		{
			super(bitmapData, pixelSnapping, smoothing);
		}
		override public function get name():String { return xname }
		override public function set name(v:String):void {xname = v }
		
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