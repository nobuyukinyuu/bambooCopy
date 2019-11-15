extends Control
var paths = []  #File paths
var LIB_PATH = "res://defaultLibrary/"
const CONFIGPATH = "res://default.cfg"

#Enums for the MiOPMdrv format positions.
enum LFO {LFRQ, AMD, PMD, WAVEFORM, NFRQ}
enum CH {PAN, FL, CON, AMS, PMS, SLOT, NE}
enum OP {AR, DR, SR, RR, SL, TL, KS, ML, DT, DT2, AMS_ENABLE}

var programs = {}  #Instrument data.
var currentProgram = {}

onready var config = ConfigFile.new()

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		config.save(CONFIGPATH)
		print ("Byebye!")

func _ready():
	
	#Prepare the config file.
	if config.load(CONFIGPATH) != OK:
		config.set_value("Folders", "0", LIB_PATH )
		config.save(CONFIGPATH)
	
	$Config/VBoxContainer/chkRecursive.pressed = config.get_value(
													"General", "recursive_scan", true)
	
	scan_folders()

#Rescans the folder list.
func scan_folders():
	$Items.clear()
	paths.clear()
	$Config/Folders.clear()

	var f_icon = preload("res://open-folder.svg")

	#Load folders into item list.
	for f in config.get_section_keys("Folders"):
		var val = config.get_value("Folders", f, "") 
		$Config/Folders.add_item(val, f_icon)
	
	
		var d = ProjectSettings.globalize_path(val)
		try_path(d)
	

		
func try_path(path):
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin(true,true)
		var file_name = dir.get_next()
		while (file_name != ""):
			if dir.current_is_dir():
				if config.get_value("General", "recursive_scan") == true:
					try_path(path + "/" + file_name)		#Recursive dive!
			else:
				if file_name.to_lower().ends_with(".opm"):
					$Items.add_item(file_name)
					paths.push_back(file_name)
				
				
			file_name = dir.get_next()
	else:
		print("An error occurred accessing the path '%s'." % path)



func _on_Items_item_activated(index):
	load_opm(LIB_PATH + paths[index])


func load_opm(path):
	var f = File.new()
	var err = f.open(path, File.READ)

	if err != OK:
			OS.alert("Can't open bank.  (Error %s)" % err, "Error opening file")
			
			f.close()
			return

	#Start parsing in.
	$Instruments.clear()
	programs.clear()
	var inst_index = 0  #Instrument index
	while not f.eof_reached():
		var line:String = f.get_line()
		if line.begins_with("//"):  continue  #Comment.  Ignore.
		
		
		if line.begins_with("@:"):  #We found an instrument.
			if $ignoreNoname.pressed and line.rfind("no Name") != -1:
				#Default instrument.  Ignore.
				break
		
			var p = {}  #Prototype
			
			for i in range(6):
				var l = f.get_line()
				var cursorLoc = l.find(" ")  #In between the line label and the data
				p[ l.left(cursorLoc -1) ] = l.right(cursorLoc).strip_edges() 

			#Add the instrument prototype to the programs
			var inst_name = line.right(line.find(" "))
			p["name"] = inst_name
			programs[inst_index] = p
			inst_index +=1
			$Instruments.add_item(inst_name, preload("res://at.svg"))
			pass
		
		pass

			
	f.close()
	pass

#Pulls a parameter from the specified program with the specified line label.
func get_param_by_index(program_index:int, lbl:String, param:int):
	if !programs.has(program_index):
		printerr("Program '%s' not found!" % program_index)
		return

	var params:String = programs.get(program_index) [lbl].split_floats(" ")
	
	return params[param]
#Pulls a parameter from the current program with the specified line label.
func get_param(lbl:String, param:int):
	var params:String = currentProgram [lbl].split_floats(" ")
	return params[param]

#Set up the instrument
func _on_Instruments_item_activated(index):
	#Load an instrument.
	$ProgramName.text = programs[index]["name"]
	currentProgram = programs[index]

	#Get the algorithm used for this instrument.
	select_algo(get_param_by_index(index, "CH", CH.CON))
	
	#Set the envelopes.  Utilizes the tab name to find the parameters for each.
	for tab in $OP.get_children():
		tab.get_node("Panel").setOP(programs[index][tab.name])

#Single click support
func _on_Instruments_item_selected(index):
	_on_Instruments_item_activated(index)

	
#Select an algorithm to display.
func select_algo(idx=-1):
	for i in 8:
		$AL.get_node(str(i)).visible = false
	
	if idx >= 0 and idx < 8:
		$AL.get_node(str(idx)).visible = true

#Assemble a preview string for FMGon to use.
func _on_Preview_pressed():
	#input format: FL, AL,		AR1, DR1, SR1, RR1, SL1, TL1, KS1, MUL1, DT1,  ....... 
	#							DT2 and AMS-EN are ignored.
	if currentProgram.empty():  return
	
	var pString = str(get_param("CH", CH.FL)) + "," + str(get_param("CH", CH.CON)) 
		
	#Assemble the operators.
	for op in ["M1", "C1", "M2", "C2"]:
		var i = 0
		var vals = currentProgram[op].split(" ")
		for val in vals:
			if i < 9:  #Ignores the last 2 params.
				pString += "," + val
				i += 1
	
	
	prints("Previewing", pString)
	
	var a = ["No output"]
	OS.execute("fmgon_test.exe", ["custom", pString], false, a)

# Copy a BambooTracker compatible instrument.
func _on_CopyEnvelope_pressed():
	if currentProgram.empty():  return
	var pString = "FM_ENVELOPE:"
	pString += str(get_param("CH", CH.FL)) + "," + str(get_param("CH", CH.CON)) + ",\n"
	
	#Assemble the operators.
	for op in ["M1", "C1", "M2", "C2"]:
		var i = 0
		var vals = currentProgram[op].split(" ")
		for val in vals:
			if i < 9:  #Ignores the last 2 params.
				pString += val + ","
				i += 1
		#Append the SSG envelope (always -1 since OP-M doesn't have this feature) and linebreak
		pString += "-1,\n"

	print (pString)
	OS.clipboard = pString
	$lblStatus.text = currentProgram["name"] + " copied.\nPaste into BambooTracker instrument!"


#Load config window.
func _on_btnConfig_pressed():
	$Config.popup_centered()

#New folder.
func _on_btnNew_pressed():
	$Config/FolderDialog.popup_centered()

#New folder location selected.
func _on_FolderDialog_dir_selected(dir):
	$Config/Folders.add_item(dir)
	config.set_value("Folders", str(config.get_section_keys("Folders").size()), dir)

#Select a folder.
var lastEditedFolderIdx = -1
func _on_Folders_item_selected(index):
	lastEditedFolderIdx = index

#Remove a folder.
func _on_btnRemove_pressed():
	if lastEditedFolderIdx >= 0:
		config.erase_section("Folders")
		$Config/Folders.remove_item(lastEditedFolderIdx)
		
		for i in $Config/Folders.get_item_count():
			config.set_value("Folders", str(i), $Config/Folders.get_item_text(i))
		
		lastEditedFolderIdx = -1
		

#Edit folder location.
func _on_Folders_item_activated(index):
	lastEditedFolderIdx = index
	$Config/FolderDialog2.current_dir = $Config/Folders.get_item_text(index)
	$Config/FolderDialog2.popup_centered()

#Folder location changed.
func _on_FolderDialog2_dir_selected(dir):
	config.set_value("Folders", str(lastEditedFolderIdx), dir)
	
	$Config/Folders.set_item_text(lastEditedFolderIdx, dir)
	pass # Replace with function body.


#Close config window.
func _on_Okay_pressed():
	$Config.visible = false



#Recursive folder scanning enable
func _on_chkRecursive_toggled(button_pressed):
	config.set_value ("General", "recursive_scan", button_pressed)

#Rescan all folders.
func _on_Rescan_pressed():
	scan_folders()
