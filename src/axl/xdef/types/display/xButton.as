/**
 *
 * AXLX Framework
 * Copyright 2014-2016 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package axl.xdef.types.display
{
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.geom.ColorTransform;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	import axl.utils.ConnectPHP;
	
	/** Typical interactive button class. Does not require adding any event listeners - all listeners are
	 * added internally - requires to define callback functions instead.<br>
	 * Allows to set of custom actions and states and common styling by providing just a textual reference.<br>
	 * Actions can be defined on click, on hover, on hover out, * on press, on release.<br> States: over, out, enabled, disabled.<br>
	 * Hover and press functions execution can be repeated in certain intervals just by defining number of miliseconds
	 * gap between execution. 
	 * @see #states 
	 * @see #execute() */
	public class xButton extends xSprite
	{
		private var isEnabled:Boolean=true;
		private var isDown:Boolean;
		private var isOver:Boolean;
		private var currentState:int=0;
		
		private var downIntervalID:uint;
		private var intervalHoverID:uint;
		
		private var postObject:ConnectPHP;
		private var URLReq:URLRequest;
		private var styleName:String;
		
		/** Allows to define display object which will be added to buttons display list at index 0 
		 * when mouse pointer rolls over the button. This property can be set automatically by adding to buttons display list
		 * an element which name matches /over/i RegExp. @see #states */
		public var stateOver:DisplayObject;
		/** Allows to define display object which will be added to buttons display list at index 0 
		 * when mouse pointer is NOT over the button. This property can be set automatically by adding to buttons display list
		 * an element which name matches /out/i RegExp. @see #states */
		public var stateOut:DisplayObject;
		/** Allows to define display object which will be added to buttons display list at index 0 
		 * when <code>enabled</code> is set to false. This property can be set automatically by adding to buttons display list
		 * an element which name matches /disabled/i RegExp. @see #states */
		public var stateDisabled:DisplayObject;
		/** Allows to define display object which will be added to buttons display list at index 0 
		 * when mouse pointer is over the button and button is pressed down. This property can be set automatically by adding to buttons display list
		 * an element which name matches /down/i RegExp. @see #states */
		public var stateDown:DisplayObject;
		/** Action defined in <code>onDown</code> property can be repeated multiple times (till release, till setting disabled). This
		 * property defines how frequent (ms) action should be repeated. Values equal and less than 0 disable repetitions. */
		public var intervalDown:int=0;
		/** Action defined in <code>onHover</code> property can be repeated multiple times (till roll out, till setting disabled). This
		 * property defines how frequent (ms) action should be repeated. Values equal and less than 0 disable repetitions. */
		public var intervalHover:int=0;
		/** Determines if pressing button down, moving mouse/finger outside the button and releasing touch/press there should cause 
		 * main execution of the button too. This action wouldn't produce "mouseClick" event in this scenario. @default false @see #execute() */
		public var executeReleasedOutside:Boolean;
		/** If defined, default on click actions are not executed - externalExecution function is executed instead (default on click actions 
		 * can be executed "manually" by calling <code>execute</code> method. @see #execute() */
		public var externalExecution:Function;
		/** Portion of uncompiled code to execute/evaluate when button is clicked.
		 * @see #execute()
		 * @see axl.xdef.types.xRoot#binCommand() */
		public var code:String;
		/** Function or portion of uncompiled code to execute/evaluate when mouse pointer is over the button.
		 * @see axl.xdef.types.xRoot#binCommand() */
		public var onOver:Object;
		/** Function or portion of uncompiled code to execute/evaluate when mouse pointer rolls out of the button.
		 * @see axl.xdef.types.xRoot#binCommand() */
		public var onOut:Object;
		/** Function or portion of uncompiled code to execute/evaluate when mouse or touch presses the button.
		 * @see axl.xdef.types.xRoot#binCommand() */
		public var onDown:Object;
		/** Function or portion of uncompiled code to execute/evaluate when mouse or touch releases the button (after press).
		 * @see axl.xdef.types.xRoot#binCommand() */
		public var onRelease:Object;
		
		/** Typical interactive button class.
		 * @param definition - xml definition
		 * @param xroot - reference to parent xRoot object 
		 * @see axl.xdef.types.xButton */
		public function xButton(definition:XML=null,xroot:xRoot=null)
		{
			super(definition,xroot);
			enabled = isEnabled;
		}
		//---------------------------------------- OVERRIDEN METHODS -----------------------------------//
		override public function addChild(child:DisplayObject):DisplayObject
		{
			var c:DisplayObject = stateInspection(child);
			if(c) return c;
			return super.addChild(child);
		}
		
		override public function set meta(v:Object):void
		{
			super.meta = v;
			if(meta.hasOwnProperty('url'))
				URLReq = new URLRequest();
			if(meta.hasOwnProperty('post'))
				postObject = new ConnectPHP();
		}
		//---------------------------------------- OVERRIDEN METHODS -----------------------------------//
		//---------------------------------------- MOUSE EVENTS -----------------------------------//
		/** Common for ROLL_OVER and ROLL_OUT event handler. Returns if isEnabled = false, otherwise swaps states,
		 * executes onOver or onOut. Sets interval if <i>hoverInterval<i> &gt; 0 */
		protected function onMouseHover(e:MouseEvent=null):void
		{
			if(!isEnabled)
				return;
			isOver = (e.type == MouseEvent.ROLL_OVER);
			if(!isDown)
				swapStates(isOver ? 1 : 0);
			executeHover();
			if(isOver && (intervalHover > 0))
				intervalHoverID = setInterval(executeHover, intervalHover);
		}
		
		/** Returns if isEnabled = false, otherwise swaps states, adds move/up mouse event listeners (to stage),
		 *  executes onDown. Sets interval if <i>downInterval</i> &gt; 0  */
		protected function onMouseDown(e:MouseEvent):void
		{
			if(!isEnabled)
				return;
			isDown = true;
			swapStates(2);
			xroot.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			xroot.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			executeDown();
			if(intervalDown > 0)
				downIntervalID = setInterval(executeDown, intervalDown);
		}
		/** Validates if button is still down (as may be released outside). */
		protected function onMouseMove(e:MouseEvent):void
		{
			if(isDown && !e.buttonDown)
				touchEnd(e);
		}
		/** Swaps states, removes move/up listeners from stage, clears all intervals. If happend to be outside 
		 * button area - main execution won't be fired unless <i>executeReleasedOutside</i> is set to true. <i>onRelease</i>
		 * is fired anyway. */
		protected function onMouseUp(e:MouseEvent):void 
		{ 
			onMouseMove(e);
		}
		
		/** Calls main execute, unless <i>externalExecution</i> is set */
		protected function onMouseClick(e:MouseEvent):void
		{
			if(!externalExecution)
				execute(e);
		}
		//---------------------------------------- MOUSE EVENTS -----------------------------------//
		//---------------------------------------- MOUSE EVENTS SUPPORT -----------------------------------//
		private function touchEnd(e:MouseEvent):void
		{
			if(!isDown) return;
			isDown = false;
			xroot.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			xroot.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			clearDownInterval();
			swapStates(0);
			if(e.target != this && executeReleasedOutside)
				onMouseClick(e);
			lenientExec(onRelease);
		}
		
		private function executeHover():void
		{
			if(isOver)
				lenientExec(onOver);
			else
			{
				clearHoverInterval();
				lenientExec(onOut);
			}
		}
		private function executeDown():void
		{
			if(isDown)
				lenientExec(onDown);
			else
				clearDownInterval();
		}
		
		private function clearHoverInterval():void
		{
			clearInterval(intervalHoverID);
			intervalHoverID = 0;
		}
		
		private function clearDownInterval():void
		{
			clearInterval(downIntervalID);
			downIntervalID=0;
		}
		
		private function lenientExec(property:Object):void
		{
			if(property is String)
				xroot.binCommand(property,this);
			if(property is Function)
				property();
		}
		//---------------------------------------- MOUSE EVENTS SUPPORT -----------------------------------//
		//---------------------------------------- MAIN EXECUTION  -----------------------------------//
		/** Performs main execution (<code>code</code> attribute + meta keywords)  in pre-defined order.
		 * Typically called automatically on event of CLICK (not mouse down), but this can be dependent on few factors:
		 * <ul><li>If <code>externalExecution</code> is defined - execute won't be called on CLICK</li>
		 * <li>If <code>executeReleasedOutside = true</code> - execution will be called even though CLICK event isn't fired in this case.</li>
		 * </ul>
		 * For example <code>xForm</code> instances by default automatically detect <code>xButton</code> instances and "intercept" their functionalty by
		 * defining <i>externalExecution</i> where internal form validation is checked and <code>execute</code> is called only when passed.
		 * <h3>Execution order</h3>
		 * <ol>
		 * <li>meta.url - if defined, navigates to url. Can be URL string or an Array where first element is URL String, second "window type",eg. "_self"</li>
		 * <li>meta.js - if defined and available, performs ExternalInterface.call, where js should supply an Array of arguments for call function</li>
		 * <li>meta.post - if defined, used as an Array of arguments for <code>sendData</code> function from ConnectPHP class</li>
		 * <li>code - evaluates portion of uncompiled code assigned to it, String argument for <code>binCommand</code> function</li>
		 * </ol>*/
		public function execute(e:MouseEvent=null):void
		{
			if(meta != null)
			{
				executeNavigateToURL();
				executeJS();
				executePost();
			}
			if(code!=null)
				xroot.binCommand(code,this);
		}
		
		private function executePost():void
		{
			if(postObject != null)
			{
				if(meta.post is String && meta.post.charAt(0) == "$")
					postObject.sendData.apply(null, xroot.binCommand(meta.post.substr(1),this));
				else if(meta.post is Array)
					postObject.sendData.apply(null, meta.post);
				else throw new Error("Invalid meta.post on btn " + this.name + ". Must be an array or String reference to array.")
			}
		}
		
		private function executeJS():void
		{
			if(meta.js && ExternalInterface.available)
				ExternalInterface.call.apply(null, meta.js);
		}
		
		private function executeNavigateToURL():void
		{
			if(!meta.url)
				return;
			var url:String;
			var windw:String=null;
			if(meta.url is Array)
			{
				url = meta.url[0];
				windw = meta.url[1];
			}
			else
				url = meta.url;
			if(url.charAt(0) == "$")
				url= xroot.binCommand(meta.post.substr(1),this);
			navigateRequest.url = url;
			navigateToURL(navigateRequest,  windw);
		}
		//---------------------------------------- MAIN EXECUTION  -----------------------------------//
		//---------------------------------------- STATES MECHANIC  -----------------------------------//
		private function stateInspection(child:DisplayObject):DisplayObject
		{
			var cn:String = child.name;
			if(cn.match(/out/i))
			{
				if(stateOut && contains(stateOut))
					removeChild(stateOut);
				stateOut = child;
				if(currentState != 0)
					return child;
			}
			if(cn.match(/over/i))
			{
				if(stateOver && contains(stateOver))
					removeChild(stateOver);
				stateOver = child;
				if(currentState != 1)
					return child;
			}
			if(cn.match(/down/i))
			{
				if(stateDown && contains(stateDown))
					removeChild(stateDown);
				stateDown = child;
				if(currentState != 2)
					return child;
			}
			if(cn.match(/disabled/i))
			{
				if(stateDisabled && contains(stateDisabled))
					removeChild(stateDisabled);
				stateDisabled = child;
				if(currentState != 3)
					return child;
			}
			return null;
		}
		
		private function swapStates(state:int):void
		{
			if(state == currentState)
				return;
			currentState = state;
			var allstates:Array = [stateOut, stateOver, stateDown,stateDisabled];
			var add:DisplayObject = allstates.splice(state,1)[0] as DisplayObject;
			var rmv:DisplayObject;
			if(add == null)
				return;
			while(allstates.length)
			{
				rmv = allstates.pop() as DisplayObject;
				if(rmv && rmv.parent)
				{
					rmv.parent.removeChild(rmv);
				}
			}
			addChildAt(add,0);
		}
		
		private function setDisabled():void
		{
			listeners(false);
			xroot.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			xroot.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			swapStates(3);
		}
		
		private function setEnabled():void
		{
			swapStates(isDown ? 2 : (isOver ? 1 : 0));
			listeners(true);
		}
		
		private function listeners(add:Boolean):void
		{
			var f:String = add ? 'addEventListener' : 'removeEventListener';
			this[f](MouseEvent.MOUSE_DOWN, onMouseDown);
			this[f](MouseEvent.CLICK, onMouseClick);
			this[f](MouseEvent.ROLL_OVER, onMouseHover);
			this[f](MouseEvent.ROLL_OUT, onMouseHover);
		}
		//---------------------------------------- STATES MECHANIC  -----------------------------------//
		//---------------------------------------- PUBLIC API  -----------------------------------//
		/** Enables / disables button: makes it clickable/unclickable, swaps states. */
		public function get enabled():Boolean {	return isEnabled }
		public function set enabled(v:Boolean):void
		{
			//if(isEnabled == v) return;
			isEnabled = buttonMode = useHandCursor = v;
			isEnabled ? setEnabled() : setDisabled();
		}
		/** Allows to set ColorTransform instance properties and asign it to this object.
		 * @param prop - String (name of ColorTransform property) or object key-value style
		 * @param val - If properties is single property (string) - value for this property. If properties is key-val object,
		 * val is ignored. */
		public function ctransform(properties:Object,val:Number):void 
		{
			if(!xtrans)
				xtrans = new ColorTransform();
			if(properties is String)
				xtrans[properties] = val;
			else if(properties is Object)
				for(var s:String in properties)
					xtrans[s] = properties[s];
			this.transform.colorTransform = xtrans;
		}
		/** Allows to set displayable objects as button states (over, out, down, disabled).<br>
		 * Value for this property should match name of the element available within config's <i>additions</i> node.
		 * Element should contain one or more children with name(s) matching state's name(s) (<i>out,over,down,disabled</i>). 
		 * Children of it are instantiated and pushed to button's display list, where internal filter assigns these to particular button states. Assigning
		 * the same style name more than once does not cause multiple instantiation. Asigning diferent button style during runtime
		 * removes old states from buttons display list but does not dispose them. Only one state is displayed at the time.
		 * It is available to define some states while not defining others without quirky results.
		 * Asigning same style to different buttons does not cause "stealing" children.<br>Example style:<br>
		 * <code>&lt;div name='standardButton'&gt;<br>
		 *    &lt;img name='out' src='/assets/btnOut.png'&gt;<br>
		 *    &lt;img name='over' src='/assets/btnOver.png'&gt;<br>
		 * &lt;/div&gt;<br></code> */
		public function get states():String { return styleName }
		public function set states(v:String):void
		{
			if(styleName && v == styleName)
				return;
			styleName = v;
			xroot.support.pushReadyTypes2(xroot.getAdditionDefByName(v),this,null,xroot);
		}
		/** If meta.url was not specified - returns null. Otherwise returns instance of URLRequest which will be used to navigate to url. 
		 * Since meta object is dynamic variables container, URLRequest.url, propety is being re-read and re-asigned on execution (meta.url gets
		 * re-evaluated). @see #execute() */
		public function get navigateRequest():URLRequest { return URLReq }
		/** If meta.post was not set to this button - returns null. Otherwise returns an instance of <code>ConnectPHP</code> class
		 * which of method <code>sendData</code> will be used to make POST/GET request. meta.post provides arguments array for sendData.
		 * @see #execute() @see axl.utils.ConnectPHP#sendData() */
		public function get POSTGETObject():ConnectPHP { return postObject }

	}
}