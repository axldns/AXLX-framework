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
	import axl.utils.AO;
	import axl.utils.Counter;
	import axl.xdef.XSupport;
	import axl.xdef.interfaces.ixDef;
	/** Non-displayable class that provides advanced timer functions. Instantiated 
	 * from: <h3><code>&lt;timer/&gt;</code></h3>
	 * Extends axl.utils.Counter by providing XML interface to it. Additionaly,
	 * ancestor's callback can be defined as uncompiled portion of code - an
	 * arguments for xRoot.binCommand. @see axl.utils.Counter @see axl.xdef.types.xRoot#binCommand */
	public class xTimer extends Counter implements ixDef
	{
		private var root:xRoot;
		private var xdef:XML;
		private var xname:String;
		private var metaAlreadySet:Boolean;
		private var xmeta:Object;
		private var xxroot:xRoot;
		
		/** Non-displayable class that provides advanced timer functions. Instantiated 
		 * from <code>&lt;timer/&gt;</code> 
		 * @param definition - xml definition @param xroot - reference to parent xRoot object
		 * @see axl.xdef.types.xTimer
		 * @see axl.xdef.interfaces.ixDef#def
		 * @see axl.xdef.interfaces.ixDef#xroot
		 * @see axl.xdef.XSupport#getReadyType2() */
		public function xTimer(definition:XML,xrootObj:xRoot=null)
		{
			this.xroot = xrootObj || this.xroot;
			this.xdef = definition;
			xroot.support.register(this);
		}
		//----------------------- INTERFACE METHODS -------------------- //
		/** XML definition of this object @see axl.xdef.interfaces.ixDef#def */
		public function get def():XML { return xdef }
		public function set def(value:XML):void 
		{ 
			if((value == null))
				return;
			xdef = value;
			XSupport.applyAttributes(def, this);	
		}
		/** Reference to parent xRoot object @see axl.xdef.types.xRoot 
		 * @see axl.xdef.interfaces.ixDef#xroot */
		public function get xroot():xRoot { return xxroot }
		public function set xroot(v:xRoot):void	{ xxroot = v }
		
		/** Dynamic variables container. It's set up only once. Subsequent applying XML attributes
		 * or calling reset() will not have an effect. 
		 * @see axl.xdef.interfaces#meta */
		public function get meta():Object { return xmeta }
		public function set meta(v:Object):void 
		{
			if(v is String)
				throw new Error("Invalid json for element " +  def.localName() + ' ' +  def.@name );
			if(!v || meta) return;
			xmeta =v;
		}
		
		/** Sets name and registers object in registry 
		 * @see axl.xdef.types.xRoot.registry @xee axl.xdef.interfaces.ixDef#name */
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
			XSupport.applyAttributes(def, this);	
		}
		
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