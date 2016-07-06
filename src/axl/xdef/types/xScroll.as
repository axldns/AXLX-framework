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
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import axl.ui.controllers.BoundBox;
	/** Class provides simple scroll bar functionality. Instantiated from &lt;scrollBar/&gt;.<br>
	 * It makes use of <code>axl.ui.controllers.BoundBox</code> controler, which needs
	 * two Display Objects to satisfy functionality (bound & box), here named as
	 * <code>rail</code> and <code>train</code>.
	 * <h3>Backward compatibility</h3>
	 * Scroll bar instance recognizes Display Obecjts added to its display list, and  auto-links functionality
	 *  if their name matches pattern. List of (case insensitive) names recognized:<ul><li>rail</li>
	 * <li>train</li><li>btnLeft</li><li>btnRight</li><li>btnDown</li><li>btnUp</li></ul>
	 * Since need of access the buttons through the registry and having multiple scroll bar instances
	 * at the same time, some of "rail", "train" and other may simply become unavailable. Thus
	 * official assignments should be made, eg.:<br><code>scrollBar.rail = this;<br>scrollBar.train = that;</code><br>
	 * <br>Scroll bar can have only one orientation at the time, hence btnIncrease and btnDecrease should be 
	 * subject of assignments onward while setting controller's orientation to both horizontal and vertical may 
	 * result in unexpected output.<br>
	 * Controller's initial values can be overriden, default values as follows:<br>
	 * <code>ctrl.bound = rail;<br>ctrl.box = train;<br>ctrl.horizontalBehavior = BoundBox.inscribed;
	 * <br>ctrl.verticalBehavior = BoundBox.inscribed;<br>ctrl.liveChanges = true;</code></br>
	 * <u>Requires to set initial orinetation</u>
	 * 	@see axl.ui.controllers.BoundBox */
	public class xScroll extends xSprite
	{
		private var ctrl:BoundBox;
		private var xrail:DisplayObject;
		private var xtrain:DisplayObject;
		private var xbtnIncrease:xButton;
		private var xbtnDecrease:xButton;
		
		/** Determines scroll efficiency default 1. For container containing text fields optimal value is 15*/
		public var deltaMultiplier:Number=1;
		/** Deterimines if masked content movement can be triggered by mouse wheel events.  @see #deltaMultiplier */
		public var wheelScrollAllowed:Boolean = false;
		/** Class provides simple scroll bar functionality. Instantiated from &lt;scrollBar/&gt;.<br>
		 * It makes use of <code>axl.ui.controllers.BoundBox</code> controler, which needs two Display Objects
		 * to satisfy functionality (bound & box), here named as <code>rail</code> and <code>train</code>.
		 * @param definition - xml definition @param xroot - reference to parent xRoot object
		 * @see axl.xdef.types.xScroll  @see axl.xdef.interfaces.ixDef#def  @see axl.xdef.interfaces.ixDef#xroot
		 * @see axl.xdef.XSupport#getReadyType2() */
		public function xScroll(def:XML,rootObj:xRoot)
		{
			makeBox();
			this.addEventListener(MouseEvent.MOUSE_WHEEL, wheelEvent);
			super(def,rootObj);
		}
		//----------------------- OVERRIDEN INTERFACE -------------------- //
		override protected function elementAddedHandler(e:Event):void
		{
			super.elementAddedHandler(e);
			var d:DisplayObject = e.target as DisplayObject;
			var n:String = d.name.toLowerCase();
			if(n.match(/rail/i)) rail = d;
			else if(n.match(/train/i))	train = d;
			else if(n.match(/(up|left)/i))	btnDecrease = d as xButton;
			else if(n.match(/(down|right)/i)) btnIncrease = d as xButton;
		}
		//----------------------- OVERRIDEN INTERFACE -------------------- //
		//-----------------------  INTERNAL -------------------- //
		private function makeBox():void
		{
			ctrl = new BoundBox();
			ctrl.bound = rail;
			ctrl.box = train;
			ctrl.liveChanges = true;
			ctrl.horizontalBehavior = BoundBox.inscribed;
			ctrl.verticalBehavior = BoundBox.inscribed;
		}
		
		private function onBtnIncrease(e:Event=null):void
		{
			if(controller.horizontal)
				ctrl.movementHor(deltaMultiplier,false,this);
			else if(controller.vertical)
				ctrl.movementVer(deltaMultiplier,false,this);
			this.xbtnIncrease.execute();
		}
		
		private function onBtnDecrease(e:Event=null):void
		{
			if(controller.horizontal)
				ctrl.movementHor(-deltaMultiplier,false,this);
			else if(controller.vertical)
				ctrl.movementVer(-deltaMultiplier,false,this);
			this.xbtnDecrease.execute();
		}
		
		/** Receives wheel events and passes delta * deltaMultipy values to controller. */
		protected function wheelEvent(e:MouseEvent):void
		{
			if(!wheelScrollAllowed || e.delta==0) 
				return;
			if(ctrl.vertical)
				ctrl.movementVer((e.delta * deltaMultiplier) * -1,false,ctrl);
			else if(ctrl.horizontal)
				ctrl.movementHor((e.delta * deltaMultiplier) * -1,false,ctrl);
		}
		
		//-----------------------  INTERNAL -------------------- //
		//-----------------------  PUBLIC API -------------------- //
		/** Defines area on which <code>train</code> can be moved. @see axl.ui.controllers.BoundBox#bound*/
		public function get rail():DisplayObject { return xrail }
		public function set rail(v:DisplayObject):void { xrail = ctrl.bound = v }
		
		/** Defines an element which can be dragged moved and scrolled within <code>rail</code> bounds.
		 *  @see axl.ui.controllers.BoundBox#box*/
		public function get train():DisplayObject { return xtrain }
		public function set train(v:DisplayObject):void { xtrain = ctrl.box = v }
		
		/** Moves horizontal scroll bar's train left and/or vertical scroll bar trains' up. */
		public function get btnDecrease():xButton { return xbtnDecrease }
		public function set btnDecrease(v:xButton):void
		{
			if(xbtnDecrease != null || xbtnDecrease != v)
				xbtnDecrease.externalExecution = null;
			xbtnDecrease = v;
			xbtnDecrease.externalExecution = onBtnDecrease;
		}
		
		/** Moves horizontal scroll bar's train right and/or vertical scroll bar trains' down. */
		public function get btnIncrease():xButton { return btnIncrease }
		public function set btnIncrease(v:xButton):void
		{
			if(xbtnIncrease != null || xbtnIncrease != v)
				xbtnIncrease.externalExecution = null;
			xbtnIncrease = v;
			xbtnIncrease.externalExecution = onBtnIncrease;
		}
		
		/** Returns controller @see axl.ui.controllers.BoundBox */
		public function get controller():BoundBox { return ctrl }
	}
}