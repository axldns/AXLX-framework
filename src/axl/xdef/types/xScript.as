/**
 *
 * AXLX Framework
 * Copyright 2014-2016 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package axl.xdef.types
{
	import axl.utils.U;
	import axl.xdef.XSupport;
	import axl.xdef.types.display.xRoot;

	public class xScript extends xObject
	{
		public var debug:Boolean = true;
		public var autoInclude:Boolean = true;
		public var onInclude:Object;
		public var onIncluded:Object;
		
		public function xScript(definition:XML, xroot:xRoot)
		{
			super(definition, xroot);
		}
		
		public function includeScript():void
		{
			if(!(data is XML) || !data.hasOwnProperty("additions"))
				throw new Error("Elements loaded from <script/> tag must contain valid XML which contains <additions/> node: " + this.name);
			var additions:XML = data.additions[0];
			
			XSupport.applyAttributes(additions,this);
			if(debug) U.log("script", this.name, "has defined actions onInclude: ", onInclude!=null, "onIncluded: ", onIncluded!=null);
			if(onInclude is String)
				xroot.binCommand(onInclude,this);
			if(onInclude is Function)
				onInclude();
			
			var xl:XMLList = additions.children() as XMLList;
			var len:int = xl.length();
			var target:XML = xroot.config.additions[0];
			for(var i:int=0; i<len;i++)
				target.appendChild(xl[i]);
			if(debug) U.log(len,"elements included to additions from script: " + this.name);
			
			if(onIncluded is String)
				xroot.binCommand(onIncluded,this);
			if(onIncluded is Function)
				onIncluded();
		}
		
	}
}