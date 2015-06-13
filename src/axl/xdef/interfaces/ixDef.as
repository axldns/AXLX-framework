package axl.xdef.interfaces
{
	import flash.events.IEventDispatcher;

	public interface ixDef extends IEventDispatcher
	{
		function get def():XML;
		function get meta():Object;
		function reset():void;
	}
	
}