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
	import axl.xdef.types.xRoot;

	public interface ixDef
	{
		function get def():XML;
		function set def(v:XML):void;
		function get meta():Object;
		function set meta(v:Object):void;
		/** Each element should be name-referenceable. This is the core functionality; to allow all elements within XML
		 * config file to be found, instantiated, added to displaylist, animated, removed from displaylist, referenced from other elements, changed,
		 * functions to be executed, it has to be legitimated by name property. Unlike naming proprty ID or anyhow else, this allows easy integration
		 * with non-framework elements */
		function get name():String;
		function set name(v:String):void;
		function get xroot():xRoot;
		function set xroot(v:xRoot):void;
		function reset():void;
	}
	
}