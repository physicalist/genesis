//genesis
//
// $ProjectVersion: Release2-2.11 $
// 
// $Id: xcell.g,v 1.8 2006/02/22 05:56:56 svitak Exp $
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


// xcell.g : xcell functionality

int include_xcell

if ( {include_xcell} == 0 )

	include_xcell = 1


//////////////////////////////////////////////////////////////////////////////
//o
//o xcell library : future enhancements
//o -----------------------------------
//o
//o The main major idea for future enhancement is to have a library for xcell
//o	displays where each display can have its own output mode.
//o
//o
//o 1. Requirements
//o ---------------
//o
//o Because the number of possible outputs is finite, the idea is to mirror 
//o	the output mode of an xcell display in its path.
//o
//o	e.g.: 
//o		/xcells/Vm............:	gives Vm output
//o		/xcells/CaP/Ik........:	gives Ik for CaP channel
//o		/xcells/Cap/Gk........:	gives Gk for CaP channel
//o		/xcells/CaP/Ek........:	gives Ek for CaP channel
//o		.	.	.	.	.	.
//o		.	.	.	.	.	.
//o
//o The xcell displays are created only when they are needed. This gives less
//o	overhead at setup time (mainly because the messages don't have to be 
//o	created) and at run time (because each visible xcell display doesn't
//o	have to go through an enormous amount of messages). Opportunity must
//o	be given to delete/hide xcells. If necessary / possible the messages
//o	should be deleted to increase performance. When an xcell display is 
//o	hidden, it should be disabled such that it doesn't receive any PROCESS
//o	actions anymore.
//o
//o Graphs plotting the values associated with particular compartments are 
//o	different in there path hierarchy : One graph is created for each of
//o	Ik,Gk,Ek and for Vm and [Ca2+]. Perhaps this can also give a nicer 
//o	name to the different plots (e.g. b1s14_16 instead of
//o	b1s14_16_Ca_pool_Ca etc).
//o	The link between the xcell displays and the plotting graphs is as
//o	follows : if a click occures inside an xcell display, we ask the user
//o	first which output parameter he wants, this defaults to the xcell's 
//o	display output parameter.
//o
//o	Besides this we still have to provide a possibility to have a plot
//o	without any xcell display where we can type the compartment name to
//o	plot.
//o	As with xcell displays, opportunity must be given to delete graphs. 
//o	If possible any messages should be deleted to increase performance.
//o
//o The config file/module should be able to reflect a particular situation.
//o	This situation should then be created at initialization. To specify
//o	this situation an enumeration of xcell displays and xgraphs is given
//o	with their output parameters. 
//o
//o	e.g. :
//o
//o		.	.	.
//o		.	.	.
//o		xCellElements 1600	(old values)
//o		XCell Vm		(creates /xcells/Vm)
//o		XCell CaP Ik		(creates /xcells/CaP/Ik)
//o		XGraph CaP Ek		(creates /xgraphs/CaP/Ek)
//o		XGraph Vm soma[0]	(creates /xgraphs/Vm plotting soma Vm)
//o		.	.	.
//o		.	.	.
//o
//o	In the long run it should be possible to save such a configuration 
//o	from the tutorial itself (without having to run the configuration 
//o	script). Perhaps a seperate file for this configuration from which the
//o	name is given in the config file is better. This lets one choose 
//o	between different output modes easily by changing the config file.
//o
//o At this moment I don't see any interference with the boundaries settings,
//o	but I could be wrong on that.
//o
//o
//o 2. Implementation
//o -----------------
//o
//o A seperate library is needed asking for a particular output mode. Part of
//o	this is present in the actual xcell code. The same applies for asking
//o	the user for a particular compartment to plot. This code is partly 
//o	present in the xgraph code.
//o
//o
//////////////////////////////////////////////////////////////////////////////


extern XCellAddElectrodeCallback
extern XCellElectrodeAdd
extern XCellElectrodeAddCallback
extern XCellElectrodeColor
extern XCellElectrodeColorNext
extern XCellElectrodeName
extern XCellElectrodeTriggerCallbacks
extern XCellRemoveElectrode


include stack.g
include xcell_name_requester.g


//v default color for electrodes

int iXCellElectrodeDefaultColor = 38

//v bool to indicate first toggle for tabchannel has been created

int bButtonsCreated = 0

//v basename for library file of all channels

str strXCLibrary = "XCLib"

//v xcell callback

str cbXCellShowCompartment


///
/// SH:	XCellElectrodeAdd
///
/// PA:	path..:	path to the xcell widget
///	comp..:	compartname name for electrode
///
/// RE:	1 if successfull
///	0 if failed (the electrode already exists)
///
/// DE:	Associate an electrode with {comp} for registered xcell parameters
///
/// Electrode prototype is /electrodes/draw/proto {xshape}
///
/// The electrode is created within 
///	/electrodes/draw/{name}.......:	always
///	/xcell/draw/{name}............:	when electrodes visible
///					in xcell display
///

function XCellElectrodeAdd(path,comp)

str path
str comp

	//- set default result

	int bResult = 0

	//- get a name for the electrode

	str electrode = {XCellElectrodeName {comp}}

	//- get color for the electrode

	//- get allocated color

	XCellElectrodeColorNext {path}/../..

	int color = {getfield {path}/../.. cNextColor}

	//- give diagnostics

	echo {"Adding electrode for " @ {electrode}}

	//- copy the prototype electrode

	copy /electrodes/draw/proto /electrodes/draw/{electrode}

	//- set field for identification and color

	setfield ^ \
		ident "record" \
		pixcolor {color}

	//- set the translation of the electrode

	setfield ^ \
		tx {getfield {comp} x} \
		ty {getfield {comp} y} \
		tz {getfield {comp} z}

	//- if the electrodes toggle is set

	if ( {getfield /xcell/electrodes state} )

		//- copy the electrode to the xcell window

		copy ^ /xcell/draw/{electrode}
	end

	//- call the callbacks

	XCellElectrodeTriggerCallbacks {path} {comp} {color}

	//- set success

	bResult = 1

	//- return result

	return {bResult}
end


///
/// SH:	XCellElectrodeAddCallback
///
/// PA:	path..:	path to the xcell display.
///	cback.: arguments to be called by the callback.
///
/// DE: Add an callback to the xcell display.  The callback will be
/// 	called whenever new electrodes are added.  The callback is a
/// 	single string without whitespaces.  Underscores will be
/// 	replaced by spaces whenever it is called.
///

function XCellElectrodeAddCallback(path,cback)

str path
str cback

	//- push the call back on the stack

	StackPush {path}/../../stack/ {cback}
end


///
/// SH:	XCellElectrodeColor
///
/// PA:	path..:	path to the xcell.
///
/// RE:	color for current plot
///
/// DE:	Give color for current plot
///

function XCellElectrodeColor(path)

str path

	//- get next color

	int color = {getfield {path} cNextColor}

	//- modulo 64 to get a legal value

	color = {color} % 64

	//- return result

	return {color}
end


///
/// SH:	XCellElectrodeColorNext
///
/// PA:	path..:	path to the xcell.
///
/// RE:	color for current plot
///
/// DE:	Give color for next plot
///

function XCellElectrodeColorNext(path)

str path

	//- get next available color

	int color = {getfield {path} cNextColor}

	//- modulo 64 to get a legal value

	color = {color + 19} % 64

	//- increment the color count

	setfield {path} cNextColor {color}

	//- return result

	return {color}
end


///
/// SH:	XCellElectrodeName
///
/// PA:	path..:	path to the clicked compartment
///
/// RE:	name for electrode
///
/// DE:	Associate an electrode name with {path} for registered xcell parameters
///	The electrode name will have a fairly descriptive name (ie from the 
///	electrode name you can make out which field from which compartment is
///	recorded.
///

function XCellElectrodeName(path)

str path

	//- get tail of compartment

	str compTail = {getpath {path} -tail}

	//- default plot title is without index

	str result = {compTail}

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

		//- set title for electrode

		result = {substring {compTail} 0 {iBegin - 1}} \
				@ "_" \
				@ {index}
	end

	//- return electrode name

	return {result}
end


///
/// SH:	XCellElectrodeTriggerCallbacks
///
/// PA:	path..:	path to the xcell display
///	comp..:	path to compartment
///	color.:	color of electrode of the compartment
///
/// DE:	Call all callbacks after an electrode has been added.
///

function XCellElectrodeTriggerCallbacks(path,comp,color)

str path
str comp
str color

	//- get path to the stack

	str callbacks = {StackElementValues {path}/../../stack/}

	//- loop over all callbacks

	str callback

	foreach callback ({arglist {callbacks}})

		//- replace underscores

		int pos = {findchar {callback} "_"}

		while ({pos} != -1)

			str head = {substring {callback} 0 {{pos} - 1}}

			str tail = {substring {callback} {{pos} + 1}}

			callback = {{head} @ " " @ {tail}}

			pos = {findchar {callback} "_"}
			
		end

		echo {"Calling electrode callback (" @ {callback} @ ")"}

		callfunc {arglist {callback}} {comp} {color}
	end
end


///
/// SH:	XCellAddElectrode
///
/// PA:	path..:	path to the clicked compartment
///	name..:	name for electrode
///	color.:	color for the electrode
///
/// RE:	1 if successfull
///	0 if failed (the electrode already exists)
///
/// DE:	Associate an electrode with {path} for registered xcell parameters
///
/// Electrode prototype is /electrodes/draw/proto {xshape}
///
/// The electrode is created within 
///	/electrodes/draw/{name}.......:	always
///	/xcell/draw/{name}............:	when electrodes visible
///					in xcell display
///

function XCellAddElectrode(path,name,color)

str path
str name
int color

	//- set default result

	int bResult = 0

	//- give diagnostics

	echo "Adding electrode for "{name}

	//- copy the prototype electrode

	copy /electrodes/draw/proto /electrodes/draw/{name}

	//- set field for identification and color

	setfield ^ \
		ident "record" \
		pixcolor {color}

	//- set the translation of the electrode

	setfield ^ \
		tx {getfield {path} x} \
		ty {getfield {path} y} \
		tz {getfield {path} z}

	//- if the electrodes toggle is set

	if ( {getfield /xcell/electrodes state} )

		//- copy the electrode to the xcell window

		copy ^ /xcell/draw/{name}
	end

	//- set success

	bResult = 1

	//- return result

	return {bResult}
end


///
/// SH:	XCellPrepareElectrodes
///
/// DE:	Prepare electrodes
///

function XCellPrepareElectrodes

	//- create a container

	create xform /electrodes

	//- disable the form

	disable ^

	//- create a draw

	create xdraw /electrodes/draw

	//- create an electrode prototype shape

	create xshape /electrodes/draw/proto \
		-linewidth 1 \
		-textmode nodraw \
		-pixcolor red \
		-coords [-40e-7,0,90e-7][0,0,0][-20e-7,0,100e-7][-30e-7,0,95e-7][-40e-7,0,150e-7][-140e-7,0,100e-7]

	//- add a field for identification

	addfield ^ \
		ident -description "Identification"

	//- set the field

	setfield ^ \
		ident "prototype"
end


///
/// SH:	XCellRemoveElectrode
///
/// PA:	path..:	path to the clicked compartment
///
/// DE:	Remove the electrode associated with {path}
///

function XCellRemoveElectrode(path)

str path

	//- get the registered xcell output source

	str xcOutputSource = {getfield /xcell outputSource}

	//- get the registered xcell output value

	str xcOutputValue = {getfield /xcell outputValue}

	//- get the registered xcell output flags

	int xcOutputFlags = {getfield /xcell outputFlags}

	//- get the electrode title

	str plotTitle = {XGraphPlotTitle \
				{path} \
				{xcOutputSource} \
				{xcOutputValue} \
				{xcOutputFlags}}

	//- if the electrode exists

	if ( {exists /electrodes/draw/{plotTitle}} )

		//- give diagnostics

		echo "Removing electrode "{plotTitle}

		//- remove the electrode

		delete /electrodes/draw/{plotTitle}

		//- if the electrodes toggle is set

		if ( {getfield /xcell/electrodes state} )

			//- delete the electrode from the xcell window

			delete /xcell/draw/{plotTitle}

			//- update the draw widget

			//xflushevents
			xupdate /xcell/draw

			//! to get around a bug that does not update 
			//! the deleted electrodes :
			//! hide and show the parent form

			xhide /xcell
			xshow /xcell
		end

	//- else

	else
		//- give diagnostics

		echo "No electrode named "{plotTitle}
	end
end


///
/// SH:	XCellRemoveElectrodes
///
/// PA:	unit..:	unit of the electrodes to be removed.
///
/// DE:	Remove all electrodes
///

function XCellRemoveElectrodes(unit)

str unit

	//- give diagnostics

	echo "Removing all electrodes, units ignored ----------------------"

	//- loop over all registered electrode

	str electr

	foreach electr ( {el /electrodes/draw/#[][ident=record]} )

		//! because of a bug in the wildcard parsing
		//! we can stil get the prototype here.
		//! we must check this by name of the element

		//- if it is not the prototype

		if ( {getpath {electr} -tail} != "proto" )

			//- delete the electrode to the xcell window

			delete {electr}
		end
	end

	//- update the state of the electrodes

	callfunc XCellSetupElectrodes {getfield /xcell/electrodes state}
end


///
/// SH:	XCellSetupElectrodes
///
/// PA:	state.:	0 if electrodes should be invisible
///		1 if electrodes should be visible
///
/// DE:	Show/hide the electrodes
///

function XCellSetupElectrodes(state)

int state

	//- loop over all electrodes in the xcell window

	str electr

	foreach electr ( {el /xcell/draw/#[][ident=record]} )

		//- remove the electrode

		delete {electr}
	end

	//- if the electrodes should be visible

	if (state)

		//- give diagnostics

		echo "Showing electrodes"

		//- loop over all registered electrode

		foreach electr ( {el /electrodes/draw/#[][ident=record]} )

			//- get the tail of the name

			str tail = {getpath {electr} -tail}

			//! because of a bug in the wildcard parsing
			//! we can stil get the prototype here.
			//! we must check this by name of the element

			if ( {tail} != "proto" )

				//- copy the electrode to the xcell window

				copy {electr} /xcell/draw/{tail}
			end
		end

	//- else

	else

		//- give diagnostics

		echo "Hiding electrodes"
	end

	//- update the draw widget

	xflushevents
	xupdate /xcell/draw

	//! to get around a bug that does not update the deleted electrodes :
	//! hide and show the parent form
	//! for some reason it is not necessary here, but it is above 
	//! (removal of electrodes).

//	xhide /xcell
//	xshow /xcell
end


///
/// SH:	XCellSetupGraph
///
/// PA:	state.:	0 if graph should be invisible
///		1 if graph should be visible
///
/// DE:	Show/hide the graph
///

function XCellSetupGraph(state)

int state

	//- if the graph should be visible

	if (state)

		//- show the graph

		xshow /xgraphs

	//- else

	else
		//- hide the graph

		xhide /xgraphs
	end
end


///
/// SH:	XCellSwitchChanMode
///
/// PA:	state.:	0 for absolute chanmode (chanmode 4)
///		1 for normalized chanmode (chanmode 5)
///
/// DE:	Switch between normalized and absolute channel mode
///	Sets the solver in {cellpath}/solve in chanmode 4 or 5.
///	Sets the min/max color values for the xcell display
///	Notifies graph for new chanmode
///

function XCellSwitchChanMode(state)

int state

	//- if state is not zero

	if (state)

		//- switch to chanmode 5

		setglobal iChanMode 5

		setfield {cellpath}/solve \
			chanmode {getglobal iChanMode}

	//- else

	else
		//- switch to chanmode 4

		setglobal iChanMode 4

		setfield {cellpath}/solve \
			chanmode {getglobal iChanMode}
	end

	//- get name for boundary element

	str bound = {BoundElementName \
			{getfield /xcell outputSource} \
			{getfield /xcell outputValue} \
			{getglobal iChanMode}}

	//- set field for boundaries

	setfield /xcell \
		boundElement {bound}

	//- set new boundaries from element

	callfunc XCellSetBoundaries {bound}

// 	//- notify graph new chanmode

// 	extern XGraphSwitchChanMode

// 	XGraphSwitchChanMode {state}
end


///
/// SH:	XCellDeleteMessages
///
/// DE:	Delete the messages from the xcell
///	If no messages are setup, none will be deleted and the function
///	will cleanly return.
///

function XCellDeleteMessages

	//- count the number of incoming messages

	int iCount = {getmsg /xcell/draw/xcell1 -incoming -count}

	//- if the count is not zero

	if (iCount)

		//- retreive the number of elements from the config

		int iElements = {getfield /config xCellElements}

		//- loop for the number of elements / messages

		int i

		for (i = 0; i < iElements; i = i + 1)

			//- delete the first message

			deletemsg /xcell/draw/xcell1 {0} -incoming
		end
	end
end


///
/// SH:	XCellSetupMessages
///
/// PA:	source:	message source in {cellpath}
///	value.:	message value within {source}
///
/// DE:	Setup the messages between the solver and xcell
///	The solver is assumed to be {cellpath}/solve .
///

function XCellSetupMessages(source,value)

str source
str value

	//- retreive the wildcard from the config file

	str wPath = {getfield /config xCellPath}

	//- give diagnostics

	echo "Setting up messages to xcell for "{source}", "{value}

	str element
//
//	foreach element ( { el { wPath } } )

//		if ( {exists {element}/{source}} )

//			echo Exists : {element}/{source}

//		else

//			echo Non existent : {element}/{source}
//		end
//		break
//	end

	//- loop over all elements in the xcell object

	str element

	foreach element ( { el { wPath } } )

		//- if the source elements exists

		if ( {exists {element}/{source}} )

			//echo Exists : {element}/{source}

			//- find solve field and add the message

			addmsg {cellpath}/solve /xcell/draw/xcell1 \
				COLOR {findsolvefield \
					{cellpath}/solve \
					{element}/{source} \
					{value}}

		//- else the element does not exist

		else

			//echo Non existent : {element}/{source}

			//- add a dummy message

			addmsg /config /xcell/draw/xcell1 COLOR z
		end
	end

	//- set number of compartments in the xcell object

	setfield /xcell/draw/xcell1 \
		nfield {getfield /config xCellElements}

	//- give diagnostics

	echo "Messages to xcell ok."
end


///
/// SH:	XCellSetupCompMessages
///
/// PA:	source:	message source in {cellpath} (not used)
///	value.:	message value within {source}
///
/// DE:	Setup the messages between the solver and xcell for compartments
///	The solver is assumed to be {cellpath}/solve .
///

function XCellSetupCompMessages(source,value)

str source
str value

	//- retreive the wildcard from the config file

	str wPath = {getfield /config xCellPath}

	//- give diagnostics

	echo "Setting up messages to xcell for (compartments), "{value}

	//- loop over all elements in the xcell object

	str element

	foreach element ( { el { wPath } } )

		//- if the source elements exists

		if ( {exists {element}} )

			//echo Exists : {element}

			//- find solve field and add the message

			addmsg {cellpath}/solve /xcell/draw/xcell1 \
				COLOR {findsolvefield \
					{cellpath}/solve \
					{element} \
					{value}}

		//- else the element does not exist

		else

			//echo Non existent : {element}

			//- add a dummy message

			addmsg /config /xcell/draw/xcell1 COLOR z
		end
	end

	//- set number of compartments in the xcell object

	setfield /xcell/draw/xcell1 \
		nfield {getfield /config xCellElements}

	//- give diagnostics

	echo "Messages to xcell ok."
end


///
/// SH:	XCellSetupExcIGEMessages
///
/// PA:	source:	message source in {cellpath}
///	value.:	message value within {source}
///
/// DE:	Setup the messages between the solver and xcell
///	The solver is assumed to be {cellpath}/solve .
///

function XCellSetupExcIGEMessages(source,value)

str source
str value

	//- this works only for Erik's Purkinje cell model

	//t have the cell document what is possible :
	//t
	//t register names of actions with the cell,
	//t call the actions at appropriate times.
	//t
	//t here we should call the action exc_ige
	//t

	//! note this depends critically on the fact that addglobal
	//! does not recreate already existing variables.

	addglobal int "cell_supports_exc_ige"

	if ( {getglobal "cell_supports_exc_ige"} == 0)

		echo "This cell does not offer support to link the xcell" -n
		echo "display with excitatory synaptic channels"

		return
	end

	//- retreive the wildcard from the config file

	str wPath = {getfield /config xCellPath}

	//- give diagnostics

	echo "Setting up messages to xcell for " \
		{source}", "{value}

	//- loop over all elements in the xcell object

	str element

	foreach element ( { el { wPath } } )

		//- get the spine that gives messages to the element

		str spine = {getmsg {element} -outgoing -destination 7}

		//- get tail of spine

		str spineTail = {getpath {spine} -tail}

		//- get head of spine for use with solver's flat space

		str spineHead = {getpath {spine} -head}

		//- if we are handling a spine

		if ( {strncmp {spineTail} "spine" 5} == 0 )

			//- default index is zero

			source = "head[0]/par"

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

			//- find solve field and add the message

			addmsg {cellpath}/solve /xcell/draw/xcell1 \
				COLOR {findsolvefield \
					{cellpath}/solve \
					{spineHead}{source} \
					{value}}

		//- else if we can find a climbing fiber input

		elif ( {exists {element}/climb } )

			//- find solve field and add the message

			addmsg {cellpath}/solve /xcell/draw/xcell1 \
				COLOR {findsolvefield \
					{cellpath}/solve \
					{element}/climb \
					{value}}

		//- else the element does not exist

		else
			//- add a dummy message

			addmsg /config /xcell/draw/xcell1 COLOR z
		end
	end

	//- set number of compartments in the xcell object

	setfield /xcell/draw/xcell1 \
		nfield {getfield /config xCellElements}

	//- give diagnostics

	echo "Messages to xcell ok."
end


///
/// SH:	XCellSetupInhIGEMessages
///
/// PA:	source:	message source in {cellpath}
///	value.:	message value within {source}
///
/// DE:	Setup the messages between the solver and xcell
///	The solver is assumed to be {cellpath}/solve .
///

function XCellSetupInhIGEMessages(source,value)

str source
str value

	//- this works only for Erik's Purkinje cell model

	//t have the cell document what is possible :
	//t
	//t register names of actions with the cell,
	//t call the actions at appropriate times.
	//t
	//t here we should call the action inh_ige
	//t

	//! note this depends critically on the fact that addglobal
	//! does not recreate already existing variables.

	addglobal int "cell_supports_inh_ige"

	if ( {getglobal "cell_supports_inh_ige"} == 0)

		echo "This cell does not offer support to link the xcell" -n
		echo "display with inhibitory synaptic channels"

		return
	end

	//- retreive the wildcard from the config file

	str wPath = {getfield /config xCellPath}

	//- give diagnostics

	echo "Setting up messages to xcell for " \
		{source}", "{value}

	//- loop over all elements in the xcell object

	str element

	foreach element ( { el { wPath } } )

		//- if we are handling a stellate cell

		if ( {exists {element}/stell} )

			//- find solve field and add the message

			addmsg {cellpath}/solve /xcell/draw/xcell1 \
				COLOR {findsolvefield \
					{cellpath}/solve \
					{element}/stell \
					{value}}

		//- else if we can find a stellate 1 cell

		elif ( {exists {element}/stell1 } )

			//- find solve field and add the message

			addmsg {cellpath}/solve /xcell/draw/xcell1 \
				COLOR {findsolvefield \
					{cellpath}/solve \
					{element}/stell1 \
					{value}}

		//- else if we can find a basket cell

		elif ( {exists {element}/basket } )

			//- find solve field and add the message

			addmsg {cellpath}/solve /xcell/draw/xcell1 \
				COLOR {findsolvefield \
					{cellpath}/solve \
					{element}/basket \
					{value}}

		//- else no inhibitory channel exists

		else
			//- add a dummy message

			addmsg /config /xcell/draw/xcell1 COLOR z
		end
	end

	//- set number of compartments in the xcell object

	setfield /xcell/draw/xcell1 \
		nfield {getfield /config xCellElements}

	//- give diagnostics

	echo "Messages to xcell ok."
end


///
/// SH:	XCellSetupSpineVmMessages
///
/// PA:	source:	message source in {cellpath}
///	value.:	message value within {source}
///
/// DE:	Setup the messages between the solver and xcell
///	The solver is assumed to be {cellpath}/solve .
///

function XCellSetupSpineVmMessages(source,value)

str source
str value

	//- retreive the wildcard from the config file

	str wPath = {getfield /config xCellPath}

	//- give diagnostics

	echo "Setting up spine compartment messages to xcell for " \
		{source}", "{value}

	//- loop over all elements in the xcell object

	str element

	foreach element ( { el { wPath } } )

		//- get the spine that gives messages to the element

		str spine = {getmsg {element} -outgoing -destination 7}

		//- get tail of spine

		str spineTail = {getpath {spine} -tail}

		//- get head of spine for use with solver's flat space

		str spineHead = {getpath {spine} -head}

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

			//echo {spineHead}{source} {value}

			//- find solve field and add the message

			addmsg {cellpath}/solve /xcell/draw/xcell1 \
				COLOR {findsolvefield \
					{cellpath}/solve \
					{spineHead}{source} \
					{value}}

		//- else the element does not exist

		else
			//- add a dummy message

			addmsg /config /xcell/draw/xcell1 COLOR z
		end
	end

	//- set number of compartments in the xcell object

	setfield /xcell/draw/xcell1 \
		nfield {getfield /config xCellElements}

	//- give diagnostics

	echo "Messages to xcell ok."
end


///
/// SH:	XCellSetupButtons
///
/// PA:	widget:	name of toggled widget
///	mode..:	output mode of xcell
///		1	comp. Vm
///		2	channel with IGE
///		3	excitatory channel with IGE
///		4	spine comp. Vm
///		5	nernst E
///		6	Calcium concen Ca
/// 		7	inhibitory channel with IGE
///
/// DE:	Display the buttons according to the output mode
///

function XCellSetupButtons(widget,mode)

str widget
int mode

	//echo setupbuttons : {widget} {mode}

	//- set the heading for the xcell form

	setfield /xcell/heading \
		title {getfield /xcell outputDescription}

	//- comp. Vm
	//- or spine comp. Vm
	//- or nernst E
	//- or Calcium concen Ca

	if (mode == 1 || mode == 4 || mode == 5 || mode == 6)

		//- hide I,G toggles

		xhide /xcell/Ik
		xhide /xcell/Gk

		//- show I,G labels

		xshow /xcell/noIk
		xshow /xcell/noGk

		//- show E label

		xhide /xcell/Ek
		xshow /xcell/noEk

	//- channel with IGE
	//- or excitatory channel with IGE
	//- or inhibitory channel with IGE

	elif (mode == 2 || mode == 3 || mode == 7)

		//- hide I,G labels

		xhide /xcell/noIk
		xhide /xcell/noGk

		//- show I,G toggles

		xshow /xcell/Ik
		xshow /xcell/Gk

		//- get widget tail

		str channel = {getpath {widget} -tail}

		//- for a calcium channel

		if ( {channel} == "CaP" || {channel} == "CaT")

			//- show Ek toggle

			xhide /xcell/noEk
			xshow /xcell/Ek

		//- else 

		else
			//- hide Ek toggle

			xshow /xcell/noEk
			xhide /xcell/Ek
		end

	//- else there is something wrong

	else
		//- give diagnostics

		echo "XCellSetupButtons : Wrong output mode for XCell"
	end

	//- loop over all toggle buttons in the xcell

	str toggle

	foreach toggle ( {el /xcell/#[][TYPE=xtoggle]} )

		//- isolate the tail

		str toggleTail = {getpath {toggle} -tail}

		//- if the toggle is not for graph, 
		//-	electrodes or abs/norm output

		if (toggleTail != "graph" \
			&& toggleTail != "electrodes" \
			&& toggleTail != "chanmode")

			//- unset the toggle

			setfield {toggle} \
				state 0
		end
	end

	//- set the toggle that has been pressed

	setfield {widget} \
		state 1

	//- set the toggle for the channel mode

	setfield /xcell/{getfield /xcell channelMode} \
		state 1

end


///
/// SH:	XCellSetOutput
///
/// PA:	widget:	name of toggled widget
///
/// RE: output mode
///	1	comp. Vm
///	2	channel with IGE
///	3	excitatory channel with IGE
///	4	spine comp. Vm
///	5	nernst E
///	6	Calcium concen Ca
///	7	inhibitory channel with IGE
///
/// DE:	Setup messages for update of xcell, setup buttons, do a reset
///

function XCellSetOutput(widget)

str widget

	//- set the field for output

	setfield /xcell \
		output {widget}

	//- delete all messages from the xcell

	XCellDeleteMessages

	//- default we should not continue

	int bContinue = 0

	//v strings for construction of messages

	str msgSource
	str msgValue
	str msgDescription

	//= mode for setting up buttons
	//=
	//= 1	comp. Vm
	//= 2	channel with IGE
	//= 3	excitatory channel with IGE
	//= 4	spine comp. Vm
	//= 5	nernst E
	//= 6	Calcium concen Ca
	//= 7	inhibitory channel with IGE

	int flButtons = 0

	//- get the parameter attribute for the widget

	str parameters = {getfield {widget} parameters}

	//- if we are dealing with compartments

	if (parameters == "Vm")

		//- the description is compartmental voltage

		msgDescription = "Compartmental voltage"

		//- the source is empty

		msgSource = ""

		//- the value is Vm

		msgValue = "Vm"

		//- remember to continue

		bContinue = 1

		//- set flags for buttons

		flButtons = 1

	//- if we are dealing with spine compartments

	elif (parameters == "spineVm")

		//- the description is spiny voltage

		msgDescription = "Spiny voltage"

		//- the source is the head of the spine

		msgSource = "head"

		//- the value is Vm

		msgValue = "Vm"

		//- remember to continue

		bContinue = 1

		//- set flags for buttons

		flButtons = 4

	//- if we are dealing with nernst

	elif (parameters == "E")

		//- the description is Nernst

		msgDescription = "Nernst"

		//- the source is Ca_nernst

		msgSource = "Ca_nernst"

		//- the value is E

		msgValue = "E"

		//- remember to continue

		bContinue = 1

		//- set flags for buttons

		flButtons = 5

	//- if we are dealing with concentration

	elif (parameters == "Ca")

		//- the description is compartmental Ca conc.

		msgDescription = "Compartmental [Ca2+]"

		//- the source is Ca_pool

		msgSource = "Ca_pool"

		//- the value is Ca

		msgValue = "Ca" 

		//- remember to continue

		bContinue = 1

		//- set flags for buttons

		flButtons = 6

	//- if we are dealing with channels

	elif (parameters == "IGE")

		//- the description is the channel with registered mode

		msgDescription \
			= {getpath {widget} -tail} \
				@ " " \
				@ {getfield \
					/xcell/{getfield /xcell channelMode} \
					description}

		//- the source is slash + the widget tail

		msgSource = {getpath {widget} -tail}

		//- the value is registered in /xcell

		msgValue = {getfield /xcell channelMode}

		//- remember to continue

		bContinue = 1

		//- set flags for buttons

		flButtons = 2

	//- if we are dealing with exc channels

	elif (parameters == "excIGE")

		//- the description is the channel with registered mode

		msgDescription \
			= "Excitatory " \
				@ {getfield \
					/xcell/{getfield /xcell channelMode} \
					description}

		//- the source is not relevant

		msgSource = "excitatory"

		//- the value is registered in /xcell

		msgValue = {getfield /xcell channelMode}

		//- remember to continue

		bContinue = 1

		//- set flags for buttons

		flButtons = 3

	//- if we are dealing with inh channels

	elif (parameters == "inhIGE")

		//- the description is the channel with registered mode

		msgDescription \
			= "Inhibitory " \
				@ {getfield \
					/xcell/{getfield /xcell channelMode} \
					description}

		//- the source is not relevant

		msgSource = "inhibitory"

		//- the value is registered in /xcell

		msgValue = {getfield /xcell channelMode}

		//- remember to continue

		bContinue = 1

		//- set flags for buttons

		flButtons = 7

	//- else somebody messed up the code

	else
		//- give diagnostics

		echo "Somebody messed up the code"
		echo "XCell module bug"
	end

	//- if we should continue

	if (bContinue)

		//- if we are handling compartments

		if (flButtons == 1)

			//- setup messages for compartments

			XCellSetupCompMessages {msgSource} {msgValue}

		//- else if we are handling spine compartments

		elif (flButtons == 4)

			//- setup messages for spines

			XCellSetupSpineVmMessages {msgSource} {msgValue}

		//- else if we are handling exc channels

		elif (flButtons == 3)

			//- setup messages for those channels

			XCellSetupExcIGEMessages {msgSource} {msgValue}

		//- else if we are handling inh channels

		elif (flButtons == 7)

			//- setup messages for those channels

			XCellSetupInhIGEMessages {msgSource} {msgValue}

		//- else we are handling normal messages

		else
			//- setup messages

			XCellSetupMessages {msgSource} {msgValue}
		end
	end

	//- register output description

	setfield /xcell \
		outputDescription {msgDescription}

	//- set up buttons correctly

	XCellSetupButtons {widget} {flButtons}

	//- get name of boundary element

	str bound = {BoundElementName {msgSource} {msgValue} {getglobal iChanMode}}

	//- register the output parameters and boundary element

	setfield /xcell \
		outputSource {msgSource} \
		outputValue {msgValue} \
		outputFlags {flButtons} \
		outputDescription {msgDescription} \
		boundElement {bound}

	//- set boundaries for xcell

	callfunc XCellSetBoundaries {bound}

	//- reset the simulation

	reset

// 	//- notify graph of switched output units

// 	callfunc XGraphNextPlotMode {msgValue}

	//- return the output mode

	return {flButtons}
end


///
/// SH:	XCellSetBoundaries
///
/// PA:	bound.:	boundary element
///
/// RE:	Success of operation
///
/// DE:	Set boundaries from the given element, update color widgets
///

function XCellSetBoundaries(bound)

str bound

	//v result var

	int bResult

	//- if the element with the boundaries exists

	if ( {exists {bound}} )

		//- give diagnostics

		echo "Setting xcell color boundaries from "{bound}

		//- set the fields for dimensions

		setfield /xcell/draw/xcell1 \
			colmin {getfield {bound} xcellmin} \
			colmax {getfield {bound} xcellmax}

		//- set config values in color widgets

		callfunc XCellShowConfigure

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
/// SH:	XCellSetChannelMode
///
/// PA:	widget:	name of toggled widget
///
/// DE:	Set the channel mode
///

function XCellSetChannelMode(widget)

str widget

	//- isolate the tail of the toggled widget

	str widgetTail = {getpath {widget} -tail}

	//- set the channelmode field

	setfield /xcell \
		channelMode {widgetTail}

	//- update the output messages

	XCellSetOutput {getfield /xcell output}
end


///
/// SH:	XCellCancelConfigure
///
/// DE:	Hide the configure window
///

function XCellCancelConfigure

	//- hide the configure window

	xhide /xcell/configure
end


///
/// SH:	XCellSetConfigure
///
/// DE:	Set xcell config as in the configuration window
///

function XCellSetConfigure

	//- set color min

	setfield /xcell/draw/xcell1 \
		colmin {getfield /xcell/colormin value}

	//- set color max

	setfield /xcell/draw/xcell1 \
		colmax {getfield /xcell/colormax value}
end


///
/// SH:	XCellShowCompartment
///
/// DE:	Popup compartment namer window.
///	This function messes with the xcell call back script
///

function XCellShowCompartment(compartment)

str compartment

	//- construct an appropriate message text

	str message

	if ( {exists {compartment} } )

		message = {"This is compartment " @ {compartment}}

		message = {{message} \
				@ "(dia:" \
				@ {getfield {compartment} dia} \
				@ ",len:" \
				@ {getfield {compartment} len} \
				@ ")"}

	else
		message = {"This compartment does not exist : " @ {compartment}}

	end

	//- echo the compartment to the terminal

	echo {message}

	//- display the message in the requester

	str requestername = {getfield /xcell requestername}

	XCellNameRequesterSetWarning {requestername} {message}

end


///
/// SH:	XCellShowCompartmentHideWindow
///
/// DE:	Hide the compartment namer window.
///

function XCellShowCompartmentHideWindow

	//- restore field for xcell script

	setfield /xcell/draw/xcell1 \
		script {cbXCellShowCompartment}

	//- hide add plot window

	str requestername = {getfield /xcell requestername}

	XCellNameRequesterHide {requestername}
end


///
/// SH:	XCellShowCompartmentShowWindow
///
/// DE:	Popup compartment namer window.
///	This function messes with the xcell call back script
///

function XCellShowCompartmentShowWindow

	//- store field for xcell script

	cbXCellShowCompartment = {getfield /xcell/draw/xcell1 script}

	//- set field for xcell script

	setfield /xcell/draw/xcell1 \
		script "XCellShowCompartment <v>"

	//- pop compartment namer

	str requestername = {getfield /xcell requestername}

	XCellNameRequesterShow {requestername}
end


///
/// SH: XCellShowConfigure
///
/// DE:	Show configuration window for xcell
///

function XCellShowConfigure

	//- set color min value

	setfield /xcell/colormin \
		value {getfield /xcell/draw/xcell1 colmin}

	//- set color max value

	setfield /xcell/colormax \
		value {getfield /xcell/draw/xcell1 colmax}
/*
	//- pop up the configuration window

	xshow /xcell/configure
*/
end


///
/// SH:	XCellCreateToggle
///
/// PA:	name..:	name of widget to create
///
/// DE:	Create a channel toggle button in the xcell form.
///	The button is only created if it does not exist yet.
///

function XCellCreateToggle(name)

str name

	//- if the widget does not exist yet

	if ( ! {exists /xcell/{name}} )

		//- if there are already channels created

		if (bButtonsCreated)

			//- create a toggle button beneath previous

			create xtoggle /xcell/{name} \
				-xgeom 90% \
				-wgeom 10% \
				-script "XCellSetOutput <w>"

		//- else 

		else
			//- create toggle button at upper right

			create xtoggle /xcell/{name} \
				-xgeom 90% \
				-ygeom 5% \
				-wgeom 10% \
				-script "XCellSetOutput <w>"

			//- remember that buttons are created

			bButtonsCreated = 1
		end

		//- add field for parameters

		addfield ^ \
			parameters -description "parameters for messages"

		//- set the parameter field to channels

		setfield ^ \
			parameters "IGE"
	end
end


///
/// SH:	XCellCreateChannelLibrary
///
/// DE:	Create library of Purkinje channels in /library
///

function XCellCreateChannelLibrary

	//v number of channels

	int iChannels = 0

	//- create neutral container

	create neutral /tmp

	//- loop over all purkinje channels found in the library

	str channel

	foreach channel ( {el /library/##[][TYPE=compartment]/##[][TYPE=tabchannel]} )

		//- isolate the name of the channel

		str tail = {getpath {channel} -tail}

		//- if the element does not exist

		if ( ! {exists /tmp/{tail}} )

			//- create library element

			create neutral /tmp/{tail}

			//- increment number of channels

			iChannels = {iChannels + 1}
		end
	end

	//- open the library file

	openfile {strXCLibrary}".u" w

	//- loop over all create elements

	foreach channel ( {el /tmp/#[]} )

		//- write tail of channel to the lib file

		writefile {strXCLibrary}".u" {getpath {channel} -tail}

		//- delete the neutral element

		delete {channel}
	end

	//- close the lib file

	closefile {strXCLibrary}".u"

	//- sort the lib file

	sh "sort <"{strXCLibrary}".u >"{strXCLibrary}".s"

	//- open the library file

	openfile {strXCLibrary}".s" r

	//- loop over all channels

	int i

	for (i = 0; i < iChannels; i = i + 1)

		//- read a channel

		channel = {readfile {strXCLibrary}".s" -linemode}

		//- create a neutral element

		create neutral /tmp/{channel}
	end

	//- close the lib file

	closefile {strXCLibrary}".s"
end


///
/// SH:	XCellCreateButtons
///
/// DE:	Create the xcell buttons and toggles.
///	Looks at the library to check which tabchannels are present
///

function XCellCreateButtons

	//- create toggle buttons per compartment

	create xtoggle /xcell/comp \
		-xgeom 70% \
		-ygeom 5% \
		-wgeom 20% \
		-title "Comp. Vm" \
		-script "XCellSetOutput <w>"
	addfield ^ \
		parameters -description "parameters for messages"
	setfield ^ \
		parameters "Vm"

	create xtoggle /xcell/Caconcen \
		-title "Comp. Ca" \
		-xgeom 70% \
		-wgeom 20% \
		-script "XCellSetOutput <w>"
	addfield ^ \
		parameters -description "parameters for messages"
	setfield ^ \
		parameters "Ca"

	create xtoggle /xcell/channelSpines \
		-xgeom 70% \
		-wgeom 20% \
		-title "Exc. chan." \
		-script "XCellSetOutput <w>"
	addfield ^ \
		parameters -description "parameters for messages"
	setfield ^ \
		parameters "excIGE"
	create xtoggle /xcell/channelSpinesInh \
		-xgeom 70% \
		-wgeom 20% \
		-title "Inh. chan." \
		-script "XCellSetOutput <w>"
	addfield ^ \
		parameters -description "parameters for messages"
	setfield ^ \
		parameters "inhIGE"
//	create xtoggle /xcell/compSpines \
//		-xgeom 70% \
//		-wgeom 20% \
//		-title "Spine comp." \
//		-script "XCellSetOutput <w>"
//	addfield ^ \
//		parameters -description "parameters for messages"
//	setfield ^ \
//		parameters "spineVm"
//	create xtoggle /xcell/nernst \
//		-xgeom 70% \
//		-wgeom 20% \
//		-script "XCellSetOutput <w>"
//	addfield ^ \
//		parameters -description "parameters for messages"
//	setfield ^ \
//		parameters "E"

	//- create a label as seperator

	create xlabel /xcell/sep1 \
		-xgeom 70% \
		-ygeom 3:last.bottom \
		-wgeom 20% \
		-title ""

	//- create toggle buttons for Ik,Gk,Ek

	create xtoggle /xcell/Ik \
		-xgeom 70% \
		-ygeom 1:sep1 \
		-wgeom 20% \
		-script "XCellSetChannelMode <w>"
	create xtoggle /xcell/Gk \
		-xgeom 70% \
		-wgeom 20% \
		-script "XCellSetChannelMode <w>"
	create xtoggle /xcell/Ek \
		-xgeom 70% \
		-wgeom 20% \
		-script "XCellSetChannelMode <w>"

	//- add descriptions

	addfield /xcell/Ik \
		description -description "Description of output"
	addfield /xcell/Gk \
		description -description "Description of output"
	addfield /xcell/Ek \
		description -description "Description of output"

	//- set descriptions

	setfield /xcell/Ik \
		description "current"
	setfield /xcell/Gk \
		description "conductance"
	setfield /xcell/Ek \
		description "reversal potential"

	create xlabel /xcell/noIk \
		-xgeom 70% \
		-ygeom 4:sep1 \
		-wgeom 20% \
		-title "No Ik"
	create xlabel /xcell/noGk \
		-xgeom 70% \
		-ygeom 3:last.bottom \
		-wgeom 20% \
		-title "No Gk"
	create xlabel /xcell/noEk \
		-xgeom 70% \
		-ygeom 3:last.bottom \
		-wgeom 20% \
		-title "No Ek"

	//- create a library of all channels

	XCellCreateChannelLibrary

	//- loop over all purkinje channels found in the library

	str channel

	foreach channel ( {el /tmp/#[]} )

		//- isolate the name of the channel

		str tail = {getpath {channel} -tail}

		//- create a toggle if necessary

		XCellCreateToggle {tail}
	end

	//- create toggle to show recording electrodes

	create xtoggle /xcell/electrodes \
		-xgeom 70% \
		-ygeom 6:draw.bottom \
		-wgeom 30% \
		-title "" \
		-onlabel "Electrodes" \
		-offlabel "No Electrodes" \
		-script "XCellSetupElectrodes <v>"

	//- create button to show compartment names

	create xbutton /xcell/naming \
		-xgeom 70% \
		-ygeom 5:last.bottom \
		-wgeom 30% \
		-title "Compartment Namer" \
		-script "XCellShowCompartmentShowWindow"

	//- create toggle to change normalized / absolute output

	create xtoggle /xcell/chanmode \
		-xgeom 70% \
		-ygeom 6:electrodes.top \
		-wgeom 30% \
		-title "" \
		-onlabel "Normalized" \
		-offlabel "Absolute" \
		-script "XCellSwitchChanMode <v>"

	//- create label with normalized / absolute description

	create xlabel /xcell/chanlabel \
		-xgeom 70% \
		-ygeom 6:chanmode.top \
		-wgeom 30% \
		-title "Output mode :"
end


///
/// SH:	XCellCreateColorDialogs
///
/// DE:	Create the xcell color dialogs at the bottom
///

function XCellCreateColorDialogs

	//- create color min dialog

	create xdialog /xcell/colormax \
		-xgeom 0:parent.left \
		-ygeom 5:draw.bottom \
		-wgeom 70% \
		-title "Color maximum (red)  : " \
		-script "XCellSetConfigure"

	//- create color max dialog

	create xdialog /xcell/colormin \
		-xgeom 0:parent.left \
		-ygeom 0:last.bottom \
		-wgeom 70% \
		-title "Color minimum (blue) : " \
		-script "XCellSetConfigure"
end


///
/// SH:	XCellCreateInfoArea
///
/// DE:	Create the xcell info area.
///

function XCellCreateInfoArea

	//- create color min dialog

	create xlabel /xcell/info1 \
		-xgeom 0:parent.left \
		-ygeom 15:colormin.bottom \
		-title "Initialized"

	create xlabel /xcell/info2 \
		-xgeom 0:parent.left \
		-ygeom 0:last.bottom \
		-title " "
end


///
/// SH:	XCellCreateHeadings
///
/// DE:	Create the xcell headings for the draw and buttons
///

function XCellCreateHeadings

	//- create header label

	create xlabel /xcell/heading [0,0,70%,5%] \
		-title "Comp. voltage"

	//- create buttons label

	create xlabel /xcell/outputs \
		-xgeom 0:last.right \
		-ygeom 0 \
		-wgeom 30% \
		-hgeom 5% \
		-title "Possible outputs"
end


///
/// SH:	XCellCreateDraw
///
/// DE:	Create the xcell draw
///

function XCellCreateDraw

	//- create draw within form

	create xdraw /xcell/draw [0,5%,70%,70%] \
		-wx 2e-3 \
		-wy 2e-3 \
		-transform ortho3d \
		-bg white

	//- set dimensions for draw

	setfield /xcell/draw \
		xmin -1.5e-4 \
		xmax 1.5e-4 \
		ymin -0.4e-4 \
		ymax 3.1e-4

	//- set projection mode

	addglobal str "xcell_transform_mode"

	setfield /xcell/draw \
		transform {xcell_transform_mode}

	//- retreive the wildcard from the config file

	str wPath = {getfield /config xCellPath}

	//- create cell display

	create xcell /xcell/draw/xcell1 \
	        -path {wPath} \
	        -colmin -0.09 \
	        -colmax 0.02 \
	        -diarange -20 

	//- set clock to use

	useclock /xcell/draw/xcell1 9
end


///
/// SH:	XCellReset
///
/// DE:	Set the default state for the xcell
///

function XCellReset

	//- default output is compartmental Vm

	setfield /xcell \
		output "/xcell/comp"

	//- default channel mode is conductance

	setfield /xcell \
		channelMode "Gk"

	//- if chanmode is 5

	if ({getglobal iChanMode} == 5)

		//- set widget to normalized output

		setfield /xcell/chanmode \
			state 1

	//- else

	else
		//- set widget to absolute output

		setfield /xcell/chanmode \
			state 0
	end

	//- default : electrodes are not visible

	setfield /xcell/electrodes \
		state 0

	//- update all output (buttons, colors)

	//! this just simulates a click on the comp. volt. button

	XCellSetOutput {getfield /xcell output}
end


// ///
// /// SH:	XCellCBRemovePlot
// ///
// /// PA:	path..:	path to the clicked compartment
// ///
// /// DE:	Callback to remove compartment from graph
// ///

// function XCellCBRemovePlot(path)

// str path

// 	//- remove the electrode

// 	XCellRemoveElectrode {path}

// 	//- remove plot from the clicked compartment

// 	callfunc "XGraphRemoveCompartment" /Purkinje {path}
// end


///
/// SH:	XCellCreate
///
/// DE:	Create the xcell display widget with all buttons
///	set the update clock to clock 9
///

function XCellCreate

	//- create form container

	create xform /xcell [0, 0, 500, 500]

	//- add field for output

	addfield /xcell \
		output -description "Output (toggled widget)"

	//- add field for output source

	addfield /xcell \
		outputSource -description \
				"Output source (compartment subelement)"

	//- add field for output value

	addfield /xcell \
		outputValue -description "Output value (Vm, Ik, Gk, Ek, Ca)"

	//- add field for output flags

	addfield /xcell \
		outputFlags -description "Output flags (1-7)"

	//- add field for output description

	addfield /xcell \
		outputDescription -description "Output description (Title)"

	//- add field for channel mode

	addfield /xcell \
		channelMode -description "Channel display mode (Ik, Gk, Ek)"

	//- add field for registering boundary element

	addfield /xcell \
		boundElement -description "Element with display boundaries"

	//- add a field to link with an xcell name requester

	addfield /xcell \
		requestername -description "xcell name requester"

	//- add an initialized field for allocated colors

	addfield /xcell cNextColor -descr "next color to allocate"
	setfield /xcell cNextColor {iXCellElectrodeDefaultColor}

	//- create a stack for the electrode callback

	create neutral /xcell/stack

	StackCreate /xcell/stack/

	//- create the heading at the top

	XCellCreateHeadings

	//- create the draw

	XCellCreateDraw

	//- create color dialog widgets at the bottom

	XCellCreateColorDialogs

	//- create the buttons and toggles

	XCellCreateButtons

	//- create the information area

	XCellCreateInfoArea

	//- prepare the electrodes

	XCellPrepareElectrodes

	setfield /xcell/draw/xcell1 \
		script "XCellElectrodeAdd.d1 <w> <v>"

// 	setfield /xcell/draw/xcell1 \
// 		script "XCellElectrodeAdd.d1 <w> <v> ; XCellCBRemovePlot.d3 <v>"

	//- create the form to request a compartment name

	str requestername \
		= {XCellNameRequester \
			"" \
			"Show compartment names" \
			"Select a compartment from the Purkinje cell" \
			"to know its name, or type a compartment " \
			"name to check its existence:" \
			"Compartment name : " \
			"XCellShowCompartment <v>" \
			"" \
			"Done" \
			"XCellShowCompartmentHideWindow"}

	setfield /xcell \
		requestername {requestername}

	//- set an informational message in the info area

	setfield /xcell/info1 \
		label "Select an output variable for the xcell view, next click"
	setfield /xcell/info2 \
		label "on the dendrite to plot the selected variable in a graph."

end


end


