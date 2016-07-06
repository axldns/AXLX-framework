/**
 *
 * AXLX Framework
 * Copyright 2014-2016 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package axl.xdef.interfaces
{
	import axl.xdef.types.display.xRoot;
	/** Interface that allows to identify, parse and proceed valid XML children of config file to
	 * functional elements of the project. */
	public interface ixDef
	{
		/** Implementer should store and be able to return its original XML definition -
		 * set of attributes mapped to properties and its sub nodes - children. */
		function get def():XML;
		function set def(v:XML):void;
		/** Every element must belong to project to exactly one root container. Only this way implementer
		 * is able to be served by registry.  */
		function get xroot():xRoot;
		function set xroot(v:xRoot):void;
		/** Implementer must provide variables dynamic container - space for animations definitions
		 * and any other referenceable properties. This variable suppose to be set up just once (be reset-resistant) 
		 * in order to securely store data/states. */
		function get meta():Object;
		function set meta(v:Object):void;
		/** Each element should be name-referenceable. This is the core functionality; to allow all elements within XML
		 * config file to be found, instantiated, added to displaylist, animated, removed from displaylist, referenced from other elements, changed,
		 * functions to be executed, it has to be legitimated by name property. Unlike naming proprty ID or anyhow else, this allows easy integration
		 * with non-framework elements */
		function get name():String;
		function set name(v:String):void;
		/** Every implementer must provide method which allows to reset it's properties to original, XML definition 
		 * defined state. */
		function reset():void;
		
	}
}