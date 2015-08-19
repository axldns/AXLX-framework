package axl.xdef.interfaces
{
	import flash.events.IEventDispatcher;
	
	import axl.xdef.types.xRoot;

	public interface ixDef extends IEventDispatcher
	{
		function get def():XML;
		function set def(v:XML):void;
		function get meta():Object;
		function set meta(v:Object):void;
		function get name():String;
		function set name(v:String):void;
		function get xroot():xRoot;
		function set xroot(v:xRoot):void;
		function reset():void;
	}
	
}