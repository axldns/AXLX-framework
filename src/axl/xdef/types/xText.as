package axl.xdef.types
{
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import axl.utils.AO;
	import axl.xdef.XSupport;
	
	public class xText extends TextField
	{
		private var xdef:XML;
		public var meta:Object;
		private var tff:TextFormat;
		public var onAnimationComplete:Function;
		
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
			trace(this, "ATS");
			if(meta != null && meta.hasOwnProperty('addChild'))
			{
				trace(this, 'metaadd');
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
		
		public function reset():void
		{
			trace('RESET', this, this.name);
			parseDef();
		}
	}
}