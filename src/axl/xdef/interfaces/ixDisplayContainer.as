/**
 *
 * AXLX Framework
 * Copyright 2014-2016 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package axl.xdef.interfaces
{
	/** Interface that allows to identify, parse and proceed valid XML children of config file to
	 * functional <b>Display Object Containers</b> Every implementer must provide function
	 * to execute when initial creation is complete, as well as listen to Event.ADDED on it's own
	 * display list on order to be able to execute onElementAdded method.  */
	public interface ixDisplayContainer extends ixDisplay
	{
		/** This method must allow to define <b>additional</b> XML defined action executed only once:
		 * when all original XML defined children of implementer are instantiated and added to implementer's
		 * display list. This function is not to be executed by implementer. Core parser will call it. 
		 * This can be reference to a function or portion of uncompiled code (argument for binCommand)
		 * @see axl.xdef.types.xRoot#binCommand() @see axl.xdef.XSupport#pushReadyTypes2() */
		function get onChildrenCreated():Object;
		function set onChildrenCreated(v:Object):void;
		
		/** This method must allow to define <b>additional</b> XML defined action executed every time an
		 * object is added to ixDisplayContainer display list 
		 * This can be reference to a function or portion of uncompiled code (argument for binCommand)
		 * @see axl.xdef.types.xRoot#binCommand() @see axl.xdef.XSupport#pushReadyTypes2() */
		function get onElementAdded():Object;
		function set onElementAdded(v:Object):void;
	}
}