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
	import axl.xdef.interfaces.ixDef;
	
	public class xObject implements ixDef
	{
		private var xdata:Object;
		private var xxroot:xRoot;
		private var xdef:XML;
		private var xmeta:Object = {};
		private var xname:String='unnamedObject';
		public var resetOnAddedToStage:Boolean = true;
		public var reparseMetaEverytime:Boolean=false;
		public var reparsDefinitionEverytime:Boolean=false;
		private var metaAlreadySet:Boolean;
		public function xObject(xml:XML,xroot:xRoot)
		{
			xxroot = xroot;
			xdef = xml;
			xroot.registry[String(xml.@name)] = this;
		}
		public function get xroot():xRoot { return xxroot }
		public function set xroot(v:xRoot):void	{ xxroot = v }
		
		
		public function get meta():Object { return xmeta }
		public function set meta(v:Object):void {
			if(v is String)
				throw new Error("Invalid json for element " +  def.localName() + ' ' +  def.@name );
			if((metaAlreadySet && !reparseMetaEverytime))
				return;
			xmeta =v;
			metaAlreadySet = true;
		}
		
		public function get name():String { return xname }
		public function set name(v:String):void { xname = v}
		
		public function get def():XML { return xdef }
		public function set def(v:XML):void { xdef = v }
		
		public function get data():Object { return xdata }
		public function set data(v:Object):void { xdata = v }
		
		public function reset():void
		{
		}

	}
}