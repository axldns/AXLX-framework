package axl.xdef.types
{
	import axl.xdef.interfaces.ixDef;

	public class xActionSet implements ixDef
	{
		private var xxroot:xRoot;
		private var xdef:XML;
		private var xmeta:Object;
		private var metaAlreadySet:Boolean;
		private var reparseMetaEverytime:Boolean;
		private var xname:String;
		private var actions:Vector.<xAction> = new Vector.<xAction>();
		private var executeArgs:Array;
		public var code:String;
		public var debug:Boolean;
		public var repeat:Number;
		public function xActionSet(definition:XML,xrootObject:xRoot)
		{
			xxroot = xrootObject;
			xdef = definition;
			if(this.xroot != null && definition != null)
			{
				var v:String = String(definition.@name);
				if(v.charAt(0) == '$' )
					v = xroot.binCommand(v.substr(1), this);
				this.name = v;
				xroot.registry[this.name] = this;
			}
			parse();
		}
		
		private function parse():void
		{
			var a:Object, b:Array, i:int, j:int;
			if(!meta || meta is String)
				return
			if(meta.hasOwnProperty('action'))
			{
				a = meta.action;
				b = (a is Array) ? a as Array : [a];
				for(i = 0, j = b.length; i<j; i++)
					actions[i] = new xAction(b[i],xroot,this);
			}
		}
		public function get arguments():Array { return executeArgs };
		public function execute(...args):void
		{
			executeArgs = args;
			for(var i:int = 0, j:int = actions.length; i<j; i++)
				actions[i].execute();
			if(code!=null)
			{
				if(isNaN(repeat))
					xroot.binCommand(code,this);
				else
					for(i=repeat; i-->0;)
						xroot.binCommand(code,this);
						
			}
		}
		public function get xroot():xRoot { return xxroot }
		public function set xroot(v:xRoot):void	{ xxroot = v }
		
		
		public function get meta():Object { return xmeta }
		public function set meta(v:Object):void {
			if(v is String)
				throw new Error("Invalid json for element " +  def.localName() + ' ' +  def.@name );
			if((metaAlreadySet && !reparseMetaEverytime))
				return;
			xmeta =v;
			metaAlreadySet = true;
			parse();
		}
		
		public function get name():String { return xname }
		public function set name(v:String):void { xname = v}
		
		public function get def():XML { return xdef }
		public function set def(v:XML):void { xdef = v }
		
		
		public function reset():void
		{
		}

		
	}
}