package axl.xdef.interfaces
{
	import flash.events.IEventDispatcher;

	public interface ixDef extends IEventDispatcher
	{
		function get def():XML;
		function set def(v:XML):void;
		function get meta():Object;
		function set meta(v:Object):void;
		function reset():void;
	}
	
}