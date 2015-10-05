package axl.xdef.types
{
	import axl.utils.U;
	import axl.xdef.XSupport;
	import axl.xdef.interfaces.ixDef;

	/** Class that allows to execute [target] functions by name.
	 *  xButton call xRoot directly, by defining "action" object in xButton meta attribute*/
	public class xAction
	{
		private var xtype:String;
		private var xvalue:Object;
		private var xdef:Object;
		private var xxparent:ixDef;
		private var xowner:String;
		private var dynamicOwner:Boolean;
		private var xownerArray:Array;
		private var dynamicArgs:Object;
		/** Class that allows to execute [target] functions by name. <br>
		 *  xButton can call xRoot directly, by defining "action" object in xButton meta attribute.<br>
		 * @param def - object that contains <code>type</code> which is funciton name, and <code>value</code>  */
		public function xAction(def:Object,xroot:xRoot,xparent:ixDef)
		{
			this.xxparent = xparent
			type = def.type;
			value = def.value;
			xdef = def;
			xowner = def.owner;
			if(xowner && xowner.charAt(0) == '$')
				xownerArray = xowner.substr(1).split('.');
			dynamicArgs = def.dynamicArgs;
			
				
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
			var f:Function;
			if(!xxparent)
				return U.log('[xAction][execute] UNKNOWN ACTION PARENT!');
			var target:Object;
			if(xownerArray != null)
				target =  XSupport.simpleSourceFinderByArray(xxparent, xownerArray);
			else if(xowner == 'this')
				target = xxparent;
			else
				target = xxparent['xroot'];
			
			if(target && target.hasOwnProperty(type))
			{
				f = target[type] as Function;
				U.log('[xAction][execute]['+xtype+']('+value+')', f);
			}
			else 
				U.log('[xAction][execute]['+xtype+']('+value+') - UNKNOWN FUNCTION OWNER', xowner, 'as', target);
			
			if(f == null)
				throw new Error("Unsupported action type: " + type);
			if(xvalue[0] == undefined)
				f()
			else if(!dynamicArgs)
				f.apply(null,value);
			else
			{
				if(value is Array)
					f.apply(null, getDynamicArgs(value as Array));
				else if(value is String && value.charAt(0) == '$')
					f.apply(null, XSupport.simpleSourceFinder(xxparent.xroot, value.substr(1)));
				else
					f.apply(null,value);
			}
		}
		
		private function getDynamicArgs(v:Array):Array
		{
			var a:Array = v.concat();
			for(var i:int = a.length; i-->0;)
			{
				var o:Object = a[i];
				if(o is String && o.charAt(0) == '$')
					a[i] = XSupport.simpleSourceFinder(xxparent.xroot, o.substr(1));
			}
			return a;
		}
	}
}