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
	import flash.utils.clearInterval;
	import flash.utils.clearTimeout;
	import flash.utils.getTimer;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	import axl.utils.U;
	import axl.xdef.XSupport;
	import axl.xdef.interfaces.ixDef;

	public class xTimer implements ixDef
	{
		private static var regexp:RegExp = /y+|w+|M+|d+|m+|h+|'.+?'|s+|S+|\s+|\W+/g;
		public var defaultFormat:String='hh : mm : ss';
		private var intervalID:uint = 0;
		private var intervalValue:uint;
		private var timeoutID:uint;
		private var xremaining:Number;
		private var tillChangePortions:Array;
		
		private var maxIndex:uint;
		private var xServerTime:Number=0;
		private var initTime:int;
		private var xTiming:Array;
		private var xTimeIndex:int=-2;
		
		public var onTimeIndexChange:Object;
		public var onComplete:Object;
		public var onUpdate:Object;
		private var root:xRoot;
		private var xdef:XML;
		private var xname:String;
		private var metaAlreadySet:Boolean;
		public var reparseMetaEverytime:Boolean;
		private var xmeta:Object;
		private var xxroot:xRoot;
		
		
		public static function xmlInstantiation(d:XML, r:xRoot):xTimer { return new xTimer(d,r) }
		public function xTimer(definition:XML,xroot:xRoot=null)
		{
			xxroot = xroot;
			xdef = definition;
			if(this.xroot != null && definition != null)
			{
				var v:String = String(definition.@name);
				if(v.charAt(0) == '$' )
					v = xroot.binCommand(v.substr(1), this);
				this.name = v;
				xroot.registry[this.name] = this;
			}
		}
		public function get xroot():xRoot { return xxroot }
		public function set xroot(v:xRoot):void	{ xxroot = v }
		
		
		public function get meta():Object { return xmeta }
		public function set meta(v:Object):void {
			if(v is String)
				throw new Error("Invalid json for element " +  def.localName() + ' ' +  def.@name );
			if((metaAlreadySet && !reparseMetaEverytime))
				return;
			xmeta =v;
			metaAlreadySet = true;
		}
		
		public function get name():String { return xname }
		public function set name(v:String):void { xname = v;}
		
		public function get def():XML { return xdef }
		public function set def(v:XML):void { xdef = v }
		
		public function reset():void {	XSupport.applyAttributes(def,this) }
		
		
		//---------------------------------------------- TIMEOUT SECTION -----------------------------------//
		/** Sets/gets sets server time in seconds.<ul><li> Setting serverTime saves value and starts counter</li>
		 * <li>Getting serveTime returns initial serverTime plus time since it was set</li></ul>
		 * @param v - number of seconds e.g utc timestamp @see #originalServerTime*/
		public function set serverTime(v:Number):void 
		{
			xTimeIndex = -2;
			clearTimeout(timeoutID);
			xServerTime = v;
			if(isNaN(xServerTime)) 
			{
				U.log("[xTimer]["+this.name+"][serverTime] serverTime CAN'T BE NaN");
				return;
			}
			initTime = getTimer();
			if(timing != null)
				findTimeIndex();
		}
		public function get serverTime():Number 
		{
			if(!isNaN(xServerTime))
				return xServerTime + Math.round((getTimer() - initTime)/1000);
			return null; 
		}
		
		/** Returns original server time assigned without time offset since passed. @see #serverTime*/
		public function get originalServerTime():Number { return xServerTime } 
		
		/** An Array of integers - numbers of seconds.<br><code>serverTime</code> is compared against these values
		 * to figure out <code>timeIndex</code>.<br>If timeIndex is lower than the timing array length, callback to next 
		 * period is set.<br>Everytime new timeIndex is set (after auto callback execution) two things happen:
		 * <ol>
		 * <li><b>onTimeIndexChange</b> is fired</li>
		 * <li>timer specific action is looked up in config. Timer specific action name is defined as name of this
		 * timer instance + timeIndex.</li></ol>
		 * <h3>Example</h3> <br><code>&lt;timer name="myTimer" serverTime='0' timing='[20,30,80,90,400]'&gt;</code><br>
		 * This will cause:<br>
		 * <ul>
		 * <li>After 20 seconds: timeIndex will change from -1 to 0, 
		 * <i>onTimeIndexChange</i> is fired, <code>executeFromXML("myTimer0")</code> is fired</li>
		 * <li>After another 10 seconds: timeIndex will change from 0 to 1, 
		 * <i>onTimeIndexChange</i> is fired, <code>executeFromXML("myTimer1")</code> is fired</li>
		 * <li>After another 50 seconds: timeIndex will change from 1 to 2, 
		 * <i>onTimeIndexChange</i> is fired, <code>executeFromXML("myTimer2")</code> is fired</li>
		 * <li>After 90 seconds since serverTime/timing was set: timeIndex will change from 2 to 3, 
		 * <i>onTimeIndexChange</i> is fired, <code>executeFromXML("myTimer3")</code> is fired</li>
		 * <li>After another 310 seconds: timeIndex will change from 3 to 4, 
		 * <i>onTimeIndexChange</i> is fired, <code>executeFromXML("myTimer4")</code> is fired, <b>onComplete</b> is fired</li>
		 * </ul> @see #timeIndex
		 *  */
		public function get timing():Array { return xTiming }
		public function set timing(v:Array):void
		{
			xTiming = v;
			xTimeIndex = -2;
			clearTimeout(timeoutID);
			if(!xTiming)
				return;
			findTimeIndex();
		}
		
		/** Returns current period id figured out based on comparison of <i>serverTime</i> against <i>timing</i> array.<br>
		 * Returns <ul>
		 * <li><b>-2</b> if timing or serverTime is not set</li>
		 * <li><b>-1</b> if serverTime value is less than first value in timing array</li>
		 * <li>other int equal to index of last value in timing array which is smaller than <i>serverTime</i></li>
		 * @see #timing */
		public function get timeIndex():int { return xTimeIndex }
		
		private function findTimeIndex():void
		{
			if(isNaN(serverTime) || !timing)
				return;
			maxIndex = timing.length-1;
			if(maxIndex < 0)
				return;
			var newTimeIndex:int = -1;
			var server:Number = serverTime;
			U.log("[xTimer]["+this.name+"][findTimeIndex] serverTime:", server, 'current time index', timeIndex,"max time index", maxIndex);			
			for(var i:int = 0; i <= maxIndex; i++)
			{
				U.log(server, '>', timing[i], (server > timing[i]))
				if(!(server > timing[i]))
					break;
			}
			newTimeIndex = i-1;
			if(newTimeIndex == timeIndex)
			{
				U.log("[xTimer]["+this.name+"][findTimeIndex][NO TIME INDEX CHANGE]", newTimeIndex, timeIndex);
				return;
			}
			else
			{
				U.log("[xTimer]["+this.name+"][findTimeIndex][NEW TIME INDEX]:", newTimeIndex, 'from (', timeIndex,') serverTime:', server);
			}
			xTimeIndex = newTimeIndex;
			executeOnTimeIndexChange();
			setUpNextCallback();
		}		
		
		private function setUpNextCallback():void
		{
			if(timeIndex < maxIndex)
			{
				var secondsTillNextPeriod:Number = ((xTiming[timeIndex + 1] - serverTime) + 1);
				var tillChangeMs:Number = secondsTillNextPeriod*1000;
				var parcel:Number = int.MAX_VALUE;
				tillChangePortions=[];
				
				while(tillChangeMs > parcel)
				{
					tillChangeMs -= parcel;
					tillChangePortions.push(parcel);
				}
				
				U.log("[xTimer]["+this.name+"][setUpNextCallback] time Index:", timeIndex, 
					'NEXT CHANGE TIME', xTiming[timeIndex + 1], 'which is in', secondsTillNextPeriod,
					'seconds', "(packed in groups of", this.tillChangePortions.length +1,')');
				timeoutID = setTimeout(nextTimeParcel, tillChangeMs);
			}
			else
			{
				executeTimerComplete();
			}
		}
		
		private function nextTimeParcel():void
		{
			if(!tillChangePortions || tillChangePortions.length <1)
				findTimeIndex();
			else
			{
				var nextMs:Number = tillChangePortions.pop();
				timeoutID = setTimeout(nextTimeParcel, nextMs);
			}
		}		
		
		private function executeOnTimeIndexChange():void
		{
			if(onTimeIndexChange != null)
			{
				if(onTimeIndexChange is Function)
					onTimeIndexChange(timeIndex);
				else			
					xroot.binCommand(onTimeIndexChange,this)
			}
			xroot.executeFromXML(name + String(timeIndex));
		}
		
		private function executeTimerComplete():void
		{
			U.log("[xTimer]["+this.name+"][COMPLETE]");
			if(intervalID)
				clearInterval(intervalID);
			if(onComplete != null)
			{
				if(onComplete is Function)
					onComplete();
				else			
					xroot.binCommand(onComplete,this)
			}
		}
		//---------------------------------------------- TIMEOUT SECTION -----------------------------------//
		//---------------------------------------------- INTERVAL SECTION -----------------------------------//
		
		/** Sets/gets frequency of executing <code>onUpdate</code> function if <code>timing</code> array is set.<br>
		 * Can't be greater then approx 24 days (int.MAX_VALUE/1000 seconds).
		 * @param v number of seconds
		 * @see #onUpdate() */
		public function get interval():Number { return intervalValue}
		public function set interval(v:Number):void
		{
			U.log("[xTimer]["+this.name+"][interval]", v);
			if(intervalID)
				clearInterval(intervalID);
			intervalID = 0;
			var ms:Number = v * 1000;
			if(ms > int.MAX_VALUE)
			{
				U.log("[xTimer]["+this.name+"][interval][MAX exceeded]" + int.MAX_VALUE/1000);
				return;
			}
			intervalID = setInterval(executeOnIntervalUpdate, ms);
		}
		
		private function executeOnIntervalUpdate():void
		{
			updateRemaining();
			if(onUpdate != null)
			{
				if(onUpdate is Function)
					onUpdate();
				else			
					xroot.binCommand(onUpdate,this)
			}
		}
		
		private function updateRemaining():void
		{
			xremaining = serverTime;
		}
		
		//---------------------------------------------- INTERVAL SECTION -----------------------------------//
		//---------------------------------------------- API SECTION -----------------------------------//
		
		public function millisecondsTillNext(nextSybiling:String='s',mod:int=1,leadingZeros:int=0):String
		{
			var stn:Number = getOffset(mod)*1000, out:String;
			switch(nextSybiling) {
				case "s": stn = stn % 1000; break;
				case "m": stn = stn % 60000; break;
				case "h": stn = stn % 3600000; break; // 60 * 60
				case "d": stn = stn % 86400000; break; // 60 * 60 * 24
				case "w": stn = stn % 604800000; break;// 60 * 60 * 24 * 7
				case "M": stn = stn % (365.25/12 * 86400000); break;
				case "y": stn = stn % (365.25 * 86400000); break;
			}
			out = String(leadingZeros < 0 ? stn : Math.floor(stn));
			while(out.length < leadingZeros)
				out = '0' + out;
			return out;
		}
		
		public function secondsTillNext(nextSybiling:String='m',mod:int=1,leadingZeros:int=0):String
		{
			var stn:Number = getOffset(mod), out:String;
			switch(nextSybiling) {
				case "m": stn = stn % 60; break;
				case "h": stn = stn % 3600; break; // 60 * 60
				case "d": stn = stn % 86400; break; // 60 * 60 * 24
				case "w": stn = stn % 604800; break;// 60 * 60 * 24 * 7
				case "M": stn = stn % (365.25/12 * 86400); break;
				case "y": stn = stn % (365.25 * 86400); break;
			}
			out = String(leadingZeros < 0 ? stn : Math.floor(stn));
			while(out.length < leadingZeros)
				out = '0' + out;
			return out;
		}
		
		public function minutesTillNext(nextSybiling:String='h',mod:int=1,leadingZeros:int=0):String
		{
			var stn:Number = getOffset(mod) / 60, out:String;
			switch(nextSybiling) {
				case "h": stn = stn % 60; break;
				case "d": stn = stn % 1440; break; // 60 * 24
				case "w": stn = stn % 10080; break; // 60 * 24 * 7
				case "M": stn = stn % (365.25/12 * 1440); break;
				case "y": stn = stn % (365.25 * 1440); break;
			}
			out = String(leadingZeros < 0 ? stn : Math.floor(stn));
			while(out.length < leadingZeros)
				out = '0' + out;
			return out;
		}
		
		public function hoursTillNext(nextSybiling:String='d',mod:int=1,leadingZeros:int=0):String
		{
			var stn:Number = getOffset(mod) / 3600, out:String;
			switch(nextSybiling) {
				case "d": stn = stn % 24; break; 
				case "w": stn = stn % 168; break; // 24 * 7
				case "M": stn = stn % (365.25/12 * 24); break;
				case "y": stn = stn % (365.25 * 24); break;
			}
			out = String(leadingZeros < 0 ? stn : Math.floor(stn));
			while(out.length < leadingZeros)
				out = '0' + out;
			return out;
		}
		
		public function daysTillNext(nextSybiling:String='w',mod:int=1,leadingZeros:int=0):String
		{
			var stn:Number = getOffset(mod) / 86400, out:String;
			switch(nextSybiling) {
				case "w": stn = stn % 7; break; 
				case "M": stn = stn % (365.25/12); break;
				case "y": stn = stn % (365.25); break;
			}
			out = String(leadingZeros < 0 ? stn : Math.floor(stn));
			while(out.length < leadingZeros)
				out = '0' + out;
			return out;
		}
		
		public function weeksTillNext(nextSybiling:String='M',mod:int=1,leadingZeros:int=0):String
		{
			var stn:Number = getOffset(mod) / 604800, out:String;
			switch(nextSybiling) {
				case "M": stn = stn % (4.34524); break;
				case "y": stn = stn % (52.1429); break;
			}
			out = String(leadingZeros < 0 ? stn : Math.floor(stn));
			while(out.length < leadingZeros)
				out = '0' + out;
			return out;
		}
		
		public function monthsTillNext(nextSybiling:String='y',mod:int=1,leadingZeros:int=0):String
		{
			var stn:Number = getOffset(mod) / (365.25/12 * 86400), out:String;
			switch(nextSybiling) {
				case "y": stn = stn % (12); break;
			}
			out = String(leadingZeros < 0 ? stn : Math.floor(stn));
			while(out.length < leadingZeros)
				out = '0' + out;
			return out;
		}
		
		public function yearsTillNext(nextSybiling:String=null,mod:int=1,leadingZeros:int=0):String
		{
			var stn:Number = getOffset(mod) / (365.25 * 86400),out:String;
			out = String(leadingZeros < 0 ? stn : Math.floor(stn));
			while(out.length < leadingZeros)
				out = '0' + out;
			return out;
		}
				
		private function getOffset(mod:int):Number 
		{
			if(mod < 0)
				mod += timing.length;
			else
				mod += timeIndex;
			if(mod < 0 || mod > maxIndex)
				return -1;
			return timing[mod] -xremaining;
		}
		
		public function tillNextBit(scale:String,nextSybiling:String=null,mod:int=1,leadingZeros:int=0):String
		{
			switch(scale)
			{
				case "y": return yearsTillNext(nextSybiling,mod,leadingZeros);
				case "M": return monthsTillNext(nextSybiling,mod,leadingZeros);
				case "w": return weeksTillNext(nextSybiling,mod,leadingZeros);
				case "d": return daysTillNext(nextSybiling,mod,leadingZeros);
				case "h": return hoursTillNext(nextSybiling,mod,leadingZeros);
				case "m": return minutesTillNext(nextSybiling,mod,leadingZeros);
				case "s": return secondsTillNext(nextSybiling,mod,leadingZeros);
				case "S": return millisecondsTillNext(nextSybiling,mod,leadingZeros);
				default: return null;
			}
		}
		
		public function tillNext(v:String=null,mod:int=1):String
		{
			updateRemaining();
			v = v || defaultFormat;
			var a:Array = v.match(regexp), out:String='';
			var bm:Object={};
			for(var i:int =0,j:int = a.length,s:String,l:int; i<j;i++)
				bm[a[i].charAt(0)]= true;
			for(i =0;i<j;i++)
			{
				s=a[i].charAt(0);
				l =a[i].length;
				switch(s)
				{
					case "'": out += a[i].replace(/'/g, ""); break;
					case "y": out += yearsTillNext(null,mod,l); break;
					case "M": out += monthsTillNext(bm.y?'y':null,mod,l); break;
					case "w": out += weeksTillNext(bm.M?'M':(bm.y?'y':null),mod,l); break;
					case "d": out += daysTillNext(bm.w?'w':(bm.m?'M':(bm.y?'y':null)),mod,l); break;
					case "h": out += hoursTillNext(bm.d?'d':(bm.w?'w':(bm.m?'M':(bm.y?'y':null))),mod,l); break;
					case "m": out += minutesTillNext(bm.h?'h':(bm.d?'d':(bm.w?'w':(bm.m?'M':(bm.y?'y':null)))),mod,l); break;
					case "s": out += secondsTillNext(bm.m?'m':(bm.h?'h':(bm.d?'d':(bm.w?'w':(bm.m?'M':(bm.y?'y':null))))),mod,l); break;
					case "S": out += millisecondsTillNext(bm.s?'s':(bm.m?'m':(bm.h?'h':(bm.d?'d':(bm.w?'w':(bm.m?'M':(bm.y?'y':null)))))),mod,l); break;
					default: out +=a[i];
				}
			}
			return out;
		}
	}
}