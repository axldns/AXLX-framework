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
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.geom.ColorTransform;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.utils.clearInterval;
	import flash.utils.clearTimeout;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	import axl.utils.ConnectPHP;
	import axl.utils.U;
	import axl.xdef.XSupport;
	
	
	public class xButton extends xSprite
	{
		public static var defaultOver:String="upstate.alpha:[1,1]";
		public static var defaultDisabled:String="alpha:[0.66,1]";
		
		private var isEnabled:Boolean=true;
		private var texture:DisplayObject;
		
		public var intervalValue:int=0;
		public var intervalDelay:int = 0;
		public var intervalHoverValue:int=0;
		public var executeReleasedOutside:Boolean;
		
		private var userClickHandler:Function;
		private var eventClick:Event = new Event("clickButton",true);
		private var isRotated:Boolean;
		
		private var trigerUrl:URLRequest;
		private var trigerEvent:Event;
		private var trigerExt:Array;
		private var trigerUrlWindow:String;
		private var isDown:Boolean;
		private var delayID:uint;
		private var intervalID:uint;
		private var intervalHoverID:uint;
		
		private var actions:Vector.<xAction> = new Vector.<xAction>();
		private var actionsOver:Vector.<xAction> = new Vector.<xAction>();
		private var actionsOut:Vector.<xAction> = new Vector.<xAction>();
		
		private var overTarget:Object;
		private var overKey:String;
		private var overVals:Object;
		
		private var disabledKey:String;
		private var disabledTarget:Object;
		private var disabledVals:Object;
		
		private var sdisabled:String;
		private var sover:String; 
		
		private var postSendArgs:Array;
		private var postObject:ConnectPHP;
		private var dynamicArgs:Boolean;
		private var actionOver:Boolean;
		private var isOver:Boolean;
		
		public var stateOver:DisplayObject;
		public var stateOut:DisplayObject;
		public var stateDisabled:DisplayObject;
		public var stateDown:DisplayObject;
		public var code:String;
		public var externalExecution:Boolean;
		
		
		private var currentState:int=0;
		private var styleName:String;
		private var actionOut:Boolean;
		
		public function xButton(definition:XML=null,xroot:xRoot=null)
		{
			super(definition,xroot);
			enabled = isEnabled;
		}
		
		override public function addChild(child:DisplayObject):DisplayObject
		{
			if(numChildren < 1)
				texture = child;
			if(child.name.match(/out/i))
			{
				if(stateOut && contains(stateOut))
					removeChild(stateOut);
				stateOut = child;
				if(currentState != 0)
					return child;
			}
			if(child.name.match(/over/i))
			{
				if(stateOver && contains(stateOver))
					removeChild(stateOver);
				stateOver = child;
				if(currentState != 1)
					return child;
			}
			if(child.name.match(/down/i))
			{
				if(stateDown && contains(stateDown))
					removeChild(stateDown);
				stateDown = child;
				if(currentState != 2)
					return child;
			}
			if(child.name.match(/disabled/i))
			{
				if(stateDisabled && contains(stateDisabled))
					removeChild(stateDisabled);
				stateDisabled = child;
				if(currentState != 3)
					return child;
			}
			return super.addChild(child);
		}
		//-- internal
		override public function set meta(v:Object):void
		{
			super.meta = v;
			var a:Object, b:Array, i:int, j:int;
			if(meta is String)
				return
			if(meta.hasOwnProperty('url'))
			{
				if(meta.url is Array)
				{
					trigerUrl =  new URLRequest(meta.url[0]);
					trigerUrlWindow = meta.url[1];
				}
				else
					trigerUrl = new URLRequest(meta.url);
			}
			if(meta.hasOwnProperty('event'))
				trigerEvent  = new Event(meta.event,true);
			if(meta.hasOwnProperty('js'))
				trigerExt = meta.js;
			if(meta.hasOwnProperty('action'))
			{
				a = meta.action;
				b = (a is Array) ? a as Array : [a];
				for(i = 0, j = b.length; i<j; i++)
					actions[i] = new xAction(b[i],xroot,this);
			}
			if(meta.hasOwnProperty('actionOver'))
			{
				actionOver = true;
				a = meta.actionOver;
				b = (a is Array) ? a as Array : [a];
				for(i = 0, j = b.length; i<j; i++)
					actionsOver[i] = new xAction(b[i],xroot,this);
			}
			if(meta.hasOwnProperty('actionOut'))
			{
				actionOut = true;
				a = meta.actionOut;
				b = (a is Array) ? a as Array : [a];
				for(i = 0, j = b.length; i<j; i++)
					actionsOut[i] = new xAction(b[i],xroot,this);
			}
			if(meta.hasOwnProperty('post'))
			{
				if(meta.post.hasOwnProperty('dynamicArgs'))
				{
					postSendArgs // will be asigned right before execution
					dynamicArgs = true;
				}
				else
					postSendArgs = meta.post.sendArgs;
				postObject = new ConnectPHP();
				U.asignProperties(postObject, meta.post.connectProperties);
			}
		}
		
		private function checkProperties():void
		{
			if(overTarget == null)
				over = defaultOver;
			if(disabledTarget ==null)
				disabled = defaultDisabled;
		}
		
		//--click mechanic
		protected function mouseDown(e:MouseEvent):void
		{
			isDown = true;
			swapStates(2);
			U.STG.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			U.STG.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
			if(intervalValue > 0)
				delayID = setTimeout(repeatEvent, intervalDelay);
			
			function repeatEvent():void
			{
				if(isDown)
					intervalID = setInterval(mouseClick, intervalValue,e);
				else
					clearIntervals();
			}
		}
		
		protected function mouseClick(e:MouseEvent):void
		{
			this.dispatchEvent(eventClick);
			if(userClickHandler != null) 
			{
				if(userClickHandler.length > 0)
					userClickHandler(e);
				else
					userClickHandler();
			}
			if(!externalExecution)
				execute(e);
		}
		
		public function execute(e:MouseEvent=null):void
		{
			if(trigerUrl)
				navigateToURL(trigerUrl, trigerUrlWindow);
			if(trigerEvent != null)
				this.dispatchEvent(this.trigerEvent);
			if(this.trigerExt && ExternalInterface.available)
				ExternalInterface.call.apply(null, trigerExt);
			if(this.postObject != null)
			{
				if(dynamicArgs)
					this.postObject.sendData.apply(null, XSupport.getDynamicArgs(meta.post.sendArgs, this.xroot,this) as Array);
				else
					this.postObject.sendData.apply(null, this.postSendArgs);
			}
			for(var i:int = 0, j:int = actions.length; i<j; i++)
				actions[i].execute();
			if(code!=null)
				xroot.binCommand(code,this);
			if(debug) U.log(this, this.name, '[executed]', j, 'actions');
		}
		
		protected function hover(e:MouseEvent=null):void
		{
			if(!isEnabled)
				return;
			checkProperties();
			
			isOver = (e.type == MouseEvent.ROLL_OVER);
			
			var val:int =  isOver ? 0 : 1;
			
			if(overTarget)
			{
				if(overTarget[overKey] is Function)
					overTarget[overKey].apply(null, overVals[val]);
				else
					overTarget[overKey] = overVals[val];
			}
			if(!isDown)
				swapStates(isOver ? 1 : 0);
			
			executeHover();
			if(isOver && (intervalHoverValue > 0) && intervalHoverID < 1)
				intervalHoverID = setInterval(repeatHoverActions, intervalHoverValue,e);
			
			function repeatHoverActions():void { (isOver) ?  executeHover() : clearHoverInterval(); }
			function executeHover():void
			{
				if(isOver && actionOver)
				{
					for(var i:int = 0, j:int = actionsOver.length; i<j; i++)
						actionsOver[i].execute();
				}
				else
					clearHoverInterval();
				
				if(!isOver && actionOut)
				{
					for(var k:int = 0,l:int = actionsOver.length; k<l; k++)
						actionsOut[k].execute();
				}
			}
			function clearHoverInterval():void
			{
				flash.utils.clearInterval(intervalHoverID);
				intervalHoverID = 0;
			}
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
		// --- --- PUBLIC API --- --- //
		public function setEnabled(v:Boolean):void { enabled =v }
		public function get enabled():Boolean {	return isEnabled }
		public function set enabled(v:Boolean):void
		{
			//if(isEnabled == v) return;
			isEnabled = v;
			checkProperties();
			swapStates(v ? (isDown ? 2 : 0) : 3);
			if(!isEnabled)
			{
				U.STG.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
				U.STG.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
				hover(new MouseEvent("rollout",false));
			}
				
			var f:String = isEnabled ? 'addEventListener' : 'removeEventListener';
			this[f](MouseEvent.MOUSE_DOWN, mouseDown);
			this[f](MouseEvent.CLICK, mouseClick);
			this[f](MouseEvent.ROLL_OVER, hover);
			this[f](MouseEvent.ROLL_OUT, hover);
			
			buttonMode = isEnabled;
			useHandCursor = isEnabled;
			disabledTarget[disabledKey] = this.disabledVals[isEnabled ? 1 : 0];
		}
		
		protected function mouseUp(e:MouseEvent):void { mouseMove(e) }
		protected function mouseMove(e:MouseEvent):void
		{
			if(isDown && !e.buttonDown)
				touchEnd(e);
		}
		
		private function touchEnd(e:MouseEvent):void
		{
			isDown = false;
			U.STG.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
			U.STG.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			clearIntervals();
			swapStates(0);
			if(e.target != this && executeReleasedOutside)
				mouseClick(e);
		}
		
		private function clearIntervals():void
		{
			flash.utils.clearInterval(intervalID);
			flash.utils.clearTimeout(delayID);
		}
		
		/** impulse over event*/
		public function get onClick():Function { return userClickHandler }
		public function set onClick(v:Function):void { userClickHandler = v	}
		
		public function get over():String { return sover }
		public function set over(v:String):void
		{
			sover = v;
			overKey = v.substring(0, v.lastIndexOf(':'));
			var val:String = v.substring(v.lastIndexOf(':')+1);
			
			var keys:Array = overKey.split('.');
			overKey = keys.pop();
			overTarget = this;
			while(keys.length)
				overTarget = overTarget[keys.shift()];
			overVals = JSON.parse(val);
		}
		public function get disabled():String { return sdisabled}
		public function set disabled(v:String):void
		{
			sdisabled = v;
			disabledKey = v.substring(0, v.lastIndexOf(':'));
			var val:String = v.substring(v.lastIndexOf(':')+1);
			
			var keys:Array = disabledKey.split('.');
			disabledKey = keys.pop();
			disabledTarget = this;
			while(keys.length)
				disabledTarget = disabledTarget[keys.shift()];
			disabledVals = JSON.parse(val);
		}
		
		public function get upstate():DisplayObject { return texture }
		public function set upstate(v:DisplayObject):void
		{
			if(texture != null && contains(texture) && texture != v)
				this.removeChild(texture);
			texture = v;
			if(upstate !=null)
				this.addChild(texture);
			rotated = rotated;
		}
		
		public function get rotated():Boolean { return isRotated }
		public function set rotated(v:Boolean):void
		{
			isRotated = v;
			if(!texture)
				return;
			if(isRotated)
			{
				texture.rotation = 180;
				texture.x = texture.width;
				texture.y = texture.height;
			}
			else
			{
				texture.rotation = 0;
				texture.x = 0;
				texture.y =0;
			}
		}
		
		public function ctransform(prop:String,val:Number):void {
			if(!xtrans)
				xtrans = new ColorTransform();
			xtrans[prop] = val;
			this.transform.colorTransform = xtrans;
		}
		public function set style(v:String):void
		{
			if(styleName && v == styleName)
				return;
			styleName = v;
			xroot.support.pushReadyTypes2(xroot.getAdditionDefByName(v),this,null,xroot);
		}
		
		public function get style():String { return styleName }
	}
}