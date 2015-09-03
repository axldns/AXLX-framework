package axl.xdef.types
{
	import axl.utils.U;
	import axl.xdef.interfaces.ixDef;

	/** Class that allows to execute [target] functions by name.
	 *  xButton call xRoot directly, by defining "action" object in xButton meta attribute*/
	public class xAction
	{
		private var xtype:String;
		private var xvalue:Object;
		private var xdef:Object;
		private var xxparent:ixDef;
		/** Class that allows to execute [target] functions by name. <br>
		 *  xButton can call xRoot directly, by defining "action" object in xButton meta attribute.<br>
		 * @param def - object that contains <code>type</code> which is funciton name, and <code>value</code>  */
		public function xAction(def:Object,xroot:xRoot,xparent:ixDef)
		{
			this.xxparent = xparent
			type = def.type;
			value = def.value;
			xdef = def;
		}
		/** Owner of the function to execute. By Default main class of the project. */
		public function get xparent():ixDef { return xxparent } 
		public function set xparent(value:ixDef):void { xxparent = value }

		/** Target's function name */
		public function get type():String { return xtype }
		public function set type(value:String):void	{ xtype = value }

		/** An argument for executed function*/
		public function get value():Object { return xvalue }
		public function set value(v:Object):void { xvalue = (v is Array) ? v : [v] }
		
		/** Executes asigned function*/
		public function execute():void
		{
			U.log("EXECUTE", xxparent);
			var f:Function;
			if(!xxparent)
				return;
			if(xparent.xroot['hasOwnProperty'](type))
			{
				f = xxparent.xroot[type] as Function;
				U.log('[xAction][execute]['+xtype+']('+value+')', f);
			}
			else if(xxparent['hasOwnProperty'](type))
			{
				f = xxparent[type] as Function;
				U.log('[xAction][execute]['+xtype+']('+value+')', f);
			}
			
			if(f == null)
				throw new Error("Unsupported action type: " + type);
			if(xvalue[0] == undefined)
			{
				U.log(' execute no args', f, type);
				f()
			}
			else
				f.apply(null,value);
		}
	}
}