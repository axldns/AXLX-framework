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
	import axl.utils.U;
	import axl.xdef.XSupport;
	import axl.xdef.types.display.xRoot;
	
	/** Lightweight class for loading external config definitions. Instantiated from: <h3><code>&lt;script/&gt;<br></code></h3>
	 * Externalizing portions of code / definitions allows to keep projects more structured, share elements between them, speeds
	 * up development process by providing re-usable, modular components.<br>
	 * This instance (unlike others) modifies original root XML config by including XML children contained in additions node of this instance
	 * to additions node of root config's addition node - pool of definitions. <br>
	 * <h4>Script Structure</h4> 
	 * Defining script with src attribute in root XML config allows to load external XML. Make use of cacheBust attribute if your template is 
	 * updated frequently. Sample use
	 * 
	 * <pre>
	 * &lt;root&gt;<br>
	 * 	&lt;script src='../shared/templates/videoPlayer.xml' cacheBust='true' /&gt;<br>
	 * &lt;/root&gt;<br>
	 * </pre>
	 * Loaded XML is expected to contain <b>additions</b> node only. All children of that node will be injected to root config additions node.<br>
	 * There is no instantiation involved - just XML definitions are added and made available to use from top level.
	 * <pre>
	 * &lt;config&gt;<br>
	 * 	&lt;additions meta='{}' onInclude='log("onInclude")' onIncluded='log("onIncluded")' &gt;<br>
	 * 		&lt;btn name="magicButton"&gt;<br>
	 * 			&lt;img name='over' src='../shared/mbover.png'/&gt;<br>
	 * 			&lt;img name='out' src='../shared/mbout.png'/&gt;<br>
	 * 		&lt;/btn&gt;<br>
	 * 	&lt;/additions&gt;<br>
	 * &lt;/config&gt;<br>
	 * </pre> */
	public class xScript extends xObject
	{
		/** Determines logging @default false*/
		public var debug:Boolean = false;
		/** Determines if script is included at instantiation (true) or waits for manual call of <code>includeScript</code> method (false).
		 * @see #includeScript() */
		public var autoInclude:Boolean = true;
		/** Function or portion of uncompiled code to execute when object is set up but right before modifying original root config XML.
		 * br>This field must be defined within loaded XML additions attributes and not in root XML.<br>
		 * An argument for binCommand. @see axl.xdef.types.display.xRoot#binCommand() */
		public var onInclude:Object;
		/** Function or portion of uncompiled code to execute right after inclusion of loaded additions to original root config XML.
		 * From this moment, all loaded definitions are available in root additions.<br>This field must be defined within loaded XML 
		 * additions attributes and not in root XML.<br>
		 * An argument for binCommand. @see axl.xdef.types.display.xRoot#binCommand() */
		public var onIncluded:Object;
		/** Allows to load and include external XML objects definitions to root config. Instantiated from <code>&lt;script/&gt;</code><br>
		 * @param definition - xml definition
		 * @param xroot - reference to parent xRoot object
		 * @see axl.xdef.types.xScript
		 * @see axl.xdef.interfaces.ixDef#xroot
		 * @see axl.xdef.XSupport#getReadyType2()  */
		public function xScript(definition:XML, xroot:xRoot)
		{
			super(definition, xroot);
		}
		/** Allows to include script manually, on demand. Should be used along with <code>autoInclude=false</code>, otherwise (simmilarly to subsequent
		 * calls to this method) root config will be modified multiple times and object definitons will be duplicated. */
		public function includeScript():void
		{
			if(!(data is XML) || !data.hasOwnProperty("additions"))
				throw new Error("Elements loaded from <script/> tag must contain valid XML which contains <additions/> node: " + this.name);
			var additions:XML = data.additions[0];
			
			XSupport.applyAttributes(additions,this);
			if(debug) U.log("script", this.name, "has defined actions onInclude: ", onInclude!=null, "onIncluded: ", onIncluded!=null);
			if(onInclude is String)
				xroot.binCommand(onInclude,this);
			if(onInclude is Function)
				onInclude();
			
			var xl:XMLList = additions.children() as XMLList;
			var len:int = xl.length();
			var target:XML = xroot.config.additions[0];
			for(var i:int=0; i<len;i++)
				target.appendChild(xl[i]);
			if(debug) U.log(len,"elements included to additions from script: " + this.name);
			
			if(onIncluded is String)
				xroot.binCommand(onIncluded,this);
			if(onIncluded is Function)
				onIncluded();
		}
	}
}