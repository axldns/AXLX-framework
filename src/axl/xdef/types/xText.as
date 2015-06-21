package axl.xdef.types
{
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import axl.utils.AO;
	import axl.xdef.XSupport;
	import axl.xdef.interfaces.ixDisplay;
	import flash.geom.ColorTransform;
	
	public class xText extends TextField implements ixDisplay
	{
		protected var xdef:XML;
		protected var xmeta:Object={};
		
		private var tff:TextFormat;
		public var onAnimationComplete:Function;
		private var xfilters:Array;
		private var xtrans:ColorTransform;
		private var xtransDef:ColorTransform;
		
		public function xText(definition:XML=null)
		{
			xdef = definition;
			tff = new TextFormat();
			super();
			if(def!= null)
				parseDef();
			this.addEventListener(Event.ADDED_TO_STAGE, ats);
		}
		
	
		protected function ats(event:Event):void
		{
			if(meta != null && meta.hasOwnProperty('addedToStage'))
			{
				var a:Array = [this].concat(meta.addChild);
				a[3] = onComplete;
				AO.animate.apply(null,a);
			}
		}
		
		private function onComplete():void
		{
			if(onAnimationComplete != null)
				onAnimationComplete();
		}
		
		public function get def():XML { return xdef }
		public function set def(value:XML):void { 
			xdef = value;
			parseDef();
		}
		
		
		protected function parseDef():void
		{
			if(def == null)
				throw new Error("Undefined definition for " + this);
			XSupport.applyAttributes(def, this);
			XSupport.applyAttributes(def, tff);
			
			if(!def.hasOwnProperty('@font'))
				tff.font = XSupport.defaultFont;
			this.defaultTextFormat = tff;
			if(def.hasOwnProperty('@html'))
				this.htmlText = def.toString();
			else
				this.text = def.toString();
			if(!def.hasOwnProperty('@width'))
				this.width = textWidth + 5;
			if(!def.hasOwnProperty('@height'))
				this.height = textHeight + 5;
		}
		
		public function reset():void { parseDef() }
		public function get meta():Object { return xmeta }
		public function set meta(v:Object):void { xmeta =v }
		
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