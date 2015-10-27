package axl.xdef.types
{
	import flash.events.Event;
	import flash.events.TextEvent;
	import flash.external.ExternalInterface;
	import flash.geom.ColorTransform;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.clearInterval;
	
	import axl.utils.AO;
	import axl.xdef.XSupport;
	import axl.xdef.interfaces.ixDisplay;
	
	public class xText extends TextField implements ixDisplay
	{
		protected var xdef:XML;
		protected var xmeta:Object={};
		private var xxroot:xRoot;
		
		private var tff:TextFormat;
		public var onAnimationComplete:Function;
		private var xfilters:Array;
		private var xtrans:ColorTransform;
		private var xtransDef:ColorTransform;
		private var trigerExt:Object;
		private var actions:Vector.<xAction> = new Vector.<xAction>();
		private var intervalID:uint;
		private var defaultFont:String;
	
		
		public function xText(definition:XML=null,xroot:xRoot=null,xdefaultFont:String=null)
		{
			xdef = definition;
			this.xroot = xroot;
			defaultFont = xdefaultFont;
			tff = new TextFormat();
			super();
			if(def!= null)
				parseDef();
			this.addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
			this.addEventListener(Event.REMOVED_FROM_STAGE, removeFromStageHandler);
			this.addEventListener(TextEvent.LINK, linkEvent);
		}
		
		public function get xroot():xRoot { return xxroot }
		public function set xroot(v:xRoot):void	{ xxroot = v }
		
		protected function linkEvent(e:TextEvent):void
		{
			if(trigerExt != null && ExternalInterface.available)
				ExternalInterface.call.apply(null, trigerExt);
			for(var i:int = 0, j:int = actions.length; i<j; i++)
				actions[i].execute();
		}
	
		protected function removeFromStageHandler(e:Event):void
		{
			AO.killOff(this);
			clearInterval(intervalID);
		}
		
		protected function addedToStageHandler(e:Event):void
		{
			if(meta.addedToStage != null)
			{
				this.reset();
				intervalID = XSupport.animByNameExtra(this, 'addedToStage');
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
				tff.font = defaultFont;
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
		
		//-- internal
		public function set meta(v:Object):void
		{
			xmeta =v;
			if(v is String)
				return
			if(meta.hasOwnProperty('js'))
				trigerExt = meta.js;
			if(meta.hasOwnProperty('action'))
			{
				var a:Object = meta.action;
				var b:Array = (a is Array) ? a as Array : [a];
				for(var i:int = 0, j:int = b.length; i<j; i++)
					actions[i] = new xAction(b[i],xroot,this);
			}
			replaceTextFieldText();
		}
		
		private function replaceTextFieldText():void
		{
			var a:Array = meta.replace as Array;
			if(a != null)
			{
				for(var i:int = 0; i < a.length;i++)
				{
					var rep:Object = a[i];
					var pattern:RegExp = new RegExp(rep.pattern, rep.options);
					var source:Object = XSupport.simpleSourceFinder(this.xroot, rep.source);
					if(source == null)
						source = rep.source;
					
					if(rep.sourceRepPattern)
					{
						var sourceRepPattern:RegExp = new RegExp(rep.sourceRepPattern, rep.sourceRepOptions);
						source = source.replace(sourceRepPattern, rep.sourceReplacement);
					}
					super.htmlText = super.htmlText.replace(pattern, String(source));
				}
			}
		}
		
		override public function set text(value:String):void
		{
			super.text = value;
			replaceTextFieldText();
		}
		
		override public function set htmlText(value:String):void
		{
			super.htmlText = value;
			replaceTextFieldText();
		}
		
		
	}
}