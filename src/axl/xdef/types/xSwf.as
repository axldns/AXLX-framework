package axl.xdef.types
{
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.Event;
	
	import axl.utils.U;
	import axl.xdef.XSupport;

	public class xSwf extends xSprite
	{
		public var stopRemoved:Boolean = true;
		public var addStarts:Boolean=true;
		public var stopOnEnd:Boolean = false;
		public var startedFromFrame:int = 0;
		public var stoppedFromFrame:int = 0;
		public var reverse:Boolean;
		public var stopOnEndAfterXcycles:int;
		public var yoyo:Boolean;
		public var dir:int=1;
		
		private var frameListenerAdded:Boolean;
		private var movieClip:MovieClip;
		private var stopFuncArgs:Boolean;
		private var stopFunc:String;
		
		public function get mc():MovieClip { return movieClip }
		public function xSwf(definition:XML=null, xroot:xRoot=null)
		{
			super(definition, xroot);
		}
		
		protected function ats(event:Event):void
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
		
		protected function rfs(event:Event):void
		{
			mc.removeEventListener(Event.ENTER_FRAME, mcEnterFrame);
			frameListenerAdded = false
			if(stopRemoved)
				mc.stop();
		}
		
		public function addSwf(main:DisplayObject):void
		{
			if(mc != null)
			{
				mc.stop();
				frameListenerAdded = false;
				mc.removeEventListener(Event.ENTER_FRAME, mcEnterFrame);
				mc.removeEventListener(Event.ADDED_TO_STAGE, ats);
				mc.removeEventListener(Event.REMOVED_FROM_STAGE, rfs);
			}
			if(main is MovieClip)
			{
				frameListenerAdded=true;
				movieClip = main as MovieClip;
				mc.gotoAndStop(0);
				
				mc.addEventListener(Event.ADDED_TO_STAGE, ats);
				mc.addEventListener(Event.REMOVED_FROM_STAGE, rfs);
				this.addChild(movieClip);
			}
			else
				U.log("loaded swf is not MovieClip");
		}
		
		protected function mcEnterFrame(e:Event):void
		{
			var n:int;
			if(reverse)
			{
				n = mc.currentFrame-1;
				mc.gotoAndStop(n);
				if(n == 0)
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
				if(mc.currentFrame == mc.totalFrames)
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
		
		override public function set meta(v:Object):void
		{
			super.meta = v;
			if(meta == null)
				return;
			if(meta.hasOwnProperty('onStop') && meta.onStop.length > 0 && meta.onStop.charAt(0) == '$')
				stopFunc = meta.onStop.substr(1);
			if(meta.hasOwnProperty('onStopFuncArgs'))
				stopFuncArgs = true
		}
		
		private function stop():void
		{
			mc.stop();
			mc.removeEventListener(Event.ENTER_FRAME, mcEnterFrame);
			frameListenerAdded = false;
			if(stopFunc != null)
			{
				var f:Function = XSupport.simpleSourceFinder(this.xroot, stopFunc) as Function;
				if(f != null)
				{
					if(stopFuncArgs)
						f.apply(null, XSupport.getDynamicArgs(meta.onStopFuncArgs,this.xroot))
					else
						f();
				}
			}
		}
		public function gotoAnd(frame:int,command:String='play'):void
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
				stop();
			}
			
		}
		public function resume():void
		{
			mc.play();
			if(!frameListenerAdded)
				mc.addEventListener(Event.ENTER_FRAME, mcEnterFrame);
			
		}
		
	}
}