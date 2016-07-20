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
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.FocusEvent;
	
	import axl.utils.U;

	/** Lightweight container class that provides typical formular features: 
	 * validation, submit action, error and focus indicators. Instantiated from
	 * <h3><code>&lt;form&gt;<br>&lt;/form&gt;</code></h3>
	 * <ul>
	 * <li>Inspects all added xText instances (&lt;txt/&gt;) against <i>meta.regexp</i> presence 
	 * and makes them members of primitive (JSON object) <code>formObject</code></li>
	 * <li>Only allows to execute "submit" function if all <i>formObject</i> members RegExp
	 * match their text value</li>
	 * <li>Displays error indicator on first spotted validation error</li>
	 * </ul>
	 * Internal display list of form object can be nested at multi levels, all textfields are examinated.
	 * */
	public class xForm extends xSprite
	{
		private var currentFocused:xText;
		private var indicatorProperties:Object = {roundness:0,thickness:2,color:0xFFFFFF,alpha:1,pixelHinting:true,scaleMode:"normal",caps:null,joints:null,miterLimit:3};

		private var errorIndicatorProperties:Object = {roundness:0,thickness:2,color:0xFF0000,alpha:1,pixelHinting:true,scaleMode:"normal",caps:null,joints:null,miterLimit:3};
		private var errorIndicator:Shape;
		private var indicator:Shape;
		private var toValidate:Vector.<xText> = new Vector.<xText>();
		private var xformObject:Object = {};
		private var lastErrorTextfield:xText;
		
		/** Allows to set up an  object that defines focus indicator appearance. These are arguments
		 * for line style of flash.display.Graphics.drawRoundRect function.<br>
		 * Available properties: thickness (2), color (0xFFFFFF), alpha (1), pixelHinting (true), 
		 * scaleMode ("normal"), caps (null) , joints (null) mitterLimit (3), roundness (0)*/
		public function get focusProps():Object	{return indicatorProperties};
		
		/** Allows to set up an  object that defines error indicator appearance. These are arguments
		 * for line style of flash.display.Graphics.drawRoundRect function.<br>
		 * Available properties: thickness (2), color (0xFFFFFF), alpha (1), pixelHinting (true), 
		 * scaleMode ("normal"), caps (null) , joints (null) mitterLimit (3), roundness (0)*/
		public function get errorProps():Object	{return errorIndicatorProperties};
		
		/** Function reference or portion of uncompiled code to execute when <code>submit()</code> is called but
		 * validation errors occur.  An argument for binCommand. @see axl.xdef.types.display.xRoot#binCommand() */
		public var onError:Object;
		
		/** Function reference or portion of uncompiled code to execute when <code>submit()</code> is called and
		 * all textfields containting meta.regexp pass all the validation tests. 
		 * An argument for binCommand. @see axl.xdef.types.display.xRoot#binCommand() */
		public var onSubmit:Object;
		
		/** Lightweight container class that provides typical formular features: 
		 * validation, submit action, error and focus indicators. Instantiated from
		 * <h3><code>&lt;form&gt;<br>&lt;/form&gt;</code></h3> @see axl.xdef.types.display.xForm */
		public function xForm(definition:XML=null, xroot:xRoot=null)
		{
			super(definition, xroot);
			indicator = new Shape();
			errorIndicator = new Shape();
			
			this.addEventListener(FocusEvent.FOCUS_IN, focusInHandler);
		}
		/** Clears error indicator and draws focus indicator. */
		protected function focusInHandler(e:FocusEvent):void
		{
			if(errorIndicator.parent != null)
				errorIndicator.parent.removeChild(errorIndicator);
			indicator.graphics.clear();
			currentFocused = e.target as xText;
			if(currentFocused == null)
				return;
			
			indicator.graphics.clear();
			indicator.graphics.lineStyle(
			indicatorProperties.thickness, 
			indicatorProperties.color, 
			indicatorProperties.alpha, 
			indicatorProperties.pixelHinting,
			indicatorProperties.scaleMode,
			indicatorProperties.caps,
			indicatorProperties.joints, 
			indicatorProperties.miterLimit);
			
			indicator.graphics.drawRoundRect(0, 0, currentFocused.width,currentFocused.height,indicatorProperties.roundness,indicatorProperties.roundness);
			indicator.x = currentFocused.x;
			indicator.y = currentFocused.y;
			currentFocused.parent.addChild(indicator);
		}
		
		override protected function elementAddedHandler(e:Event):void
		{
			super.elementAddedHandler(e);
			var t:xText = e.target as xText;
			if(t && t.meta && t.meta.hasOwnProperty('regexp') && toValidate.indexOf(t) < 0)
				toValidate.push(t);
		}
		/** Validates all children xText instances (&lt;txt/&gt;) against their meta.regexp and either 
		 *displays error indicator on first spotted error or executes <code>onSubmit</code> @see #onSubmit */
		public function submit():void
		{
			for(var i:int = 0,t:xText,r:RegExp,j:int=toValidate.length; i < j;i++)
			{
				t = toValidate[i];
				formObject[t.name] = t.text;
				if(!t.text.match(t.meta.regexp))
					return addError(t);
			}
			lastErrorTextfield = null;
			removeErrorIndicator();
			removeFocusIndicator();
			if(onSubmit is String)
				xroot.binCommand(onSubmit,this);
			else if(onSubmit is Function)
				onSubmit();
		}
		
		private function addError(t:xText):void
		{
			if(debug) U.log("Form validation error in ", t, t.name, "didn't match", t.meta.regexp);
			if(indicator.parent != null)
				indicator.parent.removeChild(indicator);
			currentFocused = null;
			stage.focus = t;
			
			errorIndicator.graphics.clear();
			errorIndicator.graphics.lineStyle(
			errorIndicatorProperties.thickness, 
			errorIndicatorProperties.color, 
			errorIndicatorProperties.alpha, 
			errorIndicatorProperties.pixelHinting,
			errorIndicatorProperties.scaleMode,
			errorIndicatorProperties.caps,
			errorIndicatorProperties.joints, 
			errorIndicatorProperties.miterLimit);
			
			errorIndicator.graphics.drawRoundRect(0, 0, t.width,t.height,errorIndicatorProperties.roundness,errorIndicatorProperties.roundness);
			errorIndicator.x = t.x;
			errorIndicator.y = t.y;
			t.parent.addChild(errorIndicator);
			lastErrorTextfield = t;
			if(onError != null)
				onError();
		}
		/** Primirtive object of key value pairs where <b>key</b> is always <b>name</b> of particular xText instance
		 * containing <i>meta.regexp</i> set and <b>value</b> is <b>text</b> property value of that text field. */
		public function get formObject():Object	{ return xformObject }
		
		/** Removes error indicator from stage */
		public function removeErrorIndicator():void 
		{
			if(errorIndicator.parent != null)
				errorIndicator.parent.removeChild(errorIndicator); 
		}
		
		/** Removes focus indicator from stage */
		public function removeFocusIndicator():void 
		{
			if(indicator.parent != null)
				indicator.parent.removeChild(indicator); 
		}
		/** xText instance on which last validation error occured. May return null if no errors occured. */
		public function get lastError():xText { return lastErrorTextfield }
	}
}