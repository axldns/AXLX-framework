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
	 * functional, <b>displayable</b> elements of the project.<br><br> Every element must handle 
	 * it's own addition to stage. Ideally execute animations  defined in meta.addedToStage, 
	 * respect resetOnAddedToStage parameter, only enabling it's other "ENTER_FRAME" related functions
	 *  when on stage.<br><br> */
	public interface ixDisplay extends ixDef
	{
		/** This method must allow to define <b>additional</b> XML defined action executed every time
		 * implementer is added to stage, specified in attribute named <i>onAddedToStage</i>. 
		 * This can be reference to a function or portion of uncompiled code (argument for binCommand)
		 *  @see axl.xdef.types.xRoot#binCommand() */
		function get onAddedToStage():Object;
		function set onAddedToStage(v:Object):void;
		/** This method must allow to define <b>additional</b> XML defined action executed every time
		 * implementer is removed from stage, specified in attribute named <i>onRemovedFromStage</i>. 
		 * This can be reference to a function or portion of uncompiled code (argument for binCommand).
		 *  @see axl.xdef.types.xRoot#binCommand() */
		function get onRemovedFromStage():Object;
		function set onRemovedFromStage(v:Object):void;
		/** Implementors must be able to handle styles - Object or an Array of objects containing
		 * key-value pairs where key is a property of implementor and value - value for that 
		 * property. Ideal implementation:<br>
		 * <code>implementor.xroot.support.applyStyle(style,implementor);</code>
		 * @see axl.xdef.XSupport#applyStyle() */
		function get styles():Object;
		function set styles(v:Object):void;
		/** Every time object is (re)added to stage method <code>reset</code> can be called. 
		 * Aim of method reset is to bring object to its initial state (defined by xml) by reparsing it's attributes
		 * reassigning its values to implementor, killing all animations @see #reset() */
		function get resetOnAddedToStage():Boolean;
		function set resetOnAddedToStage(v:Boolean):void;
	}
}