/**
 *
 * AXLX Framework
 * Copyright 2014-2015 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
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
		private var xrepeat:Object;
		private var dynamicArgs:Object;
		private var stickFunction:Boolean;
		private var stickArgs:Boolean;
		private var func:Function;
		private var aargs:Array;
		private var xowner:Object;
		private var dynamicOwner:Boolean;

		private var target:Object;
		private var refreshArgumentsOnRepeat:Boolean;
		/** Class that allows to execute [target] functions by name. <br>
		 *  xButton can call xRoot directly, by defining "action" object in xButton meta attribute.<br>
		 * @param def - object that contains <code>type</code> which is funciton name, and <code>value</code>  */
		public function xAction(def:Object,xroot:xRoot,xparent:ixDef)
		{
			this.xxparent = xparent;
			this.xrepeat = def.repeat || 1;
			type = def.type;
			value = def.value;
			xdef = def;
			
			stickFunction = def.stickFunction;
			stickArgs = def.stickArgs;
			refreshArgumentsOnRepeat = def.refrefreshArgumentsOnRepeat;
			
			xowner = def.owner;
			if(xowner is String && xowner.charAt(0) == '$')
				xowner = def.owner.substr(1);
			
			dynamicOwner = Boolean(def.hasOwnProperty('dynamicOwner') && def.dynamicOwner == 'true');
			dynamicArgs = def.dynamicArgs;
		}
		/** Owner of the function to execute. By Default main class of the project. */
		public function get xparent():ixDef { return xxparent } 
		public function set xparent(value:ixDef):void { xxparent = value }

		/** Target's function name */
		public function get type():String { return xtype }
		public function set type(value:String):void	{ xtype = value }

		/** An argument or array of arguments for function to execute*/
		public function get value():Object { return xvalue }
		public function set value(v:Object):void { xvalue = (v is Array) ? v : [v] }
		
		/** Executes asigned function*/
		public function execute():void
		{
			trace('eesc');
			var f:Function;
			var a:Object;
			if(func == null || !stickFunction)
				func = findFunc();
			f = func;
			
			if(f == null)
				throw new Error("Unsupported action type: " + type);
			if(!dynamicArgs)
			{
				trace('not dynamic args');
				a = value == 'this' ? xxparent : value;
			}
			else if(!refreshArgumentsOnRepeat)
			{
				if(aargs == null || !stickArgs)
					aargs = (XSupport.getDynamicArgs(value as Array, xxparent.xroot,xxparent) as Array) || [value];
				a = aargs;
			}
			var r:int = 0;
			if(xrepeat is String && xrepeat.charAt(0) == '$')
				r =int(xparent.xroot.binCommand(xrepeat.substr(1),xxparent));
			else
				r = int(xrepeat);
			if(xparent['debug'] )U.log("executing action", r, 'times');
			if(f == xparent.xroot.binCommand && a is Array)
			{
				a[1] = a[1] || xparent;
			}
			if(a == null)
			{
				while(r-->0)
					f();
			}
			else
			{
				if(!refreshArgumentsOnRepeat)
					while(r-->0)
						f.apply(null,a);
				else
				{
					while(r-->0)
						f.apply(null, (XSupport.getDynamicArgs(value as Array, xxparent.xroot,xxparent) as Array));
				}
			}
				
		}
		
		private function findFunc():Function
		{
			var f:Function;
			if(!xxparent)
			{
				U.log('[xAction][execute] UNKNOWN ACTION PARENT!');
				return null;
			}
			
			if(xowner == 'this')
				target = xxparent;
			else if(xowner == null)
				target = xxparent['xroot'];
			else if(dynamicOwner)
			{
				target =  this.xparent.xroot.binCommand(xowner,xxparent);
			}
			else
			{
				if(target == null)
					target =  this.xparent.xroot.binCommand(xowner,xxparent);
			}
			
			if(target && target.hasOwnProperty(type))
			{
				f = target[type] as Function;
				//U.log('[xAction][execute]['+target+']['+xtype+']('+value+')', f);
			}
			else 
				U.log('[xAction][execute]['+target+']['+xtype+']('+value+') - UNKNOWN FUNCTION OWNER', xowner, 'as', target)
			return f;
		}
	}
}