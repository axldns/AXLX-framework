package axl.xdef.types
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.geom.ColorTransform;
	
	import axl.xdef.XSupport;
	import axl.xdef.interfaces.ixDisplay;
	
	
	public class xBitmap extends Bitmap implements ixDisplay
	{
		protected var xdef:XML;
		protected var xmeta:Object={};
		private var xtrans:ColorTransform;
		private var xtransDef:ColorTransform;
		private var xfilters:Array;
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
		
		public function get xtransform():ColorTransform { return xtrans }
		public function set xtransform(v:ColorTransform):void { xtrans =v; this.transform.colorTransform = v;
			if(xtransDef == null)
				xtransDef = new ColorTransform();
		}
		public function set transformOn(v:Boolean):void { this.transform.colorTransform = (v ? xtrans : xtransDef ) }
		
		override public function set filters(v:Array):void
		{
			xfilters = v;
			super.filters=v;
		}
		
		public function set filtersOn(v:Boolean):void {	super.filters = (v ? xfilters : null) }
		public function get filtersOn():Boolean { return filters != null }
		
		
		public function ctransform(prop:String,val:Number):void {
			if(!xtrans)
				xtrans = new ColorTransform();
			xtrans[prop] = val;
			this.transform.colorTransform = xtrans;
		}
		
	}
}