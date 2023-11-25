@tool
extends Control

# SaveData accessor script included here for the debug edit type
const accessor_script = preload("res://addons/savedata-dx/backend/save_accessor.gd")
@onready var accessor_inst = accessor_script.new()

# Variables pointing to different nodes in layout
@onready var head_button_edit_mode = %HeadEditMode
@onready var head_button_new = %HeadNew
@onready var head_button_load = %HeadLoad
@onready var head_button_save = %HeadSave

@onready var debug_select = $DebugSelect

# Current edit mode
var edit_mode: EditModeType
enum EditModeType {
	SLOT,
	COMMON,
	DEBUG
}

func _ready() -> void:
	_on_edit_mode_selected(EditModeType.DEBUG)

# Update the interface when the edit mode is changed
func _on_edit_mode_selected(index: int) -> void:
	head_button_edit_mode.selected = index
	edit_mode = index
	
	match(index):
		EditModeType.SLOT:
			head_button_new.disabled = false
			head_button_load.disabled = false
			head_button_save.disabled = false
		EditModeType.COMMON:
			head_button_new.disabled = true
			head_button_load.disabled = true
			head_button_save.disabled = false
		EditModeType.DEBUG:
			head_button_new.disabled = true
			head_button_load.disabled = false
			head_button_save.disabled = false

# Header button functions
func _on_head_new_pressed():
	pass # Replace with function body.

func _on_head_load_pressed():
	match edit_mode:
		EditModeType.DEBUG:
			debug_select.popup()

func _on_head_save_pressed():
	pass # Replace with function body.

# Debug mode functions

# Convert file path to dictionary
func decrypt_save(path: String) -> Dictionary:
	return accessor_inst.read_backend(path)

# Called upon selecting a file in the debugger mode
func _on_debug_select_file(path: String) -> void:
	var dict: Dictionary = decrypt_save(path)
	%CodeEdit.text = JSON.stringify(dict, "\t", true)
