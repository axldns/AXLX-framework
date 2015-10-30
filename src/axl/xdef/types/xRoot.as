package axl.xdef.types
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.utils.setTimeout;
	
	import axl.utils.Ldr;
	import axl.utils.U;
	import axl.xdef.XSupport;
	import axl.xdef.interfaces.ixDef;

	/** Master class for XML DisplayList projects. Treat it as your stage */
	public class xRoot extends xSprite
	{
		public var elements:Object = {};
		protected var xsupport:XSupport;
		protected var CONFIG:XML;
		public var sourcePrefixes:Array;
		
		
		/** Master class for XML DisplayList projects. Treat it as your stage */
		public function xRoot(definition:XML=null)
		{
			if(xsupport == null)
				xsupport = new XSupport();
			if(xsupport.root == null)
				xsupport.root = this;
			super(definition);
		}
		
		public function get config():XML { return CONFIG }
		
		override public function set def(value:XML):void
		{
			// as xRoot is not called via XSupport.getReadyType
			// it must take care of parsing definition itself
			super.def = value;
			xsupport.pushReadyTypes2(value, this,'addChildAt',this);
			XSupport.applyAttributes(value, this);
		}
		
		
		// ADD - REMOVE
		public function add(v:Object,underChild:String=null,onNotExist:Function=null,indexModificator:int=0,node:String='additions',forceNewElement:Boolean=false):void
		{
			if(v is Array)
				getAdditionsByName(v as Array, gotit,node,onNotExist,forceNewElement);
			else
				getAdditionByName(v as String, gotit,node,onNotExist,forceNewElement)
			function gotit(d:DisplayObject):void{
				
				if(underChild != null)
					addUnderChild(d,underChild,indexModificator);
				else
					addChild(d);
			}
		}
		
		public function addTo(v:Object,intoChild:String,command:String='addChild',onNotExist:Function=null,node:String='additions',forceNewElement:Boolean=false):void
		{
			if(intoChild.charAt(0) == "$")
				intoChild = XSupport.simpleSourceFinder(this,intoChild) as String;
			var c:DisplayObjectContainer = xsupport.registered(intoChild) as DisplayObjectContainer;
			if(c == null)
			{
				U.log(this, "[addTo][ERROR] 'intoChild' parameter refers to non existing object or it's not a DisplayObjectContainer descendant");
				return
			}
				
			if(v is Array)
				getAdditionsByName(v as Array, c[command],node,onNotExist,forceNewElement);
			else
				getAdditionByName(v as String, c[command],node,onNotExist,forceNewElement);
		}
		
		public function addUnderChild(v:DisplayObject, chname:String,indexMod:int=0):void
		{
			var o:DisplayObject = getChildByName(chname);
			
			var i:int = o ? this.getChildIndex(o) : -1;
			var j:int = contains(v) ? getChildIndex(v) : int.MAX_VALUE;
			if(j < i)
			{
				U.log("Child", v, v.name, "already exists in this container and it is under child", o, o? o.name : null);
				return;
			}
			if(i > -1)
			{
				i+= indexMod;
				if(i<0)
					i=0;
				if(i < this.numChildren)
					this.addChildAt(v,i);
				else
					this.addChild(v);
			}
			else this.addChild(v);
		}
		
		/** Returns first XML child of Config[node] which matches it name */
		public function getAdditionDefByName(v:String,node:String='additions'):XML
		{
			return this.CONFIG[node].*.(@name==v)[0];
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
		public function getAdditionByName(v:String, callback:Function, node:String='additions',onError:Function=null,forceNewElement:Boolean=false):void
		{
			U.log('getAdditionByName', v);
			if(v == null)
				return U.log("requesting non existing element", v);
			if(v.charAt(0) == '$')
			{
				v = XSupport.simpleSourceFinder(this,v) as String;
				if(v == null)
					v='ERROR';
			}
			if((elements[v] != null) && !forceNewElement)
			{
				U.log(v, 'already exists in xRoot.elements cache');
				callback(elements[v]);
				return;
			}
			
			var xml:XML = getAdditionDefByName(v,node);
			if(xml== null)
			{
				U.log('---@---@---@---@---@ [WARINING] REQUESTED CHILD "' + v + '" DOES NOT EXIST IN CONFIG "' + node +  '" NODE @---@---@---@---@---');
				if(onError == null) 
					throw new Error(v + ' does not exist in additions node');
				else
				{
					if(onError.length > 0)
						onError(v);
					else
						onError()
					return;
				}
			}
			
			xsupport.getReadyType2(xml, loaded,true,null,this);
			function loaded(dob:DisplayObject):void
			{
				elements[v] =  dob;
				callback(dob);
			}
		}
		
		/** Executes <code>getAdditionByName</code> in a loop. @see #getAdditionByName() */
		public function getAdditionsByName(v:Array, callback:Function,node:String='additions',onError:Function=null,forceNewElement:Boolean=false):void
		{
			var i:int = 0, j:int = v.length;
			next();
			function next():void
			{
				if(i<j)
					getAdditionByName(v[i++], ready,node,onError,forceNewElement);
			}
			
			function ready(v:DisplayObject):void
			{
				callback(v);
				next()
			}
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
		
		/**  Uses registry to define child to remove. This can reach inside containers to remove specific element.
		 * The last registered element of name defined in V will be removed */
		public function removeRegistered(v:String):void
		{
			var dobj:DisplayObject = xsupport.registered(v) as DisplayObject;
			if(dobj != null && dobj.parent != null)
				dobj.parent.removeChild(dobj);
		}
		/** executes <code>removeRegistered</code> in a loop */
		public function removeRegisteredGroup(v:Array):void
		{
			for(var i:int = 0; i < v.length; i++)
				removeRegistered(v[i]);
		}
		
		public function rmv(...args):void
		{
			for(var i:int = 0,j:int = args.length, v:Object; i < j; i++)
			{	
				v = args[i]
				if(v is String)
					removeRegistered(v as String);
				else if(v is Array)
					removeRegisteredGroup(v as Array);
				else if(v is DisplayObject)
					removeChild(v as DisplayObject)
				else
					U.log(this,"[rmv][WARNING] - Can't remove: " + v + " - is unknow type");
			}
		}
		
		public function get registry():Object { return xsupport.registry }
		public function registered(v:String):Object { return  xsupport.registered(v) }

		// ANIMATION UTILITIES - to comment
		public function singleAnimByMetaName(objName:String, screenName:String, onComplete:Function=null,c:ixDef=null):void
		{
			c = c || this.getChildByName(objName) as ixDef;
			U.log("singleAnimByMetaName [", screenName, '] - ', objName, c);
			if(c != null && c.meta.hasOwnProperty(screenName))
				XSupport.animByNameExtra(c, screenName, onComplete);
			else
			{
				if(onComplete != null)
					setTimeout(onComplete, 5);
			}
		}
		
		public function animateAllRegisteredToScreen(screenName:String,onComplete:Function=null):void
		{
			var all:int=0;
			var reg:Object = xsupport.registry;
			for(var s:String in reg)
			{
				var c:ixDef = reg[s] as ixDef;
				if(c != null && c.meta.hasOwnProperty(screenName))
				{
					all++;
					singleAnimByMetaName(c.name,screenName,singleComplete,c);
				}
			}
			if(all < 1 && onComplete != null)
				onComplete();
			function singleComplete():void
			{
				if(--all == 0 && onComplete !=null)
					onComplete();
			}
		}
		
		public function animAllMetaToScreen(screenName:String,onComplete:Function=null):void
		{
			var all:int=0;
			for(var i:int = 0; i < this.numChildren; i++)
			{
				var c:ixDef = this.getChildAt(i) as ixDef;
				if(c != null && c.meta.hasOwnProperty(screenName))
				{
					all++;
					singleAnimByMetaName(c.name,screenName,singleComplete,c);
				}
			}
			if(all < 1 && onComplete != null)
				onComplete();
			function singleComplete():void
			{
				if(--all == 0 && onComplete !=null)
					onComplete();
			}
		}
		public function get files():Object { return Ldr.objects }
		
		public function assign(left:String,leftProperty:String,operand:String,right:String,target:String=null,targetProperty:String=null):void
		{
			var l:Object = XSupport.simpleSourceFinder(this,left);
			var lp:String = XSupport.simpleSourceFinder(this,leftProperty) as String;
			var r:Object = XSupport.simpleSourceFinder(this,right);
			var t:Object = (target != null) ?  XSupport.simpleSourceFinder(this,target) : l;
			var tp:String = (targetProperty != null) ?  XSupport.simpleSourceFinder(this,targetProperty) as String : lp;
			
			if(!l || !lp || !t || !tp) // right can be null or false
			{
				U.log(this, "[assign] INVALID ASIGNMENT:", left, leftProperty, operand, right,'|', target ? target : '', targetProperty ? targetProperty : '', 'vs', "l:",l,"lp:",lp,"r:",r,'|',"t:",t,"tp:",tp);
				return;
			}
			try {
				//U.log(this, "[assign]", "l:",l,"lp:",lp,"r:",r,'|',"t:",t,"tp:",tp);
				switch(operand)
				{
					case '!': t[tp] = !r; break;
					case '+': t[tp] = l[lp] + r; break;
					case '-':  t[tp] = l[lp] - Number(r); break;
					case '*':  t[tp] = l[lp] * Number(r); break;
					case '/':  t[tp] = l[lp] / Number(r); break;
					case '%':  t[tp] = l[lp] % Number(r); break;
					case '>>':  t[tp] = l[lp] >> Number(r); break;
					case '<<':  t[tp] = l[lp] << Number(r); break;
					case '>':  t[tp] = l[lp] > r; break;
					case '<':  t[tp] = l[lp] < r; break;
					case '<=': t[tp] = l[lp] <= r; break;
					case '>=':  t[tp] = l[lp] >= r; break;
					case '==':  t[tp] = l[lp] == r; break;
					case '===':  t[tp] = l[lp] === r; break;
					case '&&':  t[tp] = l[lp] && r; break;
					case '||':  t[tp] = l[lp] || r; break;
					case '+=': l[lp] += r; break;
					case '-=': l[lp] -= r; break;
					case '*=': l[lp] *= r; break;
					case '/=': l[lp] /= r; break;
					case '=': l[lp] = r; break;
					case 'is': t[tp] = l[lp] is r.constructor; break;
					default:
						U.log(this, "[assign] INVALID OPERAND:", left, leftProperty, operand, right,'|', target ? target : '', targetProperty ? targetProperty : '');
						break;
				}
			}
			catch(e:*)
			{
				U.log(this, "[assign][ERROR]:",e, '\ON:', left, leftProperty, operand, right,'|', target ? target : '', targetProperty ? targetProperty : '');
			}
		}
		
		public function replace(left:String,leftProperty:String,regexp:String,replacement:String,regexpProperties:String='g',target:String=null,targetProperty:String=null,replacementIsDynamic:Boolean=true):void
		{
			var l:Object = XSupport.simpleSourceFinder(this,left);
			var lp:String = XSupport.simpleSourceFinder(this,leftProperty) as String;
			var t:Object = (target != null) ?  XSupport.simpleSourceFinder(this,target) : l;
			var tp:String = (targetProperty != null) ?  XSupport.simpleSourceFinder(this,targetProperty) as String : lp;
			var rp:String = replacementIsDynamic ? String(XSupport.simpleSourceFinder(this,replacement)) : replacement;
			
			if(!l || !lp || !t || !tp || rp==null) // right can be null or false
			{
				U.log(this, "[replace] INVALID ARGUMENTS:", left, leftProperty, regexp,replacement,regexpProperties,'|', target ? target : '', targetProperty ? targetProperty : '', 
					'vs', l,lp,regexp,rp,regexpProperties,'|',t,tp);
				return;
			}
			var r:RegExp = new RegExp(regexp, regexpProperties);
			try { 
				//U.log("[REPLACE] TARGET:", t, tp,'('+t[tp]+')', "LEFT:", l, lp, '('+l[lp]+')','REGEXP:', r, "REPLACEMENT:", rp);
				t[tp] = l[lp].replace(r,rp) 
			
			}
			catch(e:*) { U.log(this, '[replace]ERROR',e,' ON:\n',left, leftProperty, regexp,replacement,regexpProperties,'|', target ? target : '', targetProperty ? targetProperty : '', 
				'vs', l,lp,regexp,rp,regexpProperties,'|',t,tp) }
		}
		
		public function addIfMatches(sel:String,regexp:String='.*',onTrue:Object=null,onFalse:Object=null):void
		{
			if(sel && sel.match(new RegExp(regexp)))
			{
				try { add.apply(null, (onTrue is Array) ? onTrue : [onTrue]) }
				catch(e:*) { U.log(this, "[addIfMatches]ERROR: invalid argument onTrue:", onTrue) }
			}
			else
			{
				try { add.apply(null, (onFalse is Array) ? onFalse : [onFalse]) }
				catch(e:*) { U.log(this, "[addIfMatches]ERROR: invalid argument onFalse:", onFalse) }
			}
		}
		
		public function executeIfMatches(sel:String,regexp:String,onTrue:String,onFalse:String,node:String='additions'):void
		{
			if(sel && sel.match(new RegExp(regexp)))
				executeFromXML(onTrue)
			else
				executeFromXML(onFalse)
		}
		
		public function executeFromXML(name:String,node:String='additions'):void
		{
			this.getAdditionByName(name, gotIt,node, gotIt);
			function gotIt(v:*):void
			{
				if(v && v is xButton)
					v.execute();
				else
					U.log("NO >>"+name+"<< btn defined in", node);
			}
		}
	}
}