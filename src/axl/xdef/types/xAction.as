package axl.xdef.types
{
	import axl.xdef.interfaces.ixDef;

	/** Class that allows to execute [target] functions by name.
	 *  xButton call xRoot directly, by defining "action" object in xButton meta attribute*/
	public class xAction
	{
		private var xtype:String;
		private var xvalue:Object;
		private var xtarget:ixDef;
		/** Class that allows to execute [target] functions by name. <br>
		 *  xButton can call xRoot directly, by defining "action" object in xButton meta attribute.<br>
		 * @param def - object that contains <code>type</code> which is funciton name, and <code>value</code>  */
		public function xAction(def:Object)
		{
			target = xRoot.instance;
			type = def.type;
			value = def.value;
		}
		
		/** Owner of the function to execute. By Default main class of the project. */
		public function get target():ixDef { return xtarget } 
		public function set target(value:ixDef):void { xtarget = value }

		/** Target's function name */
		public function get type():String { return xtype }
		public function set type(value:String):void	{ xtype = value }

		/** An argument for executed function*/
		public function get value():Object { return xvalue }
		public function set value(v:Object):void { xvalue = (v is Array) ? v : [v] }
		
		/** Executes asigned function*/
		public function execute():void
		{
			var f:Function;
			if(target['hasOwnProperty'](type))
				f = target[type] as Function;
			if(f == null)
				throw new Error("Unsupported action type: " + type);
			f.apply(null,value);
		}
	}
}