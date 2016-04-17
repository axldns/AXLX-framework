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
	
	import axl.utils.AO;
	/** Extends xCarousel class by adding functionality of animated transitions from one 
	 * element to another and exposing "selected" element. 
	 * @see #poolMovement() 
	 * @see #currentChoice */
	public class xCarouselSelectable extends xCarousel
	{
		private var movementProps:Object;
		private var selectedObject:Object;
		private var movementPoint:Object = {x:0,y:0}
		/** Determines number of seconds in which carousel 
		 * transitions from one element to another @default 0.2 */
		public var movementSpeed:Number= .2;
		/** Function to execute when transition from one element to another is complete */
		public var onMovementComplete:Function;
		/** Determines easing that is used for carousel movement transitions 
		 * @see http://easings.net 
		 * @default "easeOutQuart" */
		public var easingType:String;
		/** @param definition - XML definition of this class (properties and children)
		 *  @param xroot - root object this instance will belong to
		 *  @see axl.xdef.types.xCarouselSelectable */
		public function xCarouselSelectable(definition:XML,xroot:xRoot=null)
		{
			super(definition,xroot);
			movementProps = {onUpdate : updateCarusele};
		}
		
		override protected function elementAdded(e:Event):void
		{
			super.elementAdded(e);
			selectedObject = getChildClosestToCenter()[0];
		}
		private function updateCarusele():void
		{
			movementBit(movementPoint.x - movementPoint.y);
			movementPoint.y = movementPoint.x;
		}
		
		private function onCaruseleTarget():void
		{
			selectedObject = getChildClosestToCenter()[0];
			if(onMovementComplete != null)
				onMovementComplete();
		}
		/** Starts animated transition from selected object to next object.
		 * <ul><li>If dir is negative - moves elements to the left. If positive - to the right.</li>
		 * <li>If dir absolute value is 1 - moves to next neighbour, 2 - jumps two neighbours,etc. </li></ul> 
		 * @see #movementSpeed @see #easingType */
		public function poolMovement(dir:int):void
		{	
			movementProps.x = (selectedObject[mod.d]+GAP) * dir;
			AO.animate(movementPoint, movementSpeed, movementProps,onCaruseleTarget,1,false,easingType,true);
		}
		/** Returns most center child in the carousel name @see #currentChoiceObject */
		public function get currentChoice():String { return selectedObject ?  selectedObject.name : null }
		/** Returns most center child in the carousel */
		public function get currentChoiceObject():DisplayObject { return selectedObject as DisplayObject }
	}
}