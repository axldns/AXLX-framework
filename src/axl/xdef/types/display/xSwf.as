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
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	
	import axl.utils.U;
	/** Class is container for loaded swf files providing API for controling timeline animations.
	 * Instantiated from: <h3><code>&lt;swf/&gt;</code></h3>
	 * General convention that loaded swf has to follow in order for playback API to work is to keep entire
	 * animation in MainTimeline rather than inside inner MovieClip objects. Different approach may involve
	 * accessing MovieClip itself and calling it's inner API code-wise. @see #mc */
	public class xSwf extends xSprite
	{
		private var frameListenerAdded:Boolean;
		private var movieClip:MovieClip;
		
		/** Determines if <code>MainTimeline.stop()</code> should be called as soon as object is removed from 
		 * stage @default true*/
		public var stopRemoved:Boolean = true;
		/** Determines if swf object added to display should start playing (from <code>startedFromFrame</code>)
		 * or go to <code>stoppedFromFrame</code> and stop @default true @see #startedFromFrame @see #stoppedFromFrame */
		public var addStarts:Boolean=true;
		/** Determines if <code>stop()</code> should be called on swf when it reaches end value. End value
		 * varies and depends on different settings: <ul><li>played normally reaches max number of frames or reaches frame <code>
		 * stopOnFrame</code></li><li>played on reverse and reaches frame 1 or reaches frame <code>stopOnFrame</code></li></ul>
		 * If set to <code>false</code> but <code>stopOnFrame</code> is greater than zero, stop will also be called with
		 * under tha same conditons as above. @see #stopOnFrame @default false*/
		public var stopOnEnd:Boolean = false;
		/** When added to stage, etermines from which frame swf should start playing if 
		 * <code>addStarts=true</code>. @default 0 @see #addStarts @see #stoppedFromFrame*/
		public var startedFromFrame:int = 0;
		/** When added to stage, determines to which frame swf should go and stop if 
		 * <code>addStarts=false</code>. @default 0 @see #addStarts @see #startedFromFrame */
		public var stoppedFromFrame:int = 0;
		/** In typical scenario determines on which frame swf should be stopped, but may depend on  other settings:<br>
		 * <code>stopOnEnd=true</code> - stops playback promptly exactly on the frame number assigned to this property,
		 * <br><code>stopOnEnd=false</code> - depends on <code>stopOnEndAfterXcycles</code>.
		 * <br><code>stopOnEndAfterXcycles&gt;0</code> - stopOnFrame determines "last frame of single cycle", after x cycles
		 * MovieClip is stopped on either frame 1 or total number of frames.
		 * <br><code>stopOnEndAfterXcycles</code> is not set - loops.
		 * <br> This property does not apply if <code>yoyo=true</code> #default-1 @see #stopOnEnd @see #stopOnEndAfterXcycles*/
		public var stopOnFrame:int = -1;
		/** Allows to play MovieClip in reverse */
		public var reverse:Boolean;
		/** Determines how many time swf should reach it's end value before it stops. End value can be
		 * max number of frames, or frame 1 (yoyo, reverse). To make this property working <code>stopOnEnd</code> 
		 * must be set to false. @see #stopOnEnd */
		public var stopOnEndAfterXcycles:int;
		/** Swf can be played forth and back. To stop yoyo after certain amount of cycles, set stopOnEnd to false
		 * and set <code>stopOnEndAfterXcycles</code>. Two cycles is full forth and back. */
		public var yoyo:Boolean;
		/** Yoyo defined animations can go forth and back (<code>dir=1</code>) or back and forth (<code>dir=-1</code>).<br>
		 * Specifing number greater than 1 will cause jumping e.g. two frames at the time.*/
		public var dir:int=1;
		/** Function or portion of uncompiled code to execute when swf playback is topped. An argument for binCommand.
		 * @see axl.xdef.types.xRoot#binCommand() */
		public var onStop:Object;
		
		/** Class is container for loaded swf files providing API for controling timeline animations.
		 * Instantiated from &lt;swf/&gt; Loaded swf object can be accessed via <code>mc</code> property.
		 * @param definition - xml definition
		 * @param xroot - reference to parent xRoot object
		 * @see #mc
		 * @see axl.xdef.types.xSwf
		 * @see axl.xdef.interfaces.ixDef#def
		 * @see axl.xdef.interfaces.ixDef#xroot
		 * @see axl.xdef.XSupport#getReadyType2()  */
		public function xSwf(definition:XML=null, xroot:xRoot=null)
		{
			super(definition, xroot);
		}
		
		//----------------------- OVERRIDEN METHODS  -------------------- //
		override public function addChild(child:DisplayObject):DisplayObject
		{
			return addSwf(child);
		}
		
		override public function addChildAt(child:DisplayObject, index:int):DisplayObject
		{
			return addSwf(child);
		}
		//----------------------- OVERRIDEN METHODS  -------------------- //
		//----------------------- SWF RELATED EVENTS  -------------------- //
		protected function movieClipAddedToStageHandler(event:Event):void
		{
			if(addStarts)
			{
				mc.addEventListener(Event.ENTER_FRAME, mcEnterFrame);
				frameListenerAdded = true;
				mc.gotoAndPlay(startedFromFrame);
			}
			else
				mc.gotoAndStop(stoppedFromFrame);
		}
		
		protected function movieClipRemovedFromStageHandler(event:Event):void
		{
			mc.removeEventListener(Event.ENTER_FRAME, mcEnterFrame);
			frameListenerAdded = false
			if(stopRemoved)
				mc.stop();
		}
		
		protected function mcEnterFrame(e:Event):void
		{
			resolveContinuation();
		}
		//----------------------- SWF RELATED EVENTS  -------------------- //
		//----------------------- INTERNAL MECHANIC  -------------------- //
		private function resolveContinuation():void
		{
			var n:int;
			if(reverse)
			{
				n = mc.currentFrame-1;
				mc.gotoAndStop(n);
				if(n == 0 || mc.currentFrame == stopOnFrame)
				{
					if(stopOnEnd)
						stop();
					else
					{
						if(--stopOnEndAfterXcycles == 0)
							stop();
						else
							mc.gotoAndStop(mc.totalFrames);
					}
				}
			}
			else if(yoyo)
			{
				n= mc.currentFrame+dir;
				var halfed:Boolean = (dir > 0) ? (mc.currentFrame == mc.totalFrames) : (n==0);
				mc.gotoAndStop(n);
				if(halfed)
				{
					if(--stopOnEndAfterXcycles == 0)
						stop();
					else
						dir *= -1;
				}
			}
			else
			{
				if(mc.currentFrame == mc.totalFrames || mc.currentFrame == stopOnFrame)
				{
					if(stopOnEnd)
						stop();
					else
					{
						if(--stopOnEndAfterXcycles == 0)
							stop();
						else
							mc.gotoAndPlay(0);
					}
				}
			}
		}
		
		private function addSwf(main:DisplayObject,parent:DisplayObject=null):*
		{
			if(mc != null)
			{
				mc.stop();
				frameListenerAdded = false;
				mc.removeEventListener(Event.ENTER_FRAME, mcEnterFrame);
				mc.removeEventListener(Event.ADDED_TO_STAGE, movieClipAddedToStageHandler);
				mc.removeEventListener(Event.REMOVED_FROM_STAGE, movieClipRemovedFromStageHandler);
			}
			if(main is MovieClip)
			{
				frameListenerAdded=true;
				movieClip = main as MovieClip;
				mc.gotoAndStop(0);
				
				mc.addEventListener(Event.ADDED_TO_STAGE, movieClipAddedToStageHandler);
				mc.addEventListener(Event.REMOVED_FROM_STAGE, movieClipRemovedFromStageHandler);
				super.addChild(parent || main);
			}
			else if(main is DisplayObjectContainer)
			{
				for(var i:int = 0, j:int = main['numChildren']; i < j; i++)
					if(main['getChildAt'](i) is MovieClip)
						addSwf(main['getChildAt'](i), main);
			}
			else
				if(debug) U.log("loaded swf is not MovieClip");
			return mc;
		}
		//----------------------- INTERNAL MECHANIC  -------------------- //
		//-----------------------PUBLIC API FUNCTIONS  -------------------- //
		/** Stops swf playback immediately @param executeOnStop - controlls <code>onStop</code> 
		 * callback execution */		
		public function stop(executeOnStop:Boolean=true):void
		{
			mc.stop();
			mc.removeEventListener(Event.ENTER_FRAME, mcEnterFrame);
			frameListenerAdded = false;
			if(executeOnStop && onStop != null)
			{
				if(onStop is String)
					xroot.binCommand(onStop,this);
				else if(onStop is Function)
					onStop();
			}
		}
		
		/** Calls gotoAndPlay or gotoAndStop on movie clip. Allows to controll calling <code>onStop</code> callback
		 * @param frame - frame to go to @param command - either "play" or anyhing else (interpretated as stop)
		 * @param executeOnStop - determines if callback <code>onStop</code> should be executed. */
		public function gotoAnd(frame:int,command:String='play',executeOnStop:Boolean=false):void
		{
			if(command == 'play')
			{
				mc.gotoAndPlay(frame);
				if(!frameListenerAdded)
					mc.addEventListener(Event.ENTER_FRAME, mcEnterFrame);
			}
			else
			{
				mc.gotoAndStop(frame);
				stop(executeOnStop);
			}	
		}
		
		/** Resumes stopped/paused movie clip */
		public function resume():void
		{
			mc.play();
			if(!frameListenerAdded)
				mc.addEventListener(Event.ENTER_FRAME, mcEnterFrame);
		}
		
		/** Returns top first MovieClip object found in loaded swf. This element is the subject of all playback 
		 * properties of this class. Accessing this object properties may allow you to access it's code base 
		 * and controll it's playback on your own. */
		public function get mc():MovieClip { return movieClip }
	}
}