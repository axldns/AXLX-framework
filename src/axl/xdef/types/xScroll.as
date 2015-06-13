package axl.xdef.types
{
	import axl.ui.controllers.BoundBox;

	public class xScroll extends BoundBox
	{
		
		private var xdef:XML;
		public function xScroll(def:XML)
		{
			super();
			xdef = def;
			xdef.children();
		}
	}
}