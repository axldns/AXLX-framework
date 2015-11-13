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
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.FocusEvent;
	
	import axl.utils.U;

	public class xForm extends xSprite
	{
		
		private var currentFocused:xText;
		private var indicatorProperties:Object = {thickness:2,color:0xFFFFFF,alpha:1,pixelHinting:true,scaleMode:"normal",caps:null,joints:null,miterLimit:3};
		private var errorIndicatorProperties:Object = {thickness:2,color:0xFF0000,alpha:1,pixelHinting:true,scaleMode:"normal",caps:null,joints:null,miterLimit:3};
		private var errorIndicator:Shape;
		private var indicator:Shape;
		private var buttonSubmit:xButton;
		private var toValidate:Vector.<xText> = new Vector.<xText>();
		private var xformObject:Object = {}
		
		public function xForm(definition:XML=null, xroot:xRoot=null)
		{
			super(definition, xroot);
			indicator = new Shape();
			errorIndicator = new Shape();
			
			this.addEventListener(FocusEvent.FOCUS_IN, focusIn);
		}
		
		protected function focusIn(e:FocusEvent):void
		{
			indicator.graphics.clear();
			U.log(e.target,e);
			currentFocused = e.target as xText;
			if(currentFocused == null)
				return;
			if(errorIndicator.parent != null)
				errorIndicator.parent.removeChild(errorIndicator);
			
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
			
			indicator.graphics.drawRect(0, 0, currentFocused.width,currentFocused.height);
			indicator.x = currentFocused.x;
			indicator.y = currentFocused.y;
			currentFocused.parent.addChild(indicator);
		}
		
		override protected function elementAdded(e:Event):void
		{
			super.elementAdded(e);
			var xb:xButton = e.target as xButton;
			if(xb && xb.name.match(/submit/i))
			{
				xb.externalExecution = true;
				buttonSubmit = xb;
				buttonSubmit.externalExecution = true;
				buttonSubmit.onClick = submitClick;
			}
			else
			{
				var t:xText = e.target as xText;
				if(t && t.meta.hasOwnProperty('regexp') && toValidate.indexOf(t) < 0)
					toValidate.push(t);
			}
		}
		
		private function submitClick():void
		{
			var j:int = this.toValidate.length;
			var t:xText;
			var r:RegExp;
			for(var i:int = 0; i < j;i++)
			{
				t = toValidate[i];
				formObject[t.name] = t.text;
				if(!t.text.match(t.meta.regexp))
					return addError(t);
			}
			if(buttonSubmit)
				buttonSubmit.execute();
		}		
		
		private function  addError(t:xText):void
		{
			U.log("Form validation error in ", t, t.name, "didn't match", t.meta.regexp);
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
			
			errorIndicator.graphics.drawRect(0, 0, t.width,t.height);
			errorIndicator.x = t.x;
			errorIndicator.y = t.y;
			t.parent.addChild(errorIndicator);
			
		}

		public function get formObject():Object	{ return xformObject }

		
	}
}