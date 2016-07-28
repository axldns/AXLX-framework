/**
 *
 * AXLX Framework
 * Copyright 2014-2016 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package axl.xdef.types
{
	import axl.xdef.interfaces.ixDef;
	import axl.xdef.types.display.xRoot;

	/**
	 * Class that allows to execute at runtime XML defined funciton.<br>
	 * Instantiated from &lt;act/> node and can be referenced from registry.
	 * This class is non displayable (lightweight) object that can be placed in config file
	 * and executed only via direct or referenced execute call.
	 * @see #execute()
	 */
	public class xAction implements ixDef
	{
		private var xxroot:xRoot;
		private var xdef:XML;
		private var xmeta:Object;
		private var xname:String;
		private var executeArgs:Array;
		private var iterationIndex:int=-1;
		/**
		 *  Determines <code>binCommand</code> level of output trace.<br>
		 * Above applies to binCommand via <code>code</code> attrubute only.
		 * Classic Actions within meta object should be set individually.
		 * @default 1
		 * @see axl.xdef.xtypes.xRoot#binCommand()*/
		public var debug:int=1;
		/**
		 * Number of times action is going to be executed on a single call.
		 * Parameter as any other argument can be referenced dynamically 
		 * and changed on the fly. Useful for loops. Iteration index is available
		 * during loop as <code>iteration</code> property of this.
		 * @default 0 - just one exec
		 * @see iteration */
		public var repeat:Number;
		/**
		 * Property containing uncompiled code for binCommand. <br>
		 * <code> code="stage.removeChildren()"</code>
		 * <br>The string is going to be parsed / code evaluated on execution, every execution.<br>
		 * <b>Confusion</b> may occur as, unlike with other in-attrubute-code-executions, you probably don't want to prepend
		 * your config "code" attrubute value with dolar sign, unless you want to 
		 * reference code containing variable to somewhere else.<br> 
		 * @see axl.xdef.types.display.xRoot#binCommand() */
		public var code:String;
		/**
		 * Instantiates class that interpretates XML defined function and makes it available for 
		 * execution.
		 * @param definition - xml definition. eg:<code> &lt;act name='ref' code='[trace(123)]'/></code>
		 * @param xrootObject - parent root object for <code>binCommand</code> context
		 * @see #execute()
		 * @see axl.xdef.types.display.xRoot#binCommand()
		 */
		public function xAction(definition:XML,xrootObject:xRoot)
		{
			xxroot = xrootObject;
			xdef = definition;
			xroot.support.register(this);
		}
		
		/** Executes actions defined within <code>code</code> property.<br>Action is executed
		 * <code>repeat</code> number of times.<br>
		 * Iteration number is publicly available via <code>iteration</code>
		 * property during execution.<br>Arguments passed to this function  are
		 * publicly available via <code>arguments</code> getter
		 * @see #code @see #repeat
		 * @see #arguments @see #iteration
		 * @see axl.xdef.types.xAction
		 *  */
		public function execute(...args):*
		{
			executeArgs = args;
			if(code!=null)
			{
				if(isNaN(repeat))
					return xroot.binCommand(code,this,debug);
				else
					for(iterationIndex=0; iterationIndex < repeat;iterationIndex++)
						xroot.binCommand(code,this,debug);
			}
			iterationIndex =-1;
		}
		/** Number of current iteration if <code>repeat</code> is set.<br>
		 * -1 means either <code>repeat</code> is not set or the loop is over. @see #repeat */
		public function get iteration():int { return iterationIndex }
		
		/** Last arguments that were passed to <code>execute</code> function.
		 * Usefull for event handling. @see #execute() */
		public function get arguments():Array { return executeArgs }
		
		/** Root object that this action set belongs too */
		public function get xroot():xRoot { return xxroot }
		public function set xroot(v:xRoot):void	{ xxroot = v }
		
		/** Dynamic variables container. It's set up only once. Subsequent applying XML attributes
		 * or calling reset() will not have an effect. @see axl.xdef.interfaces.ixDef#meta  */
		public function get meta():Object { return xmeta }
		public function set meta(v:Object):void 
		{
			if(v is String)
				throw new Error("Invalid json for element " +  def.localName() + ' ' +  def.@name );
			if(!v || meta) return;
			xmeta =v;
		}
		
		/** Name that allows to reference this object through registry 
		 * @see axl.xdef.interfaces.ixDef#name*/
		public function get name():String { return xname }
		public function set name(v:String):void { xname = xroot.support.requestNameChange(v,this);}
		
		/** XML definition of this class instance
		 * @see axl.xdef.interfaces.ixDef#def*/
		public function get def():XML { return xdef }
		public function set def(v:XML):void { xdef = v }
		
		/** This class does not use <code>reset</code> functionality
		 *  @see axl.xdef.interfaces.ixDef#reset() **/
		public function reset():void
		{
		}
	}
}