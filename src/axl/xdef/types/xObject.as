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
	
	import axl.xdef.XSupport;
	import axl.xdef.interfaces.ixDef;
	
	public class xObject implements ixDef
	{
		private var xdata:Object;
		private var xxroot:xRoot;
		private var xdef:XML;
		private var xmeta:Object = {};
		private var xname:String='unnamedObject';
		public function xObject(xml:XML,xroot:xRoot)
		{
			xxroot = xroot;
			xdef = xml;
			XSupport.applyAttributes(xml, this);
		}
		public function get xroot():xRoot { return xxroot }
		public function set xroot(v:xRoot):void	{ xxroot = v }
		
		
		public function get meta():Object { return xmeta }
		public function set meta(v:Object):void { xmeta =v }
		
		public function get name():String { return xname }
		public function set name(v:String):void { xname = v}
		
		public function get def():XML { return xdef }
		public function set def(v:XML):void { xdef = v }
		
		public function get data():Object { return xdata }
		public function set data(v:Object):void { xdata = v }
		
		public function reset():void
		{
		}
		
		public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void
		{
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void
		{
		}
		
		public function dispatchEvent(event:Event):Boolean
		{
			return false;
		}
		
		public function hasEventListener(type:String):Boolean
		{
			return false;
		}
		
		public function willTrigger(type:String):Boolean
		{
			return false;
		}

	}
}