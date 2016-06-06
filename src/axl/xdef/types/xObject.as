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
	import axl.xdef.interfaces.ixDef;
	/** Lightweight class for loading data and providing an easy acces to its contents, without accessing internal
	 * assset manager. Instantiated from: <h3><code>&lt;data/&gt;<br></code></h3>
	 * Data parsing is available right after defining src attribute. Loaded data passes through  
	 * known types check in order to instantiate valid ActionScript objects, according to <code>Ldr.load</code> Example:<br>
	 * <pre> &lt;data src='audio.mp3' anything='$this.data.play()'/&gt; 
	 * @see axl.utils.Ldr */
	public class xObject implements ixDef
	{
		protected var xdata:Object;
		protected var xdef:XML;
		protected var xmeta:Object;
		protected var xxroot:xRoot;
		private var xname:String;
		private var xparent:Object;
		/** Lightweight data class instantiated from <code>&lt;data/&gt;<br></code>
		 * @param definition - xml definition
		 * @param xroot - reference to parent xRoot object
		 * @see axl.xdef.types.xObject
		 * @see axl.xdef.interfaces.ixDef#def
		 * @see axl.xdef.interfaces.ixDef#xroot
		 * @see axl.xdef.XSupport#getReadyType2() */
		public function xObject(definition:XML,xroot:xRoot)
		{
			xxroot = xroot;
			xdef = definition;
			xroot.support.register(this);
		}
		/** Reference to parent xRoot object @see axl.xdef.types.xRoot
		 *  @see axl.xdef.interfaces.ixDef#xroot */
		public function get xroot():xRoot { return xxroot }
		public function set xroot(v:xRoot):void	{ xxroot = v }
		
		/** XML definition of this object @see axl.xdef.interfaces.ixDef#def */
		public function get def():XML { return xdef }
		public function set def(v:XML):void { xdef = v }
		
		/** Dynamic variables container. It's set up only once. Subsequent applying XML attributes
		 * or calling reset() will not have an effect. @see axl.xdef.interfaces.ixDef#meta  */
		public function get meta():Object { return xmeta }
		public function set meta(v:Object):void 
		{
			if(v is String)
				throw new Error("Invalid json for element " +  def.localName() + ' ' +  def.@name );
			if(!v || meta) return;
			xmeta =v;
		}
		
		/** Sets name and registers object in registry @see axl.xdef.types.xRoot.registry */
		public function get name():String { return xname }
		public function set name(v:String):void
		{
			xname = xroot.support.requestNameChange(v,this);
		}
		/** Whatever content (text, JSON, XML, sound, other) has been loaded/specified in 
		 * <code>src</code> attribute - it's accesible through this property.*/
		public function get data():Object { return xdata }
		public function set data(v:Object):void { xdata = v }
		/** Method reset doesn't apply for xObject instance */
		public function reset():void { }
		
		/** Allows to asign owner of this object. By default it's whichever node
		 * that contains it in xml */
		public function get parent():Object { return xparent }
		public function set parent(v:Object):void {  xparent = v}
	}
}