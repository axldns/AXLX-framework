**AXLX Framework**
--------------

AXLX is an Open Source framework for building projects based on dynamicaly loaded XML files. 
Unlike flex framework, where XML (MXML) files are used for compilation, in AXLX XMLs are used for building flash content after compilation.
XML definitions can define layouts, complex interactivity, logic, data processing and even more sophisticated tasks.

It is an answer to constant need of fast updates to live projects. Since updating XML does not require compilation/depoloyment afterwards, amends and bug fixes can be applied in an eye blink. 

It actually allows to build, develop and update projects without IDE. All it needs is a swf file with AXLX embedded in or a stub loading AXLX as a RSL. This can move weight of not necessarily developer updates to other member of the team (copywriters, graphic designers). 
Since the most significant part is externalized to XML, using AXLX framework have positive impact on source code controll.

You can build your content completely on AXLX framework or just make it complementary part of larger projects. 
It is very easy to extend it by building your API on top of it.

Dedicated software to work with AXLX projects is AxlLoader. It allows to re-load projects quickly instead of constantly re-compiling them or re-opening to view changes made to XML definitions.

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
When you look into console, you'll see a substantial log - the result of initial flow. Flow is quite complex but there's not much to worry, all it does is finding out where to load config from, loads it an builds content.

> The easiest way to find out what was the location the config file was searched for is to examinate log for "xml" occurrences.

By default XML file name has to have the same name as the flash file. 
By default, it checks ONE DIRECTORY UP relative to where your swf is placed (in web projects). 
It applies to content run locally and to swf files put on server. This can be controlled by various settings, see [independent server directories](http://axldns.com/docs/axl/xdef/types/display/xRoot.html#appRemote), [file name dictates sub-directories](http://axldns.com/docs/axl/xdef/xLauncher.html#appReomoteSPLITfilename), [hardcoding config filename](http://axldns.com/docs/axl/xdef/types/display/xRoot.html#fileName), [loading AXLX from stub](http://axldns.com/docs/axl/xdef/types/display/xRoot.html#xRoot()).
For mobile projects, default location it's File.applicationStorageDirectory.

In our case it's going to be "Example/bin-debug/../Example.xml". That means your XML definition should be placed in root of your project folder (outside "src").

Ok, config not found (SKIPPED). Let's feed it. Let's create an empty Example.xml and debug it again.

Blue bar still says "Invalid config file", but this time inside log we can see that file was LOADED (instead of skipped like last time). It's also printed out that "Config isn't valid XML file". Lets create valid but empty XML file. 

###XML structure

    <axlx>
    	<root/>
    </axlx>
   *Minimal valid XML definiton of the config file*
If we paste above code to our Example.xml created before and debug project again, blue error bar is finally gone, but swf is still blank. That's a good sign. We can start building content.
####Nodes
There are two kind of nodes available: *Grand Nodes* and *Child Nodes*.
Only Grand Nodes can be children of top XML node. Child Nodes can only be children of Grand Nodes in general. 
#####Grand nodes
There are three Grand Nodes interpreted from the XML definiton:

 - `<root/>` - represents your root display object (instance of Example class in our project). Children of this node are processed (loaded, instantiated, added to the display list) right after config file is loaded and project settings are read.
 - `<project/>`- sets up project / library related properties such as
   debug mode, time-out for assets loading, timeouts for POST and GET requests etc. Parsed right after config file is loaded and read, can be referenced later.   
 - `<additions/>` - container for Child Nodes that are not
   instantiated automatically. Children of this node can be turned from
   XML nodes to valid ActionScript objejects, processed and added to
   DisplayList or stay reference-able for further interactivity /
   processing. Before instantiation they take up no more space in memory than XML nodes.

#####Child Nodes
Child Nodes represent particular data types. Each one (once instantiated) is a particular class instance. These are classes defined by AXLX framwork and can be divided on 2 groups:  [12 displayable classes](http://axldns.com/docs/axl/xdef/types/display/package-detail.html) and [4 functional classes](http://axldns.com/docs/axl/xdef/types/package-detail.html).

######Displayable nodes

| Node | Description |
| ------------- |-------------	|
| `<div>`    | [Display object container](http://google.com) |
| `<img>`    | Bitmap / image |
|`<txt>` | Text field    |
| `<btn>`   | Button |
|`<msk>`  | Interactive container with mask and bounding box |
| `<swf>` | Container to control loaded swf timeline |
| `<scrollBar>` | Interactive container with bounding box, multi purpose, plug-able to `<msk>` |
| `<carousel>`    | interactive container, auto children distribution, infinite horizontal / vertical scroll |
| `<carouselSelectable>`     | same as `<carousel>` but provides animated scroll from object to object and  has "center" object concept|
| `<form>`     | container that validates input type text fields against regular expressions they carry, exposes form object based on these |
| `<vod>`     | Video on demand player (regular flash video, stage video not supported). |


| col 2 is      | centered      |
| zebra stripes | are neat      |
| col 3 is      | right-aligned |
| col 2 is      | centered      |
| zebra stripes | are neat      |


f it's a descendant of DisplayObjectContainer, XML children of that node representing other DisplayObject descendants  will automatically become children of that DisplayObject Container.
