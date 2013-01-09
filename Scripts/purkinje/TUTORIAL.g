//genesis - Purkinje cell version M9 genesis2 master script
// Copyright: Theoretical Neurobiology, Born-Bunge Foundation - UA, 1998-1999.
//
// $ProjectVersion: Release2-2.11 $
// 
// $Id: TUTORIAL.g,v 1.8 2006/02/22 05:56:56 svitak Exp $
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

//- give header

echo "--------------------------------------------------------------------------"
echo
echo "Purkinje tutorial, version " -n
// $Format: "echo \"$ProjectVersion$ ($ProjectDate$)\""$
echo "Release2-2.11 (Tue, 21 Feb 2006 17:03:18 -0600)"
echo "                       Simulation script"
echo
echo "--------------------------------------------------------------------------"


//- let Genesis know where to find the library of prototypes

setenv SIMPATH {getenv SIMPATH} ./library/cells/purkinje_eds1994
setenv SIMPATH {getenv SIMPATH} ./library/cells/purkinje_guineapig
setenv SIMPATH {getenv SIMPATH} ./library/cells/purkinje_rat
setenv SIMPATH {getenv SIMPATH} ./library/cells/purkinje_turtle
setenv SIMPATH {getenv SIMPATH} ./library/segments
setenv SIMPATH {getenv SIMPATH} ./library/channels

//- cell path of cell to simulate

addglobal str cellpath "/Purkinje"

//- set default output rate

addglobal int outputRate 10

//- set default chanmode for solver : normalized

addglobal int iChanMode 5

//- set default mode : in vitro

addglobal int iVVMode 0

//- set default for current : current clamp on

addglobal int iCurrentMode 1

//- in vivo : parallel cell firing rate

addglobal float phertz 25

//- in vivo : basket cell firing rate

addglobal float ihertz 1

//- speed of climbing fiber volley (in sec)

addglobal float delay 0.00020

//- strength of climbing fiber synapses

addglobal float strength 1.0

//- speed of climbing fiber volley (in steps == delay / dt)
//- this variable is set later on when dt is defined in an other module

addglobal int delaysteps {0.00020 / 1}

//- cell that is read from pattern file

echo "cellpath is " {cellpath}

include cell.g {cellpath}

//- include the utility module, it is needed by multiple others modules

utility.g

//- include the config module

config.g

// //- default we do not update the config file

// addglobal int bUpdateConfig 0

//- read cell data from .p file

readcell {cellfile} {cellpath}

//- analyze the cell structure

cell_path.g

CellPathInitialize {cellpath}


//- include other files of interest

info.g
bounds.g
config.g
control.g
xcell.g
xgraph.g


//- read configuration file

ConfigRead {cellfile} {cellpath}

//- initialize experiments specific for this cell

CellInit

//- set simulation clocks

int i, j

for (i = 0; i <= 8; i = i + 1)
	setclock {i} {dt}
end

//- set the output clock

setclock 9 {dt * outputRate}

//- set clock for refresh elements

setclock 10 {dt * 239}

//- set delay in steps for climbing fiber

delaysteps = {delay / dt}

//- setup the hines solver

echo preparing hines solver {getdate}
ce {cellpath}
create hsolve solve

//- We change to current element solve and then set the fields of the parent
//- (solve) to get around a bug in the "." parsing of genesis

ce solve

setfield . \
        path "../##[][TYPE=compartment]" \
        comptmode 1 \
        chanmode {getglobal iChanMode} \
        calcmode 0

//- create all info widgets

InfoCreate

//- create all settings widgets

SettingsCreate

//- setup the solver with all messages from the settings

call /Purkinje/solve SETUP

//- Use method to Crank-Nicolson

setmethod 11

//- go back to simulation element

ce /Purkinje

//- set colorscale

xcolorscale rainbow3

//- create the xcell widget

XCellCreate

//- create the graph widgets

// str unit
// str outputSource
// str outputValue
// str outputFlags
// str outputDescription
// int iChannelMode

XGraphCreate \
	Vm \
	"" \
	"Vm" \
	1 \
	"Compartmental voltage" \
	{getglobal iChanMode}

XGraphCreate \
	Ca \
	"Ca_pool" \
	"Ca" \
	6 \
	"Compartmental [Ca2+]" \
	{getglobal iChanMode}

XGraphCreate \
	Ik \
	-1 \
	"Ik" \
	2 \
	"Channel current (Ik)" \
	{getglobal iChanMode}

XGraphCreate \
	Gk \
	-1 \
	"Gk" \
	2 \
	"Channel conductance (Gk)" \
	{getglobal iChanMode}

XGraphCreate \
	Em \
	-1 \
	"Ek" \
	2 \
	"Channel reversal potential" \
	{getglobal iChanMode}

//- set default state

XCellReset

// //- reset graph

// XGraphReset

//- create the control panel

ControlPanelCreate

//- create the output menus

output.g

OutputInitialize

sh "mkdir simulation_sequences/Purkinje"

echo "Prepared directory for simulation plots : simulation_sequences/Purkinje"
echo "You can find ascii file recordings overthere."

//- reset simulation

PurkinjeReset

//- to further initialize all elements (e.g. colors of xcell element)
//- we do one step in the simulation and then a reset

step 1

//- update the firing frequencies for stellate and parallel fibers

UpdateFrequencies

//- reset all elements

reset

//- show some of the graphics

call /output/panel/cell B1DOWN
setfield /output/panel/cell state 1

//! now it's up to the user to do simulations...


