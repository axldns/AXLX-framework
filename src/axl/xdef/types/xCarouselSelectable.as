package axl.xdef.types
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import axl.utils.AO;
	import axl.utils.U;

	public class xCarouselSelectable extends xCarousel
	{
		private var btnSelect:xButton;
		private var poolMask:DisplayObject;
		private var selectedObject:Object;
		private var movementPoint:Point= new Point();
		public var movementSpeed:Number= .2;
		public var onSelect:Function;
		
		private var bmCache:Bitmap;
		private var bMatrix:Matrix;
		private var skel:Rectangle = new Rectangle();
		private var elementSelected:xAction;
		
		public var hoveredObject:DisplayObject;
		private var hoverProperty:String;
		public var hoverValue:Object;
		public var hoverValueIdle:Object;
		private var selectProperty:String;
		public var selectValue:Object;
		public var selectValueIdle:Object;
		public var onMovementComplete:Function;
		public var onMovementStart:Function;
		
		public function xCarouselSelectable(definition:XML,xroot:xRoot=null)
		{
			super(definition,xroot);
			this.cacheAsBitmap = true;
			railElementsContainer.addEventListener(MouseEvent.CLICK, mouseClickCarusele);
			railElementsContainer.addEventListener(MouseEvent.MOUSE_OVER, mouseOverCarusele);
			railElementsContainer.addEventListener(MouseEvent.MOUSE_OUT, mouseOutCarusele);
		}
		
		protected function mouseClickCarusele(e:MouseEvent):void
		{
			var newSelected:DisplayObject = e.target as DisplayObject;
			if(selectProperty)
			{
				if(newSelected == selectedObject)
				{
					selectedObject[selectProperty] = selectValueIdle;
					selectedObject = null;
				}
				else
				{
					if(selectedObject != null)
						selectedObject[selectProperty] = selectValueIdle;
					selectedObject = newSelected;
					selectedObject[selectProperty] = selectValue;
				}
			}
			else
				selectedObject = newSelected;
			if(btnSelect == null)
				if(onSelect != null)
					onSelect();
		}
		
		protected function mouseOutCarusele(e:MouseEvent):void
		{
			if(hoverProperty && hoveredObject != null && hoveredObject != selectedObject)
			{
				hoveredObject[hoverProperty] = hoverValueIdle;
			}
		}
		
		protected function mouseOverCarusele(e:MouseEvent):void
		{
			if(hoverProperty)
			{
				hoveredObject = e.target as DisplayObject;
				if(hoveredObject != null && hoveredObject != selectedObject)
					hoveredObject[hoverProperty] = hoverValue;
			}
		}
		
		public function get selectedObjectProperty():String	{ return selectProperty }
		public function set selectedObjectProperty(value:String):void {	 selectProperty = value }
		
		public function get hoverObjectProperty():String	{ return hoverProperty }
		public function set hoverObjectProperty(value:String):void { hoverProperty = value }
		
		
		override public function addToRail(obj:DisplayObject, seemles:Boolean=false):void
		{
			switch(obj.name.toLowerCase())
			{
				case 'mask':
					poolMask = obj;
					poolMask.cacheAsBitmap = true;
					railElementsContainer.cacheAsBitmap = true;
					railElementsContainer.mask = poolMask;
					addChild(poolMask);
					break;
				case 'btnleft':
				case 'btnright':
				case 'btnup' : 
				case 'btndown':
					if(obj is xButton)
					{
						obj['onClick'] = poolDirectionEvent;
						addChild(obj);
					}
					break;
				case 'btnselect' : btnSelect = obj as xButton;
					btnSelect.onClick = btnSelectHandler;
					addChild(btnSelect);
					break;
				default : super.addToRail(obj, seemles);
					break;
			}
		}
		
		override public function set meta(v:Object):void
		{
			super.meta = v;
			if(!(meta is String))
				if(meta.hasOwnProperty('elementSelected'))
					elementSelected = new xAction(meta.elementSelected,xroot,this);
		}
		
		override protected function elementAdded(e:Event):void
		{
			selectedObject = getChildClosestToCenter()[0];
			super.elementAdded(e);
		}
		
		
		private function btnSelectHandler(e:MouseEvent):void
		{
			if(onSelect != null) onSelect();
		}
		
		private function poolDirectionEvent(e:MouseEvent):void
		{
			if(selectedObject == null)
				selectedObject = getChildClosestToCenter()[0];
			if(selectedObject == null)
				return;
			
			poolMovement((e.target.name.match(/(left|up)/i)) ? 1 : -1);
		}
		
		private function poolMovement(dir:int):void
		{	
			var p:Object = {onUpdate : updateCarusele};
				p[mod.a] = (selectedObject.width+GAP) * dir;
			if(onMovementStart != null)
				onMovementStart();
			AO.animate(movementPoint, movementSpeed, p,onCaruseleTarget,1,false,null,true);
			
		}
		
		private function updateCarusele():void
		{
			movementBit(movementPoint[mod.a] - movementPoint[modA.a]);
			movementPoint[modA.a] = movementPoint[mod.a];
		}
		
		private function onCaruseleTarget():void
		{
			selectedObject = getChildClosestToCenter()[0];
			if(onMovementComplete != null)
				onMovementComplete();
		}
		
		public function get currentChoice():String { return selectedObject ?  selectedObject.name : null }
		public function get currentChoiceMC():DisplayObject { return selectedObject as DisplayObject }
		
		public function getCurrentChoice(fitIn:Object):Bitmap
		{
			var ascale:Number = 1;
			var flt:Array = selectedObject.filters;
			selectedObject.filters = [];
			if(fitIn != null)
			{
				skel.setTo(0,0,selectedObject.width, selectedObject.height);
				U.resolveSize(skel, fitIn);
				ascale = skel.width / selectedObject.width;
			}
			
			if(bmCache.bitmapData != null)
				bmCache.bitmapData.dispose();
			else
			{	// lazy init
				bMatrix = new Matrix();
				bMatrix.scale(ascale, ascale);
			}
			bmCache.bitmapData = new BitmapData(selectedObject.width * ascale + 2, selectedObject.height * ascale + 2,true, 0x00000000);
			bmCache.bitmapData.draw(selectedObject as DisplayObject,bMatrix,null,null,null,true);
			bmCache.x =  fitIn.width - bmCache.width >>1;
			bmCache.y = fitIn.height - bmCache.height >> 1;
			selectedObject.filters = flt;
			return bmCache;
		}
	}
}