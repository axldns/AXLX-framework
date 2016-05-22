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
	import axl.utils.Counter;
	import axl.xdef.XSupport;
	import axl.xdef.interfaces.ixDef;

	public class xTimer extends Counter implements ixDef
	{
		public var reparseMetaEverytime:Boolean;
		private var root:xRoot;
		private var xdef:XML;
		private var xname:String;
		private var metaAlreadySet:Boolean;
		private var xmeta:Object;
		private var xxroot:xRoot;
		
		public function xTimer(definition:XML,xroot:xRoot=null)
		{
			xxroot = xroot;
			xdef = definition;
			if(this.xroot != null && definition != null)
			{
				var v:String = String(definition.@name);
				if(v.charAt(0) == '$' )
					v = xroot.binCommand(v.substr(1), this);
				this.name = v;
				xroot.registry[this.name] = this;
			}
		}
		public function get xroot():xRoot { return xxroot }
		public function set xroot(v:xRoot):void	{ xxroot = v }
		
		public function get meta():Object { return xmeta }
		public function set meta(v:Object):void 
		{
			if(v is String)
				throw new Error("Invalid json for element " +  def.localName() + ' ' +  def.@name );
			if((metaAlreadySet && !reparseMetaEverytime))
				return;
			xmeta =v;
			metaAlreadySet = true;
		}
		
		public function get def():XML { return xdef }
		public function set def(v:XML):void { xdef = v }
		
		public function reset():void {	XSupport.applyAttributes(def,this) }
		
		override protected function executeOnTimeIndexChange():void
		{
			super.executeOnTimeIndexChange();
			if(onTimeIndexChange is String)
				xroot.binCommand(onTimeIndexChange,this);
			xroot.executeFromXML(name + String(timeIndex));
		}
		
		override protected function executeTimerComplete():void
		{
			super.executeTimerComplete()
			if(onComplete is String)
				xroot.binCommand(onComplete,this);
		}
		
		override protected function executeOnIntervalUpdate():void
		{
			super.executeOnIntervalUpdate();
			if(onUpdate is String)
				xroot.binCommand(onUpdate,this);
		}
	}
}