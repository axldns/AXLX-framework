**AXLX Framework**
--------------

AXLX - open source framework for building projects based on dynamicaly loaded XML files. 

###Table of contents:

- [Overview](#overview)
- [STEP BY STEP](#step-by-step)
	- [Setting up the project](#setting-up-the-project)
	- [XML name and location](#xml-name-and-location)
	- [XML structure](#xml-structure)
		- [Nodes](#nodes)
			- [Grand nodes](#grand-nodes)
			- [Child Nodes](#child-nodes)
				- [Displayable nodes](#displayable-nodes)
				- [Functional nodes](#functional-nodes)
				- [Decorative nodes](#decorative-nodes)
		- [Attributes](#attributes)
			- [How attributes are parsed](#how-attributes-are-parsed)
				- [Attribute key](#attribute-key)
				- [Attribute value](#attribute-value)
				- [How to write ActionScript in XML attributes](#how-to-write-actionscript-in-xml-attributes)
				- [Special attributes](#special-attributes)
					- [name](#name)
					- [meta](#meta)
					- [src](#src)
			- [When attributes are parsed](#when-attributes-are-parsed)
	- [Interactivity](#interactivity)
		- [Add, remove elements to/from display list](#add-remove-elements-tofrom-display-list)
		- [The Registry](#the-registry)
		- [Animations](#animations)
			- [meta variables, keywords](#meta-variables-keywords)
			- [meta variables, non keywords](#meta-variables-non-keywords)
			- [ui controller’s animations](#ui-controllers-animations)
			- [manual scripts](#manual-scripts)
			- [Externalized animations](#externalized-animations)

		- [Network communication](#network-communication)

- [Working with it](#working-with-it)



Overview
--------

AXLX is an Open Source framework for building projects based on dynamicaly loaded XML files. 

>It is an answer to constant need of fast updates to live projects. Since updating XML does not require compilation/depoloyment afterwards, amends and bug fixes can be applied in an eye blink. 

Unlike flex framework, where XML (MXML) files are used for compilation, in AXLX XMLs are used for building flash content after compilation. XML definitions can define layouts, complex interactivity, logic, data processing and even more sophisticated tasks. It benefits from set of UI components, controllers, tweening engine and other elements of [AXL library](https://github.com/axldns/AXL-library).

It actually allows to build, develop and update projects without IDE. All it needs is a swf file with AXLX embedded in or a stub loading AXLX as a RSL. This can move weight of not necessarily developer updates to other member of the team (copywriters, graphic designers). 
Since the most significant part is externalized to XML, using AXLX framework have positive impact on source code controll.

You can build your content completely on AXLX framework or just make it complementary part of larger projects. 
It is easy to extend it by building your API on top of it.

Dedicated software to work with AXLX projects is [AxlLoader](https://github.com/axldns/AxlLoader) small, fast open source (free) AIR app. It allows to re-load projects quickly instead of constantly re-compiling or re-opening to view changes made to XML definitions.

STEP BY STEP
----------------------

###Setting up the project

The most basic set-up is stupidly simple. 

 1. Create new web project, give it a name, let's say "Example".
 2. Import AXL Library and AXLX Framework to your project.
 3. Navigate to your root class (Example.as) and make it extending xRoot class (import axl.xdef.types.display.xRoot).
 4. You're done! Debug your project and watch the console log. 

###XML name and location
Once you run a debug of Example.as, you'll probably see your swf blank with a blue [alert](http://axldns.com/?page_id=150) saying "*Invalid config file*". 
When you look into console, you'll see a substantial log - the result of initial flow. The flow is quite complex but there's not much to worry, all it does is finding out where to load config from, loads it an builds the content.

> The easiest way to find out what was the location the config file was searched for is to examinate log for "xml" occurrences.

By default XML file name has to have the same name as the flash file. 
By default, it checks ONE DIRECTORY UP relative to where your swf is placed (in web projects). 
It applies to content run locally and to swf files put on server. This can be controlled by various settings, see [independent server directories](http://axldns.com/docs/axl/xdef/types/display/xRoot.html#appRemote), [file name dictates sub-directories](http://axldns.com/docs/axl/xdef/xLauncher.html#appReomoteSPLITfilename), [hardcoding config filename](http://axldns.com/docs/axl/xdef/types/display/xRoot.html#fileName), [loading AXLX from stub](http://axldns.com/docs/axl/xdef/types/display/xRoot.html#xRoot()).
For mobile projects, default location is File.applicationStorageDirectory.

In our case it's going to be "Example/bin-debug/../Example.xml". That means our XML definition should be placed in root of our project folder (outside "src").

Ok, config not found (SKIPPED). Let's feed it. Let's create an empty Example.xml and debug it again.

Blue bar still says "Invalid config file", but this time inside log we can see that file was LOADED (instead of skipped like last time). It's also printed out that "Config isn't valid XML file". Lets create valid XML file. 

###XML structure

    <axlx>
    	<root/>
    </axlx>
   *Minimal valid XML definiton of the config file*
If we copy the code above, paste to our Example.xml created before and debug the project again, blue error bar is finally gone, but swf is still blank. That's a good sign. We can start building content.
####Nodes
There are two kind of nodes available: *Grand Nodes* and *Child Nodes*.
Only Grand Nodes can be children of top XML node. Child Nodes can only be children of Grand Nodes. 
#####Grand nodes
There are three Grand Nodes interpreted from the XML definiton:

 - `<root/>` - represents your root display object (instance of Example class in our project). Children of this node are processed (loaded, instantiated, added to the display list) right after config file is loaded and project settings are read.
 - `<project/>`- sets up project / library related properties such as
   debug mode, time-out for assets loading, time-out for POST and GET requests etc. Parsed right after config file is loaded and validated, can be referenced later though.   
 - `<additions/>` - container for Child Nodes that are not
   instantiated automatically. Children of this node can be turned from
   XML nodes to valid ActionScript objects as a result of interactivity, processed and added to display list or stay reference-able for further interactivity / processing. Before instantiation they take up no more space in memory than XML nodes.

#####Child Nodes
Child Nodes represent particular data types. Each one (once instantiated) is a particular class instance. These are classes or decorative functions defined by AXLX framework and can be divided on 3 groups:  [12 displayable nodes](http://axldns.com/docs/axl/xdef/types/display/package-detail.html), [4 functional nodes](http://axldns.com/docs/axl/xdef/types/package-detail.html) and 3 decorative nodes. 

######Displayable nodes

| Node | Description |
| ------------- |-------------	|
| `<div>`    | [Display object container](http://google.com) |
| `<img>`    | [Bitmap, image](http://axldns.com/docs/axl/xdef/types/display/xBitmap.html) |
|`<txt>` | [Text field merged with TextFormat](http://axldns.com/docs/axl/xdef/types/display/xText.html)    |
| `<btn>`   | [Button](http://axldns.com/docs/axl/xdef/types/display/xButton.html) |
|`<msk>`  | [Interactive container with mask and bounding box](http://axldns.com/docs/axl/xdef/types/display/xMasked.html) |
| `<swf>` | [Container to control loaded swf's timeline](http://axldns.com/docs/axl/xdef/types/display/xSwf.html) |
| `<scrollBar>` | [Interactive container with bounding box, multi purpose, plug-able to `<msk>`](http://axldns.com/docs/axl/xdef/types/display/xScroll.html) |
| `<carousel>`    | [Interactive container, auto children distribution, infinite horizontal / vertical scroll](http://axldns.com/docs/axl/xdef/types/display/xCarousel.html) |
| `<carouselSelectable>`     | [same as `<carousel>` but provides animated scroll from object to object and  has got "center" object concept](http://axldns.com/docs/axl/xdef/types/display/xCarouselSelectable.html)|
| `<form>`     | [container that validates all input type text fields against regular expressions they carry, exposes form object based on these](http://axldns.com/docs/axl/xdef/types/display/xForm.html) |
| `<vod>`     | [Video on demand player (regular flash video, stage video not supported yet).](http://axldns.com/docs/axl/xdef/types/display/xVOD.html) |
| `<root>`     | [Master class of the framework, the root of display list, and context for code execution, treat it as your stage, so it's once in the project.](http://axldns.com/docs/axl/xdef/types/display/xVOD.html) |


Layering display list

If node is a recipe for descendant of `DisplayObjectContainer`, XML children of that node representing other `DisplayObject` descendants  will automatically become children of that `DisplayObjectContainer`. Example:

    <div>
    	<txt/>
    	<img/>
    </div>
is an equivalent of: 

    var s:Sprite = new Sprite();
    s.addChild(new TextField());
    s.addChild(new Bitmap());
It's not hard to notice the resemblance between layering display list this way and HTML. There are more of these similarities in the framework. It's just upside down comparing to it! Particular nodes represent instructions and they're read from top to bottom, putting last read object on top of the stack.

######Functional nodes
Functional nodes can not be added to the display list but they follow the same principal: placed in `<root>` - processed (instantiated) right after config is loaded, placed in `<additions>` node take no more space than their XML node until they're processed in a result of interactivity. Even they're not the display objects, can be XML children of any Child Node - they'll be processed and available right after their parent.

| Node | Description |
| ------------- |-------------	|
|`<act>`| [Function equivalent](http://axldns.com/docs/axl/xdef/types/xAction.html) |
|`<data>`| [Lightweight container for loaded data (JSON, XML, CSV, Sound, swf with fonts)](http://axldns.com/docs/axl/xdef/types/xObject.html) |
|`<script>`| [Loads external XML definitions to the project such as templates, components](http://axldns.com/docs/axl/xdef/types/xScript.html) |
|`<timer>`| [Combination of `setTimeout` and `setInterval`](http://axldns.com/docs/axl/xdef/types/xTimer.html) |

Since functional nodes operate entirely on attributes (no reason for them to have children), they're typically occur as closed nodes
e.g. `<act attrib='123'/>`. Attributes usage is described right after Nodes.

######Decorative nodes
Decorative nodes are not display objects themselves but they decorate display objects. In order to decorate any of it, make it it's child. 

| Node | Description |sub-nodes|
| ------------- |-------------	|------------- |
|`<colorTransform/>`| [assigns flash.geom.ColorTransform](http://axldns.com/docs/axl/xdef/XSupport.html#getColorTransformFromDef%28%29) | no
|`<graphics>`| [draws on object using flash.display.Graphics](http://axldns.com/docs/axl/xdef/XSupport.html#drawFromDef%28%29) | `<command>`
|`<filters>`| [creates and assigns an array of descendands of flash.filters.BitmapFilter](http://axldns.com/docs/axl/xdef/XSupport.html#filtersFromDef%28%29) | `<filter/>`

Decorative nodes can only be used with display objects that support given style of decoration, that means e.g. using `<graphics>` on `<img>` or `<txt>` has no effect.

    <img>
	    <colorTransform/>
    </img>
*Example use of decorative node. Assigns flash.display.ColorTransform to Bitmap.*

####Attributes
In contrast to node type which defines what class is going to be instantiated, XML attributes of the node are here to set properties of that particular instance.  Handy inline key-value style saves a lot of space and can be copied from one node to another. Example:

    var t:TextField = new TextField();
    t.type= "input";
    t.border = true;
    t.width  = 200;
    t.height = 60;
    t.x = 30;
    t.y = 20;

Can be translated to 

    <txt x='30' y='20' width='200' height='30' border='true' type='input'/>

Ok, let's come back to our Example project. We've got an Example.swf file in bin-debug folder and Example.xml file one directory up. We've successfully debugged the project causing swf to load our minimal valid XML. We now know that we can safely place any of 11 displayable Child Nodes into the Grand Node called `<root>` and they'll be rendered right after config is loaded. We also know how to set properties of any instance that node type is linked to, so let's try it out with the txt node from example above. Our new Example.xml should look like this now:

    <config>
    	<root>
    		<txt x='30' y='20' width='200' height='30' border='true' type='input'/>
    	</root>
    </config>
Debug or re-open Example.swf. Voilà! Rectangular, black border input text field appears on our flash. 
But let's take a closer look. `x`, `y`, `width`, `height` are of Number data type, `border` is Boolean, `type` is String. How does it know what to do, what happened to strong-typing? And what happens if we try to use attribute that does not exist in instance that node is linked to?

#####How attributes are parsed
The order of attributes matters - they're being processed from left to right. Attributes can refer to target's deeper properties. E.g.

    <msk controller.animationTime="2"/>

######Attribute key
 If target (any object) does not own property specified as attribute in the node, then the property is not assigned. If it does, value of the attribute is assigned to the target's property. If object is dynamic and property of given attribute name does not exist, new property on target is not created. 
######Attribute value
Every attribute value is parsed by a single [function](http://axldns.com/docs/axl/xdef/XSupport.html#resolveValue%28%29). In regular cases it passes it through **JSON.parse** method and assigns either result of parsing if it was successful or original string value if it failed. This allows to differentiate all primitives such as Numbers, Strings, Booleans, Arrays and Objects containing other primitives. Quite a wide field already, e.g. for creating matrix for ColorMatrixFilter or gradient fill for Graphics. 
>But parsing attribute can go further - it can go through the code evaluation and take value from reference to other object or even create new object or instance of any class available in ApplicationDomain.

In other words, it's available to write an ActionScript code inside attributes of any XML node. But this should not be overused and actually avoided wherever possible. Internal parser is small and fast but no way as fast as the real, compiled ActionScript. Use functionalities available within the framework. 
######How to write ActionScript in XML attributes
First of all, interpreter is quite limited. It performs really well (as for its size) but some limitations and bizzarity apply.  For instance, to refer to any class you may want to use (instantiation, static methods) it's required to invoke full package. Eg. `new flash.display.Sprite()`.  Another: parser is designed to return one result, therefore more then one instruction at the time must be wrapped in an array, where instructions are separated with coma character (semicolons are not recognized). 
Full overview of what is supported and what is not, can be found [here](http://axldns.com/docs/axl/utils/binAgent/RootFinder.html#parseInput%28%29).

To make sure an attribute value will go through code evaluation, use dollar sign as a prefix. E.g.

    <txt width='$stage.stageWidth/2' height='$stage.stageHeight/2'/>
This applies to any native flash object properties available within ActionScript documentation. However, within AXLX framework, there are certain properties of certain classes that do not require dollar sign prefix in attribute value to contain not compled ActionScript. They actually expect a String, which is going to be evaluated when needed. If you prefix such with dollar sign, evaluation will either occur to early (not wanted) or you'll make a reference to other object containing the right string to evaluate (advanced).

List of attributes that don't need dolar sign to evaluate value:

| attribute| implementors|
| ------------- |-------------	|
|onAddedToStage | [every displayable node](http://axldns.com/docs/axl/xdef/types/display/package-detail.html) | 
|onRemovedFromStage | [every displayable node](http://axldns.com/docs/axl/xdef/types/display/package-detail.html) | 
|onChildrenCreated| [every display object container](http://axldns.com/docs/axl/xdef/interfaces/ixDisplayContainer.html)| 
|onElementAdded| [every  display object container](http://axldns.com/docs/axl/xdef/interfaces/ixDisplayContainer.html) | 
|onMovementComplete| `<carouselSelectable>` |
|onStop| `<swf>` |
|onSubmit, onError| `<form>` | 
|onLinkEvent|`<txt>` |
|code|`<act>`,`<btn>`,`<txt>` |
|onOver, onOut, onDown, onRelease| `<btn>` | 
|onTimeIndexChange, onUpdate, onComplete| `<timer>` | 
|onInclude, onIncluded| `<script>` |
|onComplete, onExit, onPlayStart, onPlayStop, onBufferFull, onBufferEmpty, onMeta, onTimerUpdate| `<vod>` |
Each attribute containing uncompiled code can use `this` keyword. It works as expected - refers to the instance which contains that code. Eg.

    <btn onDown='this.x += 10'>
    	<txt mouseEnabled='false' >click me</txt>
    </btn>
*Using "this" keyword example. Clicking button moves it by 10 pixels.*

If keyword "this" is omitted, and for every other element, root context of our references and directives is our root class - Example.as in this case. Since it extends framework's xRoot class, gives a rich API to manipulate, add, remove, animate display objects, execute XML defined functions and more. How to reference other objects within the project can be found in "The Registry" paragraph.

#####Special attributes
In contrast to standard attributes, which refer to instance's properties and methods, there are three special ones, which are quite crucial for whole framework. They could be called Grand attributes.
They only apply to displayable and functional Child Nodes (excl. decorative) but not necessarily refer to existing fields of it.
######name
Each element you want to dynamically interact with should have name attribute of unique value. This is the core functionality; to allow all elements within XML config file to be found, instantiated, added to display list, animated, removed from display list, referenced from other elements, changed, functions to be executed, it has to be legitimated by name property. That means **every prime child of `<additions>` Grand Node has to have name attribute defined.** Unlike naming property e.g. ID or anyhow else, this allows easy integration since "name" property is native to all display objects in flash. It's also a part of the registry concept, described in Registry paragraph.
######meta
ixDef interface enforces providing dynamic container - space for animations definitions and any other referenceable properties. This variable suppose to be set up just once (be reset-resistant) in order to securely store data/states. It has to be JSON style object, so the simplest implementation would look like this:

    <div meta='{}'/>

Most of the framework classes has also defined "meta keywords", these are pre-reserved variable names in meta object. Their existence will be exterminated and appropriate action taken when they're found / looked for. None of meta keywords usage is obligatory but assigning inappropriate values to it may lead to unexpected results.  
List of meta keywords and their implementors:

| meta keyword| implementors| type of action
| ------------- |-------------	|-------------	|
|meta.addedToStage, meta.addChild, meta.addChildAt, meta.removeChild, meta.removeChildAt | [every displayable node](http://axldns.com/docs/axl/xdef/types/display/package-detail.html) | animation|
|meta.js | `<btn>`, `<txt>` |calls external interface, array of arguments| 
|meta.url | `<btn>` | navigates to url on execution| 
|meta.post | `<btn>`| performs POST or GET request on execution| 
|meta.replace|  `<txt>` | [replaces given pattern with given source within text](http://axldns.com/docs/axl/xdef/types/display/xText.html#meta)|
|meta.regexp|`<txt>`|[If txt is child of form, form checks for regular expressions to validate input](http://axldns.com/docs/axl/xdef/types/display/xForm.html)|

######src
Loads resource from specified address, turns it into usable ActionScript form (DisplayObject, XML, Sound, String, Object, ByteArray) and processes according to node type context. 
Address can be absolute or relative. Relative addresses take original XML file location as a base.
If resource is already loaded (other object loaded same filename first), by default no subsequent load call is made. In this case, for images, bitmap data is drawn (copied) from originally loaded source. For other data types "stealing effect" may occur. To prevent it use `overwriteInLib=true` attribute along with src. To prevent getting file from cache in web projects, use `cachebust='true'` attribute. 

Contextual behaviors when resource is loaded:

 - Draws loaded image to bitmapData associated with `<img>` node.
 - For any Display Object Container, creates new bitmap, draws to its bitmap data from resource, and adds it to it's display list at index 0.
 - For `<script>`  - loads external XML definition and merges it's
   additions node to main config's additons node.
 - For `<swf>` - loads it, searches against MovieClip to control
   existence, puts it into displayable container.
 - For `<data>` - loads and just keeps able to reference (for loading
   fonts in embeds swf its just enough).

Let's try it out with our Example project. Next to Example.xml let's create folder called "assets" and put dummy "Example.jpg" in it.
Our folder structure should now look like this:

    .
    ..
    assets
    	|-Example.jpg
    bin-debug
    	|-Example.swf
    Example.xml
    src
    	|-Example.as

 Lets add the image reference to our config. We want to make it backgrund, so we'll put an `<img>` node right after root tag is open, before `<txt>`. Now the config file should look like this:

	<config>
        <root>
    	    <img src='/assets/Example.jpg'/>
            <txt x='30' y='20' width='200' height='30' border='true' type='input'/>
        </root>
    </config>
Run Example.swf again and watch.

Has loading files ever been easier? In one line we can load, instantiate, set tons of properties and add it to the right spot at the display list. Saves tens of lines of code, eliminates dealing with event listeners, thinking about sequence and so on. 

 When processing any XML node, attribute src is checked before any other attribute, even before actual instantiation of the object  that node points to. Therefore you can be sure that every other attributes will be processed when resource defined in src is ready.
 
 

#####When attributes are parsed

For non-displayable objects, attributes are parsed just once - at instantiation. In displayable objects though, attributes are parsed on instantiation and (by default) every time object is added to stage! This can cause loads of unwanted results, especially if you put some scripting in attributes. Most common issue is object duplication. Most precious advantages of this behavior are: 

 - repeatable animations: when displayable object has an animation defined e.g. in meta.onAddedToStage, then every time object is added, all properties are set to original and animation can be performed exactly the same way. That can help building all screens self sufficient and easy.
 - dynamic text always up to date: re-setting text for txt nodes makes assigned "replace" mechanism to work, refresh.

However, to take control over parsing arguments at least twice (on instantiation, on added to stage) with help comes ixDisplay interface method `resetOnAddedToStage` and ixDef interface method `reset`.
>Use `resetOnAddedToStage='false'`  displayable node attribute if you want to avoid parsing attributes and code evaluation multiple times. Use `reset()` interface method to re-parse attributes manually, on demand.

Attribute `src` can not be a subject of reset. There's no way to reload resource assigned to already existing, instantiated node.

###Interactivity
We now know how to create and set up objects on stage (`<root>`). 
We also know that Child Nodes in `<additions>` node are only recipes for objects. We probably also know a little bit of magic with writing quasi ActionScript in attributes. 
Now, how to add objects from recipe to stage,  how to add object to another object, how to remove it from there dynamically?
####Add, remove elements to/from display list
We'll now clear out our Example.XML's root, so we can start sort of from scratch. Let's first include `<additions>` Grand Node. Ready? Does it look like this?:

    <config>
        <root>
        </root>
        <additions>
        </additions>
    </config>

Let's now create two buttons: A and B. We'll put A on the stage, but place B into additions node. We'll give them a name 'btnA' and 'btnB' accordingly.
Then we'll set button A to remove itself from stage and add button B instead. We'll do it similarly for button B, remove itself but add button A back again.
We'll give them a `txt` node as a child so they'll have some labels.
Our config file now is little bit more developed, looks like this:

    <config>
        <root>
        	<btn name='btnA' x='0' code='[rmv("btnA"),add("btnB")]'>
        		<txt border='true' mouseEnabled='false' size='30'>I'm A</txt>
        	</btn>
        </root>
        <additions>
        	<btn name='btnB' x='100' code='[rmv("btnB"),add("btnA")]'>
        		<txt border='true' mouseEnabled='false' size='30'>I'm B</txt>
        	</btn>
        </additions>
    </config>

Let's run Example.swf again.
As expected, on screen we can only see button A. Once clicked, button B appears and A vanishes. After click on B, B disappears and button A is restored. Further sequences give exactly the same results, it works! But how?  Does it create new button every time?
####The Registry
We've used uncompiled ActionScript in button's *code* attribute to call two methods: *add* and *rmv*. From "How to write ActionScript in XML attributes" we know, that default context for our commands is the xRoot class.  Both [`add`](http://axldns.com/docs/axl/xdef/types/display/xRoot.html#add%28%29) and [`rmv`](http://axldns.com/docs/axl/xdef/types/display/xRoot.html#rmv%28%29) methods indeed belong to [API](http://axldns.com/docs/axl/xdef/types/display/xRoot.html) of this class. 
There are few variations of add method but in general it follows the same scenario:

> Adds one or more elements to display list. Searches through **registry**  for already instantiated elements of the same name first and adds it to display list if found. If not found, searches through additions node for child with attribute name matching first argument value(s). If found in additions, instantiates and adds object to display list.

There's just one but efficient enough rmv method and what it does is: 
> Removes elements from the display list. Searches through **registry**. Accepts arrays of display objects, their names and mixes of it. Skips objects which are not part of the display list.

That 's handy, we don't have to know where the actual object is, what is it's parent, we can just remove it by name, globally (provided that it's name is unique).

They both mention registry object. What is it then?
According to the [documentation](http://axldns.com/docs/axl/xdef/types/display/xRoot.html#registry):
>Registry is an associative array of all instantiated objects which can be identified by name attribute. Multiple objects registered under the same name will cause registry to return only the most recently registered one. Object registration is automatic but only within AXLX framework classes. Other ixDef implementors can use XSupport class functions to register themselves or request change in registered name.

Is it now clear how button A knew where to look for button B and opposite? 
Ok, fine. Caching objects. For what else registry can be used?
Literally for everything. Especially for references to any, even outlying live elements of the project. It's way easier to say `registry.tfSomething.text` than accessing it `getChildAt(0).getChildAt(4).getChildAt(3).text` way, isn't it?
Registry, by being proxy, flattens the structure in communication layer, completely. And if we don't want to make our element able to reference through registry, encapsulate it a little? Then we just don't give a name our object.
Registry can also be used for other automated tasks like [group animations](http://axldns.com/docs/axl/xdef/types/display/xRoot.html#animateAllRegisteredToScreen%28%29).

Next to *add*, there are couple more API functions which check registry first, then additions node if not found. One worth attention is [`executeFromXML`](http://axldns.com/docs/axl/xdef/types/display/xRoot.html#executeFromXML%28%29).

####Animations
Framework uses [AO tweeining engine](http://axldns.com/?page_id=228), which  offers an  [API](http://axldns.com/docs/axl/utils/AO.html) very similar to other market solutions like GreenSock TweenLite, Gtween or Micro Tween. AXLX is designed to make every displayable object as easy to animate as possible. For optimization purpose, all animations are set to be stopped automatically when object is removed from stage.

#####meta variables, keywords
In general, tween definition are to be kept as  *meta* object variables. These are expected to be arrays of arguments for method [animate function](http://axldns.com/docs/axl/utils/AO.html#animate%28%29) (excluding first argument, which is passed internally).


	<div name='a' meta='{"addedToStage":[0.3,{"x":10}]}'/>
*The shortest example of meta defined animation. Tweens object from whichever position to x 10 in 0.3sec every time object is added to stage.*
	
One variable can contain more than one animation definition at the time. They shall be grouped in an array. Adding break lines for readability is allowed.

    <div name='a' meta='{
    	"addedToStage":[
    		[0.3,{"x":10}],
    		[0.6,{"y":20}],
    		[0.4,{"scaleX":3,"scaleY":3,"delay":1}]
    	]
    }'/>
There are certain meta keywords for which animation definition is automatically recognized and triggered without any manual calls. 
These are: 

 - `addedToStage` (every time object is added to stage)
 - `addChild`, `addChildAt` (every time object is added to any [ixDisplayContainer implementor](http://axldns.com/docs/axl/xdef/interfaces/ixDisplayContainer.html)
 -  `removeChild`, `removeChildAt` (when object is about to remove, actual removal can be automatically delayed by on remove animations). Even if object has on remove animation defined, it can still be removed from display list instantly (without animation) if any of his ancestors are removed.

#####meta variables, non keywords
Another way to animate objects is defining custom variables inside meta their object and triggering these from API, on demand, anytime during runtime. Two top level functions to use in this case are: 

 - [`animateAllRegisteredToScreen`](http://axldns.com/docs/axl/xdef/types/display/xRoot.html#animateAllRegisteredToScreen%28%29)
   for group animations (whole registry is scanned for objects
   containing that meta variable, every object matching it is animated)
 - [`singleAnimByMetaName`](http://axldns.com/docs/axl/xdef/types/display/xRoot.html#singleAnimByMetaName%28%29) for animating specific object defined by it's name or reference
 Non-keywords animations are good for corresponding with states in your application.

		<btn name='submit' code='animateAllRegisteredToScreen("STATE_SUBMITTED")' />

#####ui controller's animations
Another type of animations available in the framework are the ones tied to pre-defined UI components. For optimization purposes, there's limited access to it (no direct callbacks, no sequencing), but most important things can be set up

| implementors| animation related property|
| ------------- |-------------	|
| `<carouselSelectable>` | [movementSpeed](http://axldns.com/docs/axl/xdef/types/display/xCarouselSelectable.html#movementSpeed), [easingType](http://axldns.com/docs/axl/xdef/types/display/xCarouselSelectable.html#easingType), [onMovementComplete](http://axldns.com/docs/axl/xdef/types/display/xCarouselSelectable.html#onMovementComplete) |
| `<msk>`, `<scrollBar>` | controller.[omitDraggingAnimation](http://axldns.com/docs/axl/ui/controllers/BoundBox.html#omitDraggingAnimation), controller.[animationTime](http://axldns.com/docs/axl/ui/controllers/BoundBox.html#animationTime), controller.[easing](http://axldns.com/docs/axl/ui/controllers/BoundBox.html#easing),

#####manual scripts
If you prefer to use tweening engine other, rough way, it's main `animate` function is exposed in top level API, other are available by accessing full package to it (*axl.utils.AO*). You can also include any other tweening engine to your project and bring it's  API to top level by defining it in your root class.

#####Externalized animations
When dealing with complex timeline animations, proper art-work with shape morphing, tweening filters, character's body animation and other frame by frame sequences scripting can become useless or make the effort unreasonable. Quickly load exported animations and mock-ups as lightweight swfs with `<swf>` tag and control it's playback via [API](http://axldns.com/docs/axl/xdef/types/display/xSwf.html). It's available to script these swfs too (access it's public methods, properties, instances).
####Network communication
For your back-end server communication is advised to build a proper API in your project. However there are two main classes which are used all over the framework for two different aspect of connectivity.
`axl.utils.Ldr` - for loading assets, resources, data feeds etc
`alx.utils.ConnectPHP` - for making POST and GET requests.
You can use this classes to build your API solution quick or be creative with current solutions (meta.post, meta.url, meta.js).

###Working with it
It's highly recommended to use [AxlLoader](https://github.com/axldns/AxlLoader) application for your projects.
It has built in development tools such as [display list editor](http://axldns.com/?page_id=98) which allows you to manipulate objects on screen easily, [stand alone console](http://axldns.com/?page_id=11) with command line and IDE style code completion, to view logs, script your project, see contents of your registry etc., and moreover - reload takes less than quarter of the second, which comparing to closing and opening or even worse: re-compiling project to see changes done to XML is a thunderbolt!
