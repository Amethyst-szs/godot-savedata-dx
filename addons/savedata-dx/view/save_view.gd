@tool
extends Control

# SaveData accessor script, this is added here so the accessor doesn't have to include @tool
const accessor_script = preload("res://addons/savedata-dx/backend/save_accessor.gd")
var accessor_inst = accessor_script.new()

# Constants
const root_slot_path: String = "res://addons/savedata-dx/data_slot.gd"
const root_common_path: String = "res://addons/savedata-dx/data_common.gd"

# Variables pointing to different nodes in layout
@onready var head_button_edit_mode = %HeadEditMode
@onready var head_button_new = %HeadNew
@onready var head_button_load = %HeadLoad
@onready var head_button_save = %HeadSave

@onready var code_editor = %CodeEdit

@onready var inspector_file_dialog = $InspectorFileDialog

# Current editor information
var open_file_path: String

var edit_mode: EditModeType
enum EditModeType {
	SLOT,
	COMMON,
	INSPECTOR
}

func _ready() -> void:
	_on_edit_mode_selected(EditModeType.SLOT)

# Common utility functions
func setup_slot_mode() -> void:
	# Open the root of the slot script in code editor
	code_editor_open_file(root_slot_path)
	
	# Enable all buttons
	head_button_new.disabled = false
	head_button_load.disabled = false
	
func setup_common_mode() -> void:
	# Open the root of the common script in code editor
	code_editor_open_file(root_common_path)
	
	# Enable all buttons
	head_button_new.disabled = false
	head_button_load.disabled = false
	
func setup_inspector_mode() -> void:
	# Disable the new button and enable the load button
	head_button_new.disabled = true
	head_button_load.disabled = false
	
	# Popup file dialog in the user's save directory
	inspector_file_dialog.popup()

# Update the interface when the edit mode is changed
func _on_edit_mode_selected(index: int) -> void:
	# Copy selected into into current edit mode
	head_button_edit_mode.selected = index
	edit_mode = index
	
	# Reset the code editor panel
	code_editor_close()
	
	# Configure depending on selected option in menu
	match(index):
		EditModeType.SLOT: setup_slot_mode()
		EditModeType.COMMON: setup_common_mode()
		EditModeType.INSPECTOR: setup_inspector_mode()

# Header button functions

func _on_head_new_pressed():
	pass # Replace with function body.

func _on_head_load_pressed():
	match edit_mode:
		EditModeType.INSPECTOR: inspector_file_dialog.popup()

func _on_head_save_pressed():
	if open_file_path.is_empty():
		return
	
	if edit_mode == EditModeType.INSPECTOR:
		accessor_inst.write_backend_with_json_string(open_file_path, code_editor.text)
	else:
		code_editor_save_script()

# Inspector mode functions

# Convert file path to dictionary
func decrypt_save(path: String) -> String:
	return accessor_inst.read_backend_raw_data(path)

# Called upon selecting a file in the debugger mode
func _on_inspector_select_file(path: String) -> void:
	var data: String = decrypt_save(path)
	if data.is_empty():
		code_editor_close("Save data could not be opened correctly, check output for more info")
		return
	
	# Copy the selected file's path to the open file path variable
	open_file_path = path
	
	# Setup code editor
	code_editor_open()
	code_editor.text = data

# Code editor management

func code_editor_close(text: String = "Open a file or change edit mode in the top bar") -> void:
	code_editor.editable = false
	code_editor.text = ""
	code_editor.placeholder_text = text
	head_button_save.disabled = true

func code_editor_open() -> void:
	code_editor.editable = true
	code_editor.text = ""
	code_editor.placeholder_text = ""
	head_button_save.disabled = false

func code_editor_open_file(path: String) -> void:
	# Verify the file exists and return early if not
	if not FileAccess.file_exists(path):
		printerr("Cannot open non-existent file at %s" % [path])
		return
	
	# Open target file
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		printerr("FileAccess open error: " + str(FileAccess.get_open_error()))
		return
	
	# Get the content of the open file
	var content: String = file.get_as_text()
	file.close()
	
	# Trim string to cut off gdscript boilerplate
	var first_line: int = content.find("\n")
	if not first_line == -1:
		content = content.substr(first_line + 1)
	
	# Setup code editor
	open_file_path = path
	code_editor.editable = true
	code_editor.text = content
	code_editor.placeholder_text = ""
	head_button_save.disabled = false

func code_editor_save_script() -> void:
	# Attempt to open new file and print an error if it fails
	var file = FileAccess.open(open_file_path, FileAccess.WRITE)
	if open_file_path == null:
		printerr("FileAccess open error: " + str(FileAccess.get_open_error()))
		return
	
	# Write data to disk
	file.store_string("extends Object\n" + code_editor.text)
	file.close()
