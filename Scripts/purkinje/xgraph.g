//genesis
//
// $ProjectVersion: Release2-2.11 $
// 
// $Id: xgraph.g,v 1.8 2006/02/22 05:56:56 svitak Exp $
//

//////////////////////////////////////////////////////////////////////////////
//'
//' Purkinje tutorial
//'
//' (C) 1998-2002 BBF-UIA
//' (C) 2005-2006 UTHSCSA
//'
//' functional ideas ... Erik De Schutter, erik@tnb.ua.ac.be
//' genesis coding ..... Hugo Cornelis, hugo.cornelis@gmail.com
//'
//' general feedback ... Reinoud Maex, Erik De Schutter, Dave Beeman, Volker Steuber, Dieter Jaeger, James Bower
//'
//////////////////////////////////////////////////////////////////////////////


// xgraph.g : xgraph functionality

int include_xgraph

if ( {include_xgraph} == 0 )

	include_xgraph = 1


extern XGraphNextColor
extern XGraphPlotCompartment
extern XGraphPlotTitle
extern XGraphReset
extern XGraphSetBoundaries


include xcell_name_requester.g


//v default color for plots

int iDefaultPlotColor = 38

//v bool for communication between XGraphPlotCompartment and others

int bXGraphPlotCompartmentResult = 0

//v normal path for xcell script

str cbXCell

//v number of graphs created so far

int iCreatedGraphs = 0


///
/// SH:	XGraphCBAddPlot
///
/// PA:	path..:	path to the graph.
///	comp..:	path to the clicked compartment
///
/// DE:	Callback to add compartment to graph
///

function XGraphCBAddPlot(path,comp)

str path

str comp

	//- allocate next color

	XGraphNextColor {path}

	//! the field cNextColor should be considered private,
	//! but read the comments below to understand why I had to
	//! read it as if it is public.
	//!
	//! With this public read it becomes more difficult to decide if the
	//! graph should do a reset (and skipping back to the default color)
	//! Modularity with genesis scripts can be tough...

	//- get allocated color

	int color = {getfield {path}/graph cNextColor}

	//! genesis callfunc cannot handle strings nor can it handle ints
	//! so the return value gets lost for the if statement

	//- get name of electrode

	str xcOutputSource = {getfield /xcell outputSource}

	str outputValue = {getfield {path} outputValue}

	str outputFlags = {getfield {path} outputFlags}

	str electrode = {XGraphPlotTitle \
				{comp} \
				{xcOutputSource} \
				{outputValue} \
				{outputFlags}}

	//- if the electrode exists

	if ( {exists /electrodes/draw/{electrode}} )

		//- give diagnostics

		echo {electrode}" is already a recording site"

	//- else

	else
		//- add plot for clicked compartment

		XGraphPlotCompartment {path} /Purkinje {comp} {color}

		if ( {getglobal bXGraphPlotCompartmentResult} )

			//- add electrode for the compartment

			XCellAddElectrode {comp} {electrode} {color}
		end
	end
end


///
/// SH:	XGraphPlotColor
///
/// PA:	path..:	path to the graph.
///
/// RE:	color for current plot
///
/// DE:	Give color for current plot
///

function XGraphPlotColor(path)

str path

	//- get next color

	int color = {getfield {path}/graph cNextColor}

	//- modulo 64 to get a legal value

	color = {color} % 64

	//- return result

	return {color}
end


///
/// SH:	XGraphNextColor
///
/// PA:	path..:	path to the graph.
///
/// RE:	color for current plot
///
/// DE:	Give color for next plot
///

function XGraphNextColor(path)

str path

	//- get next available color

	int color = {getfield {path}/graph cNextColor}

	//- modulo 64 to get a legal value

	color = {color + 19} % 64

	//- increment the color count

	setfield {path}/graph cNextColor {color}

	//- return result

	return {color}
end


///
/// SH:	XGraphPlotTitle
///
/// PA:	comp..:	compartment to be plotted
///	source:	registered output source
///	value.:	registered output value
///	flags.:	registered output flags
///
/// RE:	title for a plot
///
/// DE:	Give title for a plot for given parameters
///

function XGraphPlotTitle(comp,source,value,flags)

str comp
str source
str value
int flags

	//- get tail of compartment

	str compTail = {getpath {comp} -tail}

	//- default plot title is without index

	str plotTitle = {compTail}

	//- default index is none

	str index = ""

	//- find beginning of index

	int iBegin = {findchar {compTail} "["}

	//- if compartment has an index

	if (iBegin != -1)

		//- get index from registered compartement

		index = {substring \
				{compTail} \
				{iBegin + 1} \
				{{findchar {compTail} "]"} - 1}}

		//- set title for plot

		plotTitle = {substring {compTail} 0 {iBegin - 1}} \
				@ "_" \
				@ {index}
	end

	//- if output source is given

	if (source != "")

		//- if first char of output source is '/'

		if ({substring {source} 0 0} == "/")

			//- add output source minus '/' to plot title

			plotTitle = {plotTitle} \
					@ "_" \
					@ {substring {source} 1}

		//- else

		else
			//- add output source to plot title

			plotTitle = {{plotTitle} @ "_" @ {source}}
		end
					
	end

	// return plot title with added value

	return {plotTitle} @ "_" @ {value}
end


///
/// SH:	XGraphNextPlotMode
///
/// PA:	path..:	path to the graph.
///	mode..:	next plotting mode
///
/// RE:	1 if mode is changed
///	0 if mode is same
///
/// DE:	Notify graph of switched output units.
///	{mode} is one of (Gk,Ik,E,Vm,Ca,E).
///	Updates warning info in the xcell name requester.
///

function XGraphNextPlotMode(path,mode)

str path
str mode

	//v result of function

	int bResult

	str requestername = {getfield {path} requestername}

	//- if registered output value is different from given mode

	if ({mode} != {getfield {path} outputValue})

		//- set field for warning info widget

		XCellNameRequesterSetWarning {requestername} "Adding plots will remove all current plots"

		//- set result : mode is changed

		bResult = 1

	//- else

	else
		//- erase field for warning info widget

		XCellNameRequesterSetWarning {requestername} ""

		//- set result : mode is same

		bResult = 0
	end

	//- return result

	return {bResult}
end


///
/// SH:	XGraphPlotCompartment
///
/// PA:	path..:	path to the graph.
///	solver:	path with solver
///	comp..:	compartment to be plotted
///	color.:	color for new plot
///
/// RE:	1 if successfull
///	0 if failed
///
/// DE:	Add a plot for the given compartment, reset the simulation
///	The registered xcell output parameters are considered for setting up
///	the message to the graph.
///

function XGraphPlotCompartment(path,solver,comp,color)

str path
str solver
str comp
int color

	//- set default result : success

	int bResult = 1

	//- get the registered xcell output source

	str xcOutputSource = {getfield /xcell outputSource}

	str xcOutputFlags = {getfield /xcell outputFlags}

	str outputValue = {getfield {path} outputValue}

	str outputFlags = {getfield {path} outputFlags}

	//- if this graph has a fixed output source

	str outputSource = {getfield {path} outputSource}

	if ({outputSource} != "-1")

		//- use it instead of the output source of the xcell

		xcOutputSource = {outputSource}

	end

	//- get tail of compartment

	str compTail = {getpath {comp} -tail}

	//- get a plot title

	str plotTitle = {XGraphPlotTitle \
				{comp} \
				{xcOutputSource} \
				{outputValue} \
				{outputFlags}}

	//- if the recording already exists

	if ({exists {path}/graph/{plotTitle}})

		echo "Adding plot "{plotTitle}" failed, it already exists"

		//- set result : failed

		bResult = 0

	//- else

	//- if flags say compartmental output

	elif (outputFlags == 1)

		//- if the specified element exists

		if ( {exists {comp} {outputValue}} )

			//- give an informational message

			echo "Adding plot for "{comp}", " \
				"source is '(compartment)', " \
				"value is '"{outputValue}"'."

			//- add message from solver to graph

			addmsg {solver}/solve {path}/graph \
				PLOT \
					{findsolvefield \
						{solver}/solve \
						{comp} \
						{outputValue}} \
					*{plotTitle} \
					*{color}

			//- set the status bar

			setfield {path}/status \
				label {"Added output " @ {plotTitle}}

		//- else

		else
			//- give an informational message

			echo "No plot for "{comp}", " \
				"source is '(compartment)', " \
				"value is '"{outputValue}"'."
			echo "The element or field does not exist."

			//- set the status bar

			setfield {path}/status \
				label {"The output " @ {plotTitle} @ " does not exist."}

			//- set result

			bResult = 0
		end

	//- else if flags say spiny Vm output

	elif (outputFlags == 4)

		//- get the spine that gives messages to the element

		str spine = {getmsg {comp} -outgoing -destination 7}

		//- get tail of spine

		str spineTail = {getpath {spine} -tail}

		//- if we are handling a spine

		if ( {strncmp {spineTail} "spine" 5} == 0 )

			//- default index is zero

			source = "head[0]"

			//- if an index is available

			if ( {strlen {spineTail}} != 5 )

				//- get index of synapse

				int synapseIndex \
					= {substring \
						{spineTail} \
						6 \
						{{strlen {spineTail}} - 1}}

				//- make source string with index

				source = "head[" @ {synapseIndex} @ "]"
			end

			//- give an informational message

			echo "Adding plot for "{comp}", " \
				"source is '"{source}"', " \
				"value is '"{outputValue}"'."

			//- add message from solver to graph

			addmsg {solver}/solve {path}/graph \
				PLOT \
					{findsolvefield \
						{solver}/solve \
						{solver}/{source} \
						{outputValue}} \
					*{plotTitle} \
					*{color}

			//- set the status bar

			setfield {path}/status \
				label {"Added output " @ {plotTitle}}

		//- else inform the user

		else
			//- give an informational message

			echo "No plot for "{comp}", " \
				"source is '"{xcOutputSource}"', " \
				"value is '"{outputValue}"'."
			echo "The element or field does not exist."

			//- set the status bar

			setfield {path}/status \
				label {"The output " @ {plotTitle} @ " does not exist."}

			//- set result

			bResult = 0
		end

	//- else if flags say excitatory channel output

	elif (outputFlags == 2 && xcOutputFlags == 3)

		//- get the spine that gives messages to the element

		str spine = {getmsg {comp} -outgoing -destination 7}

		//- get tail of spine

		str spineTail = {getpath {spine} -tail}

		//- get head of spine for use with solver's flat space

		str spineHead = {getpath {spine} -head}

		//- if we are handling a spine

		if ( {strncmp {spineTail} "spine" 5} == 0 )

			//- default index is zero

			str source = "head[0]/par"

			//- if an index is available

			if ( {strlen {spineTail}} != 5 )

				//- get index of synapse

				int synapseIndex \
					= {substring \
						{spineTail} \
						6 \
						{{strlen {spineTail}} - 1}}

				//- make source string with index

				source = "head[" @ {synapseIndex} @ "]/par"
			end

			//- give an informational message

			echo "Adding plot for "{comp}", " \
				"source is '"{spineHead}{source}"', " \
				"value is '"{outputValue}"'."

			//- add message from solver to graph

			addmsg {solver}/solve {path}/graph \
				PLOT \
					{findsolvefield \
						{solver}/solve \
						{spineHead}{source} \
						{outputValue}} \
					*{plotTitle} \
					*{color}

			//- set the status bar

			setfield {path}/status \
				label {"Added output " @ {plotTitle}}

		//- else if we can find a climbing fiber input

		elif ( {exists {comp}/climb} )

			//- give an informational message

			echo "Adding plot for "{comp}", " \
				"source is 'climb', " \
				"value is '"{outputValue}"'."

			//- add message from solver to graph

			addmsg {solver}/solve {path}/graph \
				PLOT \
					{findsolvefield \
						{solver}/solve \
						{comp}/climb \
						{outputValue}} \
					*{plotTitle} \
					*{color}

			//- set the status bar

			setfield {path}/status \
				label {"Added output " @ {plotTitle}}

		//- else inform the user

		else
			//- give an informational message

			echo "No plot for "{comp}", " \
				"source is '"{xcOutputSource}"', " \
				"value is '"{outputValue}"'."
			echo "The element or field does not exist."

			//- set the status bar

			setfield {path}/status \
				label {"The output " @ {plotTitle} @ " does not exist."}

			//- set result

			bResult = 0
		end

	//- else if flags say inhibitory channel output

	elif (outputFlags == 2 && xcOutputFlags == 7)

		//- if we can find a stellate cell

		if ( {exists {comp}/stell} )

			//- give an informational message

			echo "Adding plot for "{comp}", " \
				"source is 'stell', " \
				"value is '"{outputValue}"'."

			//- add message from solver to graph

			addmsg {solver}/solve {path}/graph \
				PLOT \
					{findsolvefield \
						{solver}/solve \
						{comp}/stell \
						{outputValue}} \
					*{plotTitle} \
					*{color}

			//- set the status bar

			setfield {path}/status \
				label {"Added output " @ {plotTitle}}

		//- else if we can find a stellate 1 cell

		elif ( {exists {comp}/stell1} )

			//- give an informational message

			echo "Adding plot for "{comp}", " \
				"source is 'stell1', " \
				"value is '"{outputValue}"'."

			//- add message from solver to graph

			addmsg {solver}/solve {path}/graph \
				PLOT \
					{findsolvefield \
						{solver}/solve \
						{comp}/stell1 \
						{outputValue}} \
					*{plotTitle} \
					*{color}

			//- set the status bar

			setfield {path}/status \
				label {"Added output " @ {plotTitle}}

		//- else if we can find a basket cell

		elif ( {exists {comp}/basket} )

			//- give an informational message

			echo "Adding plot for "{comp}", " \
				"source is 'basket', " \
				"value is '"{outputValue}"'."

			//- add message from solver to graph

			addmsg {solver}/solve {path}/graph \
				PLOT \
					{findsolvefield \
						{solver}/solve \
						{comp}/basket \
						{outputValue}} \
					*{plotTitle} \
					*{color}

			//- set the status bar

			setfield {path}/status \
				label {"Added output " @ {plotTitle}}

		//- else inform the user

		else
			//- give an informational message

			echo "No plot for "{comp}", " \
				"source is '"{xcOutputSource}"', " \
				"value is '"{outputValue}"'."
			echo "The element or field does not exist."

			//- set the status bar

			setfield {path}/status \
				label {"The output " @ {plotTitle} @ " does not exist."}

			//- set result

			bResult = 0
		end

	//- else we have 'normal' compartmental output

	else

		//- if the specified element exists

		if ( {exists {comp}/{xcOutputSource} {outputValue}} )

			//- give an informational message

			echo "Adding plot for "{comp}", " \
				"source is '"{xcOutputSource}"', " \
				"value is '"{outputValue}"'."

			//- add message from solver to graph

			addmsg {solver}/solve {path}/graph \
				PLOT \
					{findsolvefield \
						{solver}/solve \
						{comp}/{xcOutputSource} \
						{outputValue}} \
					*{plotTitle} \
					*{color}

			//- set the status bar

			setfield {path}/status \
				label {"Added output " @ {plotTitle}}

		//- else

		else
			//- give an informational message

			echo "No plot for "{comp}", " \
				"source is '"{xcOutputSource}"', " \
				"value is '"{outputValue}"'."
			echo "The element or field does not exist."

			//- set the status bar

			setfield {path}/status \
				label {"The output " @ {plotTitle} @ " does not exist."}

			//- set result

			bResult = 0
		end
	end

	//- if adding plot was successfull

	if (bResult)

		//- reset added plot (makes it visible)

		call {path}/graph/{plotTitle} RESET
	end

	//- set global result

	bXGraphPlotCompartmentResult = {bResult}

	//- return result

	return {bResult}
end


///
/// SH:	XGraphRemoveCompartment
///
/// PA:	path..:	path with solver
///	comp..:	compartment to be removed from plot list
///
/// DE:	Remove the plot for the given compartment
///

function XGraphRemoveCompartment(path,comp)

str path
str comp

	//- get the registered xcell output source

	str xcOutputSource = {getfield /xcell outputSource}

	str outputValue = {getfield {path} outputValue}

	str outputFlags = {getfield {path} outputFlags}

	//- get a plot title

	str plotTitle = {XGraphPlotTitle \
				{comp} \
				{xcOutputSource} \
				{outputValue} \
				{outputFlags}}

	//- if the plot exists

	if ( {exists {path}/graph/{plotTitle}} )

		//- give diagnostics

		echo "Removing plot "{plotTitle}

		//- remove the plot

		delete {path}/graph/{plotTitle}

		//- reset the graph

		call {path}/graph RESET

	//- else

	else
		//- give diagnostics

		echo "No plot named "{plotTitle}
	end
end


///
/// SH: XGraphClear
///
/// PA: path..:	parent element to clear all graphs for
///
/// DE:	clear all graphs within the given element tree
///

function XGraphClear(path)

str path

	//- give diagnostics

	echo {"Removing all plots from " @ {path}}

	//v old status of overlay

	int overlayOld

	//- loop over all plots in the given tree

	str plot

	foreach plot ( {el {path}/##[][TYPE=xplot]} )

		//- delete the plot

		delete {plot}
	end

	//- loop over all graphs in the given tree

	str graph

	foreach graph ( {el {path}/##[][TYPE=xgraph]} )

		//- push the element

		pushe {graph}

		//- remember status of overlay field

		overlayOld = {getfield . overlay}

		//- unset overlay field

		setfield . overlay 0

		//echo RESET for {el .} with overlay {getfield . overlay}

		//- reset the graph

		call . RESET

		//- reset overlay field to previous state

		setfield . overlay {overlayOld}

		//- pop previous current element

		pope
	end

	//- set the status bar

	str unit = {getfield {path} unit}

	if ({unit} == "Ik" \
		|| {unit} == "Gk" \
		|| {unit} == "Ek")

		setfield {path}/status \
			label {"Cleared.  To add new plots, select a channel as output variable."}
	else
		setfield {path}/status \
			label {"Cleared.  Click on the dendrite to add new plots."}
	end	
end


///
/// SH:	XGraphResetAxes
///
/// PA:	path..:	path to the graph.
///
/// DE:	Reset the axes to registered values if any
///
/// NO:	This functions is obsoleted because of normalized boundary
///	handling
///

function XGraphResetAxes(path)

str path

	//- get relevant output parameters

	str xcOutputSource = {getfield /xcell outputSource}

	str xcOutputFlags = {getfield /xcell outputFlags}

	str outputSource = {getfield {path} outputSource}

	str outputValue = {getfield {path} outputValue}

	str outputFlags = {getfield {path} outputFlags}

	//- if this graph has a fixed output source

	if ({outputSource} != "-1")

		//- use it instead of the output source of the xcell

		xcOutputSource = {outputSource}

	//- else the graph is related to channels

	else
		//- if the graph and the xcell are operating in a different mode

		if ({outputFlags} != {xcOutputFlags})

			//- have to do some thing,
			//- so lets take the fast sodium channel as source

			xcOutputSource = "NaF"

		//- else

		else

			//- inherit the source from the xcell
		end
	end

	//- get name for boundary element

	str bound = {BoundElementName \
			{xcOutputSource} \
			{outputValue} \
			{getglobal iChanMode}}

	//- set boundaries

	XGraphSetBoundaries {path} {bound}
end


///
/// SH:	XGraphCancelScales
///
/// PA:	path..:	path to the graph.
///
/// DE:	Hide the set scales window
///

function XGraphCancelScales(path)

str path

	//- hide the set scales window

	xhide {path}/setscales
end


///
/// SH:	XGraphSetScales
///
/// PA:	path..:	path to the graph.
///
/// DE:	Set the scales as in the set scales window
///

function XGraphSetScales(path)

str path

	//- set x min

	setfield {path}/graph \
		xmin {getfield {path}/setscales/xmin value}

	//- set x max

	setfield {path}/graph \
		xmax {getfield {path}/setscales/xmax value}

	//- set y min

	setfield {path}/graph \
		ymin {getfield {path}/setscales/ymin value}

	//- set y max

	setfield {path}/graph \
		ymax {getfield {path}/setscales/ymax value}

	//- hide the set scales window

	xhide {path}/setscales
end


///
/// SH:	XGraphUpdateScales
///
/// PA:	path..:	path to the graph.
///
/// DE:	Update scales window with registered xgraph values
///	Values come from xmin, xmax, ymin and ymax fields from xgraph
///

function XGraphUpdateScales(path)

str path

	//- set x min value

	setfield {path}/setscales/xmin \
		value {getfield {path}/graph xmin}

	//- set x max value

	setfield {path}/setscales/xmax \
		value {getfield {path}/graph xmax}

	//- set y min value

	setfield {path}/setscales/ymin \
		value {getfield {path}/graph ymin}

	//- set y max value

	setfield {path}/setscales/ymax \
		value {getfield {path}/graph ymax}
end


///
/// SH:	XGraphShowScales
///
/// PA:	path..:	path to the graph.
///
/// DE:	Popup set scales window
///

function XGraphShowScales(path)

str path

	//- update values for scales window

	XGraphUpdateScales {path}

	//- pop up the scales form

	xshow {path}/setscales
end


///
/// SH:	XGraphHideAddPlot
///
/// PA:	path..:	path to the graph.
///
/// DE:	Hide the add plot window
///	Resets the xcell call back
///

function XGraphHideAddPlot(path)

str path

	//- restore field for xcell script

	setfield /xcell/draw/xcell1 \
		script {cbXCell}

	//- hide add plot window

	str requestername = {getfield {path} requestername}

	XCellNameRequesterHide {requestername}
end


///
/// SH:	XGraphSetAddPlot
///
/// PA:	path..:	path to the graph.
///	name..:	name of compartment to add plot for
///
/// DE:	Add plot for specified compartment name
///	The field and subelement to output are taken from xgraph output mode
///	If the function is successfull, the add plot window will hide.
///

function XGraphSetAddPlot(path,name)

str path

str name

	//- for empty given name

	if ( {name} == "" )

		//- just return

		return
	end

	//- if name is relative

	if ( {substring {name} 0 0} != "/" )

		//- add cell path to compartment name

		name = {{cellpath} @ "/" @ {name}}
	end

	//- get tail of string

	str tail = {getpath {name} -tail}

	//- find opening bracket

	int iOpen = {findchar {tail} "["}

	//- if name has index

	if ( iOpen != -1 )

		//- find closing bracket

		int iClose = {findchar {tail} "]"}

		//- get index from tail of name

		int iIndex = {substring {tail} {iOpen + 1} {iClose - 1}}

		//- if index count of tail is zero

		if ( iIndex == 0 )

			//- delete index of tail of name

			tail = {substring {tail} 0 {iOpen - 1}}

			//- construct new name

			name = {{getpath {name} -head} @ {tail}}
		end
	end

	//- call callback script for xcell

	XGraphCBAddPlot {path} {name}
end


///
/// SH:	XGraphShowAddPlot
///
/// PA:	path..:	path to the graph.
///
/// DE:	Popup add plot window
///	This function messes with the xcell call back script
///

function XGraphShowAddPlot(path)

str path

	//- store field for xcell script

	cbXCell = {getfield /xcell/draw/xcell1 script}

	//- set field for xcell script

	setfield /xcell/draw/xcell1 \
		script {"XGraphCBAddPlot " @ {path} @ " <v>"}

	//- pop add plot form

	str unit = {getfield {path} unit}

	str requestername = {getfield {path} requestername}

	XCellNameRequesterShow {requestername}
end


///
/// SH:	XGraphToggleOverlay
///
/// PA:	widget:	name of widget to toggle overlay for
///	state.:	new state for overlay field
///
/// DE:	Toggle the overlay field for the given widget
///

function XGraphToggleOverlay(widget,state)

str widget
str state

	//- if xoverlay element exists

	if ({exists {widget}/xoverlay})

		//- delete the xoverlay element

		delete {widget}/xoverlay
	end

	//- set the overlay field for the given widget

	setfield {widget} overlay {state}
end


///
/// SH:	XGraphCreate
///
/// PA:	unit..:	unit to display.
///
/// DE:	Creates a graph and parent from element.
///	Adds a field for allocation of colors (named cNextColor)
///	Sets the update clock to clock 8
///

function XGraphCreate(unit,outputSource,outputValue,outputFlags,outputDescription,iChannelMode)

str unit
str outputSource
str outputValue
str outputFlags
str outputDescription
int iChannelMode

	//- create the graph container if it does not exist yet

	if ( ! {exists /xgraphs} )

		create neutral /xgraphs
	end

	//- create container form

	int x1 = 500 + {iCreatedGraphs * 10}
	int y1 = 0 + {iCreatedGraphs * 10}
	int x2 = 500
	int y2 = 420

	iCreatedGraphs = {iCreatedGraphs + 1}

	create xform /xgraphs/{unit} [{x1}, {y1}, {x2}, {y2}]

	//- add field specifying the unit

	addfield /xgraphs/{unit} \
		unit -description "unit for this graph"
	setfield /xgraphs/{unit} \
		unit {unit}

	//- add field for output source

	addfield /xgraphs/{unit} \
		outputSource -description "Output source"

	setfield /xgraphs/{unit} \
		outputSource {outputSource}

	//- add field for output value

	addfield /xgraphs/{unit} \
		outputValue -description "Output value"

	setfield /xgraphs/{unit} \
		outputValue {outputValue}

	//- add field for output flags

	addfield /xgraphs/{unit} \
		outputFlags -description "Output flags"

	setfield /xgraphs/{unit} \
		outputFlags {outputFlags}

	//- add field for output description

	addfield /xgraphs/{unit} \
		outputDescription -description "Output description"

	setfield /xgraphs/{unit} \
		outputDescription {outputDescription}

	//- add field for channel mode

	addfield /xgraphs/{unit} \
		channelMode -description "Channel display mode"

	setfield /xgraphs/{unit} \
		channelMode {iChannelMode}

	//- add field for registering boundary element

	addfield /xgraphs/{unit} \
		boundElement -description "Element with display boundaries"

	//- add a field to link with an xcell name requester

	addfield /xgraphs/{unit} \
		requestername -description "xcell name requester"

	//- make the form the current element

	pushe /xgraphs/{unit}

	//- create graph within the form

	create xgraph graph \
		-xgeom 1% \
		-ygeom 2% \
		-wgeom 99% \
		-hgeom 85% \
		-title {outputDescription}

	//- set appropriate dimensions for voltage

	setfield ^ \
		xmin 0 \
		xmax {runtime / 1000} \
		ymin -0.1 \
		ymax 0.05 \
		bg white \
		XUnits "t (sec)" 

	//- add a button to clear the graph

	create xbutton clear \
		-xgeom 1% \
		-ygeom 0:graph \
		-wgeom 24% \
		-title "Clear graph" \
		-script {"XGraphClear /xgraphs/" @ {unit}}

// 	//- add a button to add a plot

// 	create xbutton addPlot \
// 		-xgeom 0:last.right \
// 		-ygeom 0:graph \
// 		-wgeom 24% \
// 		-title "Add plot" \
// 		-script {"XGraphShowAddPlot /xgraphs/" @ {unit}}

	//- add toggle for overlay

	create xtoggle overlay \
		-xgeom 0:last.right \
		-ygeom 0:graph \
		-wgeom 25% \
		-title "" \
		-script {"XGraphToggleOverlay /xgraphs/" @ {unit} @ "/graph <v>"}

	//- set on/off labels

	setfield overlay \
		offlabel "Overlay off" \
		onlabel "Overlay on"

	//- add a button to set the axes

	create xbutton scales \
		-xgeom 0:last.right \
		-ygeom 0:graph \
		-wgeom 25% \
		-title "Set scales" \
		-script {"XGraphShowScales /xgraphs/" @ {unit}}

	//- add a button to reset the axes

	create xbutton axes \
		-xgeom 0:last.right \
		-ygeom 0:graph \
		-wgeom 25% \
		-title "Reset axes" \
		-script {"XGraphResetAxes /xgraphs/" @ {unit}}

	//- create a status bar

	create xlabel status \
		-xgeom 1% \
		-wgeom 99% \
		-label "Initialized"

	//- add an initialized field for allocated colors

	addfield /xgraphs/{unit}/graph cNextColor -descr "next color to allocate"
	setfield /xgraphs/{unit}/graph cNextColor {iDefaultPlotColor}

	//- set clock to use for graph

	useclock /xgraphs/{unit}/graph 9

	//- create a form for setting scales

	create xform setscales [600,150,300,210]

	//- make it the current element

	pushe ^

	//- create label with header

	create xlabel heading \
		-label "Axes limits"

	//- create x min dialog

	create xdialog xmin \
		-title "X minimum : "

	//- create x max dialog

	create xdialog xmax \
		-title "X maximum : "

	//- create y min dialog

	create xdialog ymin \
		-title "Y minimum : "

	//- create y max dialog

	create xdialog ymax \
		-title "Y maximum : "

	//- create done button

	create xbutton done \
		-title "Done" \
		-script {"XGraphSetScales /xgraphs/" @ {unit}}

	//- create cancel button

	create xbutton cancel \
		-title "Cancel" \
		-script {"XGraphCancelScales /xgraphs/" @ {unit}}

	//- pop previous element

	pope

	//- create the form to request a compartment name

	str requestername \
		= {XCellNameRequester \
			"" \
			"Add a plot to the graph" \
			"Select a compartment from the Purkinje cell" \
			"to plot its output value in the graph," \
			"or type a compartment name below :" \
			"Compartment name to plot : " \
			{"XGraphSetAddPlot /xgraphs/" @ {unit} @ "<v>"} \
			"" \
			"Done" \
			{"XGraphHideAddPlot /xgraphs/" @ {unit}}}

	setfield /xgraphs/{unit} \
		requestername {requestername}

	//- add callback for the xcell display

	//! callback called when an electrode is added

	XCellElectrodeAddCallback \
		/xcell/draw/xcell1 \
		{"XGraphPlotCompartment_/xgraphs/" \
			@ {unit} \
			@ "_" \
			@ {cellpath}}

	//- go to previous current element

	pope

	//- reset the graph

	XGraphResetAxes /xgraphs/{unit}
end


///
/// SH:	XGraphReset
///
/// PA:	path..:	path to the graph.
///
/// DE:	Clear the graph and reset the title
///	This functions relies on an xcell form /xcell that has fields for
///	registering output source, value etc.
///

function XGraphReset(path)

str path

	//- clear the graph

	XGraphClear {path}

	//- get the registered xcell output source

	str xcOutputSource = {getfield /xcell outputSource}

	//- if output is comp. Vm

	str outputFlags = {getfield {path} outputFlags}

	if (outputFlags == 1)

		//- set title

		setfield {path}/graph \
			title "Compartmental voltage"

	//- else if output is channel with IGE

	elif (outputFlags == 2)

		//- set title

		setfield {path}/graph \
			title {xcOutputValue}

	//- else if the output is excitatory channel with IGE

	elif (outputFlags == 3)

		//- set title

		setfield {path}/graph \
			title {xcOutputValue}

	//- else if the output is spine comp. Vm

	elif (outputFlags == 4)

		//- set title

		setfield {path}/graph \
			title {xcOutputSource}" spine "{xcOutputValue}

	//- else if the output is nernst E

	elif (outputFlags == 5)

		//- set title

		setfield {path}/graph \
			title {xcOutputSource}" nernst potential"

	//- else if the output is Calcium concen Ca

	elif (outputFlags == 6)

		//- set title

		setfield {path}/graph \
			title {xcOutputSource}" Calcium concentration"

	//- else if the output is inhibitory channel with IGE

	elif (outputFlags == 7)

		//- set title

		setfield {path}/graph \
			title {outputValue}

	end

	//- set new axes

	//- get name for boundary element

	str bound = {BoundElementName \
			{getfield /xcell outputSource} \
			{getfield {path} outputValue} \
			{getglobal iChanMode}}

	callfunc XGraphSetBoundaries {path} {bound}

	//- register next output mode

	XGraphNextPlotMode {path} {outputValue}
end


///
/// SH:	XGraphSetBoundaries
///
/// PA:	path..:	path to the graph.
///	bound.:	boundary element
///
/// RE:	Success of operation
///
/// DE:	Set boundaries for the xgraph
///

function XGraphSetBoundaries(path,bound)

str path

str bound

	//v result var

	int bResult

	//- if the boundary element exists

	if ( {exists {bound}} )

		//- give diagnostics

		echo "Setting xgraph boundaries from "{bound}

		//- set the axes values

		setfield {path}/graph \
			xmin 0 \
			xmax {runtime / 1000} \
			ymin {getfield {bound} xgraphmin} \
			ymax {getfield {bound} xgraphmax}

		//- update scales in widgets

		XGraphUpdateScales {path}

		//- set result : ok

		bResult = 1

	//- else

	else
		//- set result : failure

		bResult = 0
	end

	//- return result

	return {bResult}
end


///
/// SH:	XGraphSwitchChanMode
///
/// PA:	state.:	0 for absolute chanmode (chanmode 4)
///		1 for normalized chanmode (chanmode 5)
///
/// DE:	Switch between normalized and absolute channel mode
///	Sets the min/max color values for the xgraph display
///

function XGraphSwitchChanMode(state)

int state

	//- get name for boundary element

	str bound = {BoundElementName \
			{getfield /xcell outputSource} \
			{getfield {path} outputValue} \
			{getglobal iChanMode}}

	//- set new boundaries from element

	callfunc XGraphSetBoundaries {path} {bound}

	//- set field for boundaries

	setfield {path} \
		boundElement {bound}
end


end


