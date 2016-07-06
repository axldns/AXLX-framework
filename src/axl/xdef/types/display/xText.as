/**
 *
 * AXLX Framework
 * Copyright 2014-2016 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package axl.xdef.types.display
{
	import flash.events.Event;
	import flash.events.TextEvent;
	import flash.external.ExternalInterface;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import axl.utils.AO;
	import axl.xdef.XSupport;
	import axl.xdef.interfaces.ixDisplay;
	
	public class xText extends TextField implements ixDisplay
	{
		public static var defaultFont:String;
		
		private var xdef:XML;
		private var xmeta:Object;
		private var xxroot:xRoot;
		private var xonAddedToStage:Object;
		private var xonRemovedFromStage:Object;
		private var xresetOnAddedToStage:Boolean = true;
		private var xstyles:Object;
		
		private var tff:TextFormat;
		private var trigerExt:Object;
		
		/** Portion of uncompiled code to execute when object is created and attributes are applied. 
		 * 	Runs only once. An argument for binCommand. Does not have to be dolar sign prefixed.
		 * @see axl.xdef.types.xRoot#binCommand() */
		public var inject:String;
		
		/**
		 * Property containing uncompiled code for binCommand. <br>
		 * <code> code='[stage.removeChildren()]'</code>
		 * <br><b>is the equivalent of:</b><br>
		 * <code>meta='{"action":[{"type":"binCommand","value":[[stage.removeChildren()]]}]}'</code><br>
		 * <br>The string is going to be parsed / code evaluated on execution, every execution.<br>
		 * <b>Confusion</b> may occur as, unlike with other in-attrubute-code-executions, you probably don't want to prepend
		 * your config "code" attrubute value with dolar sign, unless you want to 
		 * reference code containing variable to somewhere else.<br>  */
		public var code:String;
		/** An array of two elementable arrays, where first element is textual pattern to find in textfield's text,
		 * and second is any text-convertable source to replace pattern in text. 
		 * <br>Example:<br><code>text = "replacement";<br>replace=[["e","a"],["m","n"]]<br></code>
		 * result: "raplacant" */
		public var replace:Object;

		/** Function to execute when a href tag is clicked in textfield. Event type is passed to 
		 * this function as an argument */
		public var onLinkEvent:Function;
		
		public function xText(definition:XML=null,xrootObj:xRoot=null)
		{
			this.xroot = xrootObj || xroot;
			xdef = definition;
			xroot.support.register(this);
			
			tff = new TextFormat();
			super();
			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
			addEventListener(Event.REMOVED_FROM_STAGE, removeFromStageHandler);
			addEventListener(TextEvent.LINK, linkEvent);
			parseDef();
		}
		//----------------------- INTERFACE METHODS -------------------- //
		/** XML definition of this object @see axl.xdef.interfaces.ixDef#def */
		public function get def():XML { return xdef }
		public function set def(value:XML):void 
		{ 
			if((value == null))
				return;
			xdef = value;
			parseDef();
		}
		/** Reference to parent xRoot object @see axl.xdef.types.xRoot 
		 *  @see axl.xdef.interfaces.ixDef#xroot*/
		public function get xroot():xRoot { return xxroot }
		public function set xroot(v:xRoot):void	{ xxroot = v }
		
		/**
		 * <h3>xText meta keywords</h3>
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
		 * instantiated and added to this instance</li>
		 * <li>"action" - action(s) to execute when html link is clicked</li>
		 * <li>"js" - argument(s) to apply to <code>ExternalInterface.call</code> method
		 * when htmlText hyperLink is clicked</li>
		 * </ul>
		 * @see axl.xdef.XSupport#animByNameExtra()
		 * @see axl.utils.AO#animate() */
		public function get meta():Object { return xmeta }
		public function set meta(v:Object):void 
		{
			if(v is String)
				throw new Error("Invalid json for element " +  def.localName() + ' ' +  def.@name );
			if(!v || meta) return;
			xmeta =v;
			
			if(meta.hasOwnProperty('action'))
			{
				var a:Object = meta.action;
				var b:Array = (a is Array) ? a as Array : [a];
			}
			refreshText();
		}
		
		/** Sets name and registers object in registry @see axl.xdef.types.xRoot.registry */
		override public function set name(v:String):void
		{
			super.name = xroot.support.requestNameChange(v,this);
		}
		
		/** Kills all animations proceeding and sets initial (xml-def-attribute-defined) values to 
		 * this object
		 * @see axl.xdef.XSupport#applyAttrubutes()
		 * @see #resetOnAddedToStage
		 * @see #reparseMetaEverytime */
		public function reset():void 
		{
			AO.killOff(this);
			parseDef();
		}
		
		/** Applies group of properties at once @see axl.xdef.interfaces.ixDisplay#style */
		public function get styles():Object	{ return xstyles }
		public function set styles(v:Object):void
		{
			xstyles = v;
			xroot.support.applyStyle(v,this);
		}
		
		/** Function reference or portion of uncompiled code to execute when object is removed from stage.
		 *  An argument for binCommand. @see axl.xdef.types.xRoot#binCommand() */
		public function get onRemovedFromStage():Object	{ return xonRemovedFromStage }
		public function set onRemovedFromStage(value:Object):void {	xonRemovedFromStage = value }
		
		/** Function or portion of uncompiled code to execute when object is added to stage. An argument for binCommand.
		 * @see axl.xdef.types.xRoot#binCommand() */
		public function get onAddedToStage():Object { return xonAddedToStage }
		public function set onAddedToStage(value:Object):void {	xonAddedToStage = value }
		
		/** Determines if object is going to be brought to it's original XML defined values. 
		 * @see axl.interfaces.ixDisplay#resetOnAddedToStage */
		public function get resetOnAddedToStage():Boolean {	return xresetOnAddedToStage }
		public function set resetOnAddedToStage(value:Boolean):void { xresetOnAddedToStage = value}
		
		//----------------------- INTERFACE METHODS -------------------- //
		//----------------------- INTERFACE SUPPORT -------------------- //
		/** Executes defaultAddedToStageSequence +  Starts listening to ENTER_FRAME events 
		 * if <code>sortZ=true</code> @see axl.xdef.types.XSuppot#defaultAddedToStageSequence() */
		protected function addedToStageHandler(e:Event):void
		{
			xroot.support.defaultAddedToStageSequence(this);
		}
		
		/**Removes ENTER_FRAME event listener if assigned +  Executes defaultRemovedFromStage
		 *  @see axl.xdef.types.XSuppot#defaultRemovedFromStageSequence() */
		protected function removeFromStageHandler(e:Event):void
		{ 
			xroot.support.defaultRemovedFromStageSequence(this);
		}
		/** Re-asigns original XML values, re-sets the style, autosizes width/height if not specifed */
		protected function parseDef():void
		{
			if(def == null)
				throw new Error("Undefined definition for " + this);
						
			XSupport.applyAttributes(def, this);
			var tv:String =  def.toString();
			if(!def.hasOwnProperty('@font'))
				tff.font = defaultFont;
			if(!this.styleSheet)
				this.defaultTextFormat = tff;
			
			if(tv.length > 0)
			{
				this.htmlText = tv;
			}
			autoSizeText();
		}
		//----------------------- INTERFACE SUPPORT -------------------- //
		//----------------------- OVERRIDEN METHODS -------------------- //
		override public function set text(value:String):void
		{
			super.text = value;
			refreshText();
		}
		
		override public function set htmlText(value:String):void
		{
			super.htmlText = value;
			refreshText();
		}
		//----------------------- OVERRIDEN METHODS -------------------- //
		//----------------------- INTERNAL METHODS -------------------- //
		private function autoSizeText():void
		{
			if(!def.hasOwnProperty('@width') && (!styles || !styles.hasOwnProperty('width')))
				this.width = textWidth + 5;
			if(!def.hasOwnProperty('@height') && (!styles || !styles.hasOwnProperty('height')))
				this.height = textHeight + 5;
		}
		private function replaceReplace(a:Array, s:String):void
		{
			for(var i:int =0, j:int = a.length;i<j;i++)
			{
				var rep:Array = a[i] as Array;
				if(!rep || rep.length != 2) continue;
				
				var pattern:RegExp = new RegExp(rep[0],"g");
				var source:Object = rep[1].charAt(0) == '$' ? xroot.binCommand(rep[1].substr(1),this) : rep[1];
				if(source == null || source is Error)
					source = rep[1];
				s= s.replace(pattern, String(source));
			}
			super.htmlText = s;	
		}
		
		private function replaceMeta(a:Array, s:String):void
		{
			for(var i:int = 0, j:int=a.length; i < j;i++)
			{
				var rep:Object = a[i];
				var pattern:RegExp = new RegExp(rep.pattern, rep.options ? rep.options : "g");
				var source:Object = (rep.source.charAt(0) == '$' ? xroot.binCommand(rep.source.substr(1),this) : rep.source);//XSupport.simpleSourceFinder(this.xroot, rep.source);
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
		/** Trigers actions when user clicks on a href tag. Available actions:
		 * meta.js, meta.actions, code (generic) and onLinkEvent (specific) where,
		 * event type is passed to the function as an argument. */
		protected function linkEvent(e:TextEvent):void
		{
			if(trigerExt != null && ExternalInterface.available)
				ExternalInterface.call.apply(null, trigerExt);
			if(code != null)
				xroot.binCommand(code,this);
			if(onLinkEvent != null)
				onLinkEvent(e.type);
		}
		//----------------------- INTERNAL METHODS -------------------- //
		//-----------------------OTHER PUBLIC API -------------------- //
		/** sets both scaleX and scaleY to the same value*/
		public function set scale(v:Number):void{ scaleX = scaleY = v }
		/** returns average of scaleX and scaleY */
		public function get scale():Number { return (scaleX + scaleY)/2 }
		
		/** Reevaluates replace statements defined in meta.replace array and attribute 
		 * <i>replace</i> array. Re-asignes text of textfield in according to these. */
		public function refreshText():void
		{
			var a:Object = meta ? meta.replace as Array : null;
			var s:String = this.htmlText;
			if(a != null)
				replaceMeta(a as Array,s);
			a = replace;
			if(a is String)
				a = a.charAt(0) == '$' ? xroot.binCommand(a.substr(1),this) : a;
			if(a is Array)
				replaceReplace(a as Array,s);
			autoSizeText();
		}
		
		public function get align():String { return tff.align }
		public function set align(v:String):void { tff.align = v; this.setTextFormat(tff); }
		public function get blockIndent():Object { return tff.blockIndent }
		public function set blockIndent(v:Object):void { tff.blockIndent = v; this.setTextFormat(tff); }
		public function get bold():Object { return tff.bold }
		public function set bold(v:Object):void { tff.bold = v; this.setTextFormat(tff); }
		public function get bullet():Object { return tff.bullet }
		public function set bullet(v:Object):void { tff.bullet = v; this.setTextFormat(tff); }
		public function get color():Object { return tff.color }
		public function set color(v:Object):void { tff.color = v; this.setTextFormat(tff); }
		public function get font():String { return tff.font }
		public function set font(v:String):void { tff.font = v; this.setTextFormat(tff); }
		public function get indent():Object { return tff.indent }
		public function set indent(v:Object):void { tff.indent = v; this.setTextFormat(tff); }
		public function get italic():Object { return tff.italic }
		public function set italic(v:Object):void { tff.italic = v; this.setTextFormat(tff); }
		public function get kerning():Object { return tff.kerning }
		public function set kerning(v:Object):void { tff.kerning = v; this.setTextFormat(tff); }
		public function get leading():Object { return tff.leading }
		public function set leading(v:Object):void { tff.leading = v; this.setTextFormat(tff); }
		public function get leftMargin():Object { return tff.leftMargin }
		public function set leftMargin(v:Object):void { tff.leftMargin = v; this.setTextFormat(tff); }
		public function get letterSpacing():Object { return tff.letterSpacing }
		public function set letterSpacing(v:Object):void { tff.letterSpacing = v; this.setTextFormat(tff); }
		public function get rightMargin():Object { return tff.rightMargin }
		public function set rightMargin(v:Object):void { tff.rightMargin = v; this.setTextFormat(tff); }
		public function get size():Object { return tff.size }
		public function set size(v:Object):void { tff.size = v; this.setTextFormat(tff); }
		public function get tabStops():Array { return tff.tabStops }
		public function set tabStops(v:Array):void { tff.tabStops = v; this.setTextFormat(tff); }
		public function get target():String { return tff.target }
		public function set target(v:String):void { tff.target = v; this.setTextFormat(tff); }
		public function get underline():Object { return tff.underline }
		public function set underline(v:Object):void { tff.underline = v; this.setTextFormat(tff); }
		public function get url():String { return tff.url }
		public function set url(v:String):void { tff.url = v; this.setTextFormat(tff); }

	}
}