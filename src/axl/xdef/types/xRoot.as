package axl.xdef.types
{
	import flash.display.DisplayObject;
	import flash.utils.setTimeout;
	
	import axl.utils.AO;
	import axl.utils.U;
	import axl.xdef.XSupport;

	/** Master class for XML DisplayList projects. Treat it as your stage */
	public class xRoot extends xSprite
	{
		public static var instance:xRoot;
		public var elements:Object = {};
		/** Master class for XML DisplayList projects. Treat it as your stage */
		public function xRoot(definition:XML=null)
		{
			super(definition);
			if(instance != null)
				throw new Error("SINGLETONE EXCEPTION! " + this);
			instance = this;
			
		}
		
		// ADD - REMOVE
		/** Returns first XML child of Config[node] which matches it name */
		public function getAdditionDefByName(v:String,node:String='additions'):XML
		{
			return U.CONFIG[node].*.(@name==v)[0];
		}
		/** Instantiates element from loaded config node. Instantiated / loaded / cached object
		 * is an argument for callback. 
		 * <br>All objects are being created within <code>XSupport.getReadyType</code> function. 
		 * <br>All objects are being cached within <code>XSupport.elements</code> dictionary where
		 * xml attribute <b>name</b> is key for it. 
		 * @param v - name of the object (must match any child of <code>node</code>). Objects
		 * are being looked up by <b>name</b> attribute. E.g. v= 'foo' for
		 *  <pre> < node>< div name="foo"/>< /node>  </pre> 
		 * @param callback - Function of one argument - loaded element. Function will be executed 
		 * once element is available (elements with <code>src</code> attribute may need to require loading of their contents).
		 * @param node - name of the XML tag (not an attrubute!) that is a parent for searched element to instantiate.
		 * @see axl.xdef.XSupport#getReadyType()
		 */
		public function getAdditionByName(v:String, callback:Function, node:String='additions',onError:Function=null):void
		{
			U.log('getAdditionByName', v);
			if(elements[v] != null)
			{
				U.log(v, 'already exists in "METAS" cache');
				callback(elements[v]);
				return;
			}
			
			var xml:XML = getAdditionDefByName(v,node);
			if(xml== null)
			{
				if(onError == null) 
					throw new Error(v + ' does not exist in additions node');
				else
				{
					onError();
					return;
				}
			}
			
			XSupport.getReadyType(xml, loaded);
			function loaded(dob:DisplayObject):void
			{
				elements[v] =  dob;
				callback(dob);
			}
		}
		
		/** Executes <code>getAdditionByName</code> in a loop. @see #getAdditionByName() */
		public function getAdditionsByName(v:Array, callback:Function):void
		{
			for(var i:int =0, j:int = v.length; i<j;i++)
				getAdditionByName(v[i], callback);
		}
		
		/** Removes elements from display list. Accepts arrays of display objects, their names and
		 * mixes of it. Skipps objects which are not part of the display list. */
		public function remove(...args):void
		{
			for(var i:int = 0,j:int = args.length, v:Object; i < j; i++)
			{	
				v = args[i]
				if(v is Array)
					removeElements(v as Array);
				else if(v is String)
					removeByName(v as String);
				else if(v is DisplayObject)
					removeChild(v as DisplayObject)
				else
					throw new Error("Can't remove: " + v + " - is unknow type");
			}
		}
		/** If child of name specified in argument exists - removes it. All animtions are performed
		 * based on individual class settings (xBitmap, xSprite, xText, etc)*/
		public function removeByName(v:String):void	{ removeChild(getChildByName(v)) }
		
		/**  removes array of objects from displaylist. can be actual displayObjects or their names */
		public function removeElements(args:Array):void
		{
			for(var i:int = args.length; i-->0;)
				args[i] is String ? removeByName(args[i]) : removeChild(args[i]);
		}
		
		// ANIMATION UTILITIES - to comment
		public function singleAnimByMetaName(objName:String, screenName:String, onComplete:Function=null):void
		{
			var pair:Object, obj:DisplayObject, meta:Object;
			if(elements.hasOwnProperty(objName))
			{
				pair = elements[objName] || {};
				obj = pair.hasOwnProperty('obj') ? pair.obj : null;
				meta = pair.hasOwnProperty('meta') ? pair.meta : null;
			}
			if(meta != null && obj != null && meta.hasOwnProperty(screenName))
			{
				U.log(objName, '--->', screenName, 'single animation');
				var animationArguments:Array = [obj].concat(meta[screenName]);
				animationArguments[3] = onComplete;
				AO.animate.apply(null, animationArguments);
			}
			else
			{
				if(onComplete != null)
					setTimeout(onComplete, 10);
			}
		}
		
		public function animAllMetaToScreen(screenName:String,onComplete:Function=null):void
		{
			var all:int=0;
			for(var key:String in elements)
			{
				all++;
				singleAnimByMetaName(key,screenName,singleComplete);
			}
			function singleComplete():void
			{
				if(--all == 0 && onComplete !=null)
					onComplete();
			}
		}
	}
}