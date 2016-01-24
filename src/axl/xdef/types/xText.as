/**
 *
 * AXLX Framework
 * Copyright 2014-2015 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
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
	import axl.utils.U;
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
		private var addedToStageActions:Vector.<xAction>;
		private var intervalID:uint;
		private var defaultFont:String;
		/** Every time META object is set (directly or indirectly - via <code>reset - XSupport.applyAttributes</code>
		 * method) object can be rebuild or set just once per existence @default false @see #reset() */
		public var reparseMetaEverytime:Boolean;
		/** Every time object XML definition is set definition can be re-read. For <code>xSprite</code> it 
		 * affects graphics drawing only. Pushing children inside happens only once per existence in
		 *  <code>XSupport.getReadyType2 - pushReadyTypes2</code>  @default false 
		 * @see axl.xdef.XSupport#getReadyType2() @see axl.xdef.XSupport#pushReadyTypes2() */
		public var reparsDefinitionEverytime:Boolean;
		/** Every time object is (re)added to stage method <code>reset</code> can be called. 
		 * Aim of method reset is to bring object to its initial state (defined by xml) by reparsing it's attributes
		 * and killing all animations @see #reset() */
		public var resetOnAddedToStage:Boolean=true;
		/** Distributes  children horizontaly with gap specified by this property. 
		 * If not set - no distrbution occur @see axl.utils.U#distribute() */
		private var metaAlreadySet:Boolean;
		public var debug:Boolean;
		
		public function xText(definition:XML=null,xrootObj:xRoot=null,xdefaultFont:String=null)
		{
			xdef = definition;
			this.xroot = xrootObj || this.xroot;
			
			if(this.xroot != null && definition != null)
				xroot.registry[String(definition.@name)] = this;
					
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
			if(resetOnAddedToStage)
				this.reset();
			if(meta.addedToStage != null)
			{
				intervalID = XSupport.animByNameExtra(this, 'addedToStage');
			}
			if(addedToStageActions != null)
			{	for(var i:int = 0, j:int = addedToStageActions.length; i<j; i++)
					addedToStageActions[i].execute();
				if(debug) U.log(this, this.name, '[addedToStage]', j, 'actions');
			}
		}
		
		private function onComplete():void
		{
			if(onAnimationComplete != null)
				onAnimationComplete();
		}
		
		public function get def():XML { return xdef }
		public function set def(value:XML):void {
			if(value == null)
				return;
			else if(xdef != null && xdef is XML && !reparsDefinitionEverytime)
				return;
			xdef = value;
			parseDef();
		}
		
		override public function set name(v:String):void
		{
			super.name = v;
			if(this.xroot != null)
				this.xroot.registry.v = this;
		}
		
		protected function parseDef():void
		{
			if(def == null)
				throw new Error("Undefined definition for " + this);
			XSupport.applyAttributes(def, this);
			var tv:String =  def.toString();
			if(!def.hasOwnProperty('@font'))
				tff.font = defaultFont;
			this.defaultTextFormat = tff;
			if(tv.length > 0)
			{
				if(def.hasOwnProperty('@html') && def.@html == 'true')
					this.htmlText = tv;
				else
					this.text = tv;
			}
			
			if(!def.hasOwnProperty('@width'))
				this.width = textWidth + 5;
			if(!def.hasOwnProperty('@height'))
				this.height = textHeight + 5;
		}
		
		public function reset():void { 
			AO.killOff(this);
			parseDef()
		}
		
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
		
		/**
		 * <h3>xSprite meta keywords</h3>
		 * <ul>
		 * <li>"replace" - array of Objects with following keys
		 * <ol>
		 * <li>"pattern" - Regexp to find inside xText.text string</li>
		 * <li>"source" - replacement or reference to replacement (start with $) String for found pattern</li>
		 * <li>(optional) "options" - pattern Regexp options (e.g. flags /gi)</li>
		 * <li>(optional) "sourceRepPattern" - source can be also replaced by this parameter - regexp</li>
		 * <li>(optional) "sourceRepOptions" - sourceRepPattern regexp options</li>
		 * </ol>
		 * If replace array is set, every time xTimer.text or htmlText is set, text is scanned and replaced
		 * against all regular expressions in "replace" array.
		 * </li>
		 * <li>"addedToStage" - animation(s) to execute when added to stage</li>
		 * <li>"addedToStageAction" - action(s) to execute when added to stage
		 * instantiated and added to this instance</li>
		 * <li>"action" - action(s) to execute when html link is clicked</li>
		 * <li>"js" - argument(s) to apply to <code>ExternalInterface.call</code> method
		 * when htmlText hyperLink is clicked</li>
		 * </ul>
		 * @see axl.xdef.types.xAction
		 * @see axl.xdef.XSupport#animByNameExtra()
		 * @see axl.utils.AO#animate()
		 */
		public function set meta(v:Object):void
		{
			if(v is String)
				throw new Error("Invalid json for element " +  def.localName() + ' ' +  def.@name );
			if((metaAlreadySet && !reparseMetaEverytime))
				return;
			xmeta =v;
			metaAlreadySet = true;
			if(meta.hasOwnProperty('js'))
				trigerExt = meta.js;
			var a:Object, b:Array;
			if(meta.hasOwnProperty('action'))
			{
				a = meta.action;
				b = (a is Array) ? a as Array : [a];
				for(var i:int = 0, j:int = b.length; i<j; i++)
					actions[i] = new xAction(b[i],xroot,this);
			}
			if(meta.hasOwnProperty('addedToStageAction'))
			{
				addedToStageActions = new Vector.<xAction>();
				a = meta.addedToStageAction;
				b = (a is Array) ? a as Array : [a];
				for(i = 0, j = b.length; i<j; i++)
					addedToStageActions[i] = new xAction(b[i],xroot,this);
			}
			replaceTextFieldText();
		}
		
		private function replaceTextFieldText():void
		{
			var a:Array = meta.replace as Array;
			var s:String = this.htmlText;
			if(a != null)
			{
				for(var i:int = 0; i < a.length;i++)
				{
					var rep:Object = a[i];
					var pattern:RegExp = new RegExp(rep.pattern, rep.options);
					var source:Object = (rep.source.charAt(0) == '$' ? xroot.binCommand(rep.source.substr(1)) : rep.source);//XSupport.simpleSourceFinder(this.xroot, rep.source);
					if(source == null || source is Error)
						source = rep.source;
					
					if(rep.sourceRepPattern)
					{
						var sourceRepPattern:RegExp = new RegExp(rep.sourceRepPattern, rep.sourceRepOptions);
						source = String(source).replace(sourceRepPattern, rep.sourceReplacement);
					}
					s= s.replace(pattern, String(source));
				}
				super.htmlText = s;
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
		
		public function get align():String { return tff.align }
		public function set align(v:String):void { tff.align = v }
		public function get blockIndent():Object { return tff.blockIndent }
		public function set blockIndent(v:Object):void { tff.blockIndent = v }
		public function get bold():Object { return tff.bold }
		public function set bold(v:Object):void { tff.bold = v }
		public function get bullet():Object { return tff.bullet }
		public function set bullet(v:Object):void { tff.bullet = v }
		public function get color():Object { return tff.color }
		public function set color(v:Object):void { tff.color = v }
		public function get font():String { return tff.font }
		public function set font(v:String):void { tff.font = v }
		public function get indent():Object { return tff.indent }
		public function set indent(v:Object):void { tff.indent = v }
		public function get italic():Object { return tff.italic }
		public function set italic(v:Object):void { tff.italic = v }
		public function get kerning():Object { return tff.kerning }
		public function set kerning(v:Object):void { tff.kerning = v }
		public function get leading():Object { return tff.leading }
		public function set leading(v:Object):void { tff.leading = v }
		public function get leftMargin():Object { return tff.leftMargin }
		public function set leftMargin(v:Object):void { tff.leftMargin = v }
		public function get letterSpacing():Object { return tff.letterSpacing }
		public function set letterSpacing(v:Object):void { tff.letterSpacing = v }
		public function get rightMargin():Object { return tff.rightMargin }
		public function set rightMargin(v:Object):void { tff.rightMargin = v }
		public function get size():Object { return tff.size }
		public function set size(v:Object):void { tff.size = v }
		public function get tabStops():Array { return tff.tabStops }
		public function set tabStops(v:Array):void { tff.tabStops = v }
		public function get target():String { return tff.target }
		public function set target(v:String):void { tff.target = v }
		public function get underline():Object { return tff.underline }
		public function set underline(v:Object):void { tff.underline = v }
		public function get url():String { return tff.url }
		public function set url(v:String):void { tff.url = v }

	}
}