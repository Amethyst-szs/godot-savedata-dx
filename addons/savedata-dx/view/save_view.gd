@tool
extends Control

# SaveData accessor script
const accessor_script = preload("res://addons/savedata-dx/backend/save_accessor.gd")
var accessor_inst = accessor_script.new()

# Constants
const root_slot_path: String = "res://addons/savedata-dx/data_slot.gd"
const root_common_path: String = "res://addons/savedata-dx/data_common.gd"

# Header buttons
@onready var head_button_edit_mode := %HeadEditMode
@onready var head_button_add := %HeadAdd
@onready var head_button_new := %HeadNew
@onready var head_button_load := %HeadLoad
@onready var head_button_save := %HeadSave
@onready var head_button_info := %HeadInfo
@onready var head_button_close := %HeadClose
@onready var head_file_name := %OpenFileTextLabel

# Code editor
@onready var code_editor := %CodeEdit
@onready var code_error_footer := %ErrorFooter
@onready var code_error_text := %ErrorText

# Dialog popups
@onready var inspector_file_dialog := $InspectorFileDialog
@onready var inspector_save_fail_dialog := $InspectorSaveFailDialog
@onready var slot_new_file_dialog := $SlotNewFileDialog
@onready var slot_load_file_dialog := $SlotLoadFileDialog
@onready var slot_import_file_dialog := $SlotImportFileDialog
@onready var common_new_file_dialog := $CommonNewFileDialog
@onready var common_load_file_dialog := $CommonLoadFileDialog
@onready var common_import_file_dialog := $CommonImportFileDialog

# Current editor information
var open_file_path: String:
	set (value):
		head_file_name.text = value
		open_file_path = value
	get:
		return open_file_path

var unsaved_changes: bool = false:
	set (value):
		if value:
			head_button_save.text = " Save*"
		else:
			head_button_save.text = " Save"
		
		unsaved_changes = value
	get:
		return unsaved_changes

var edit_mode: EditModeType
enum EditModeType {
	INSPECTOR,
	SLOT,
	COMMON
}

# Reference to editor plugin
var editor_plugin: EditorPlugin

func _ready() -> void:
	if not is_instance_valid(editor_plugin):
		return
		
	apply_theme()
	_on_edit_mode_selected(EditModeType.INSPECTOR)

func _input(event: InputEvent) -> void:
	if not visible: return

	if event is InputEventKey and event.is_pressed():
		match event.as_text():
			"Ctrl+S", "Command+S":
				get_viewport().set_input_as_handled()
				_on_head_save_pressed()
			"Ctrl+O", "Command+O":
				get_viewport().set_input_as_handled()
				_on_head_load_pressed()
			"Ctrl+N", "Command+N":
				get_viewport().set_input_as_handled()
				_on_head_new_pressed()
			"Ctrl+W", "Command+W":
				get_viewport().set_input_as_handled()
				_on_head_close_pressed()
			"Ctrl+I", "Command+I":
				get_viewport().set_input_as_handled()
				_on_head_add_pressed()

# Common utility functions
func setup_slot_mode() -> void:
	# Open the root of the slot script in code editor
	code_editor_open_file(root_slot_path)
	
	# Toggle button activeness
	head_button_new.visible = true
	head_button_add.visible = true
	
func setup_common_mode() -> void:
	# Open the root of the common script in code editor
	code_editor_open_file(root_common_path)
	
	# Toggle button activeness
	head_button_new.visible = true
	head_button_add.visible = true
	
func setup_inspector_mode() -> void:
	# Toggle button activeness
	head_button_new.visible = false
	head_button_add.visible = false

# Update the interface when the edit mode is changed
func _on_edit_mode_selected(index: int) -> void:
	# Copy selected into into current edit mode
	head_button_edit_mode.selected = index
	edit_mode = index
	
	# Reset the code editor panel
	code_editor_close()
	head_button_close.disabled = true
	
	# Configure depending on selected option in menu
	match(index):
		EditModeType.SLOT: setup_slot_mode()
		EditModeType.COMMON: setup_common_mode()
		EditModeType.INSPECTOR: setup_inspector_mode()

# Header button functions

func _on_head_new_pressed():
	match edit_mode:
		EditModeType.SLOT: slot_new_file_dialog.popup()
		EditModeType.COMMON: common_new_file_dialog.popup()

func _on_head_load_pressed():
	match edit_mode:
		EditModeType.SLOT: slot_load_file_dialog.popup()
		EditModeType.COMMON: common_load_file_dialog.popup()
		EditModeType.INSPECTOR: inspector_file_dialog.popup()

func _on_head_save_pressed():
	if open_file_path.is_empty():
		return
	
	unsaved_changes = false
	
	# If in inspector mode, verify user input and then write to disk
	if edit_mode == EditModeType.INSPECTOR:
		var test_parse = JSON.parse_string(code_editor.text)
		if test_parse == null:
			inspector_save_fail_dialog.popup()
			return
			
		accessor_inst._write_backend_with_json_string(open_file_path, code_editor.text)
	else: # If this isn't inspector mode, write script to disk normally
		code_editor_save_script()

func _on_head_add_pressed():
	match edit_mode:
		EditModeType.SLOT: slot_import_file_dialog.popup()
		EditModeType.COMMON: common_import_file_dialog.popup()

func _on_head_info_pressed():
	OS.shell_open("https://github.com/Amethyst-szs/godot-savedata-dx/wiki")

func _on_head_close_pressed():
	_on_edit_mode_selected(edit_mode)

# Slot and Common mode functions

func _on_slot_new_file_dialog(path: String) -> void:
	open_file_path = path
	head_button_close.disabled = false
	code_editor_open()

func _on_slot_load_file_dialog(path: String) -> void:
	head_button_close.disabled = false
	code_editor_open_file(path)

func _on_slot_import_file_dialog(path: String) -> void:
	_on_code_edit_text_changed()
	
	# Create constant name
	var path_end: int = path.rfind("/") + 1
	var name: String = path.substr(path_end).replacen(".", "_")
	
	code_editor.text = "const %s = preload(\"%s\")\n\n%s" % [name, path, code_editor.text]

# Inspector mode functions

# Convert file path to dictionary
func decrypt_save(path: String) -> String:
	return accessor_inst._read_backend_raw_data(path)

# Called upon selecting a file in the debugger mode
func _on_inspector_select_file(path: String) -> void:
	var data: String = decrypt_save(path)
	if data.is_empty():
		code_editor_close("Save data could not be opened, check output for more info")
		return
	
	# Copy the selected file's path to the open file path variable
	open_file_path = path
	
	# Setup code editor
	head_button_close.disabled = false
	code_editor_open()
	code_editor.text = data

# Code editor management

func _on_code_edit_text_changed():
	unsaved_changes = true
	$CompileTimer.start()

func _on_compile_timer_timeout():
	# Only needs to test compiling for the inspector mode
	if not edit_mode == EditModeType.INSPECTOR:
		return
	
	# Try parsing the JSON
	var json: JSON = JSON.new()
	var test_parse: Error = json.parse(code_editor.text)
	
	# If the parse was unsuccessful, handle that here
	if not test_parse == Error.OK:
		head_button_save.disabled = true
		code_error_footer.visible = true
		code_error_text.text = "Error on Line %s: %s" % [str(json.get_error_line()), json.get_error_message()]
		print()
		return
	
	code_error_footer.visible = false
	head_button_save.disabled = false

func code_editor_close(text: String = "Open a file or change edit mode in the top bar") -> void:
	unsaved_changes = false
	
	open_file_path = ""
	code_editor.editable = false
	code_editor.text = ""
	code_editor.placeholder_text = text
	head_button_save.disabled = true
	code_error_footer.visible = false

func code_editor_open() -> void:
	unsaved_changes = false
	
	code_editor.editable = true
	code_editor.text = ""
	code_editor.placeholder_text = ""
	head_button_save.disabled = false
	code_error_footer.visible = false

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
	
	unsaved_changes = false
	
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

func apply_theme() -> void:
	if is_instance_valid(editor_plugin) and is_instance_valid(code_editor):
		var scale: float = editor_plugin.get_editor_interface().get_editor_scale()
		var set = editor_plugin.get_editor_interface().get_editor_settings()
		var highlight: CodeHighlighter = code_editor.syntax_highlighter
		
		head_button_add.icon = get_theme_icon("Add", "EditorIcons")
		head_button_new.icon = get_theme_icon("New", "EditorIcons")
		head_button_load.icon = get_theme_icon("Load", "EditorIcons")
		head_button_save.icon = get_theme_icon("Save", "EditorIcons")
		head_button_info.icon = get_theme_icon("Help", "EditorIcons")
		head_button_close.icon = get_theme_icon("Back", "EditorIcons")
		
		code_editor.add_theme_color_override("background_color", set.get_setting("text_editor/theme/highlighting/background_color"))
		highlight.number_color = set.get_setting("text_editor/theme/highlighting/number_color")
		highlight.symbol_color = set.get_setting("text_editor/theme/highlighting/symbol_color")
		highlight.function_color = set.get_setting("text_editor/theme/highlighting/function_color")
		highlight.member_variable_color = set.get_setting("text_editor/theme/highlighting/member_variable_color")
		
		highlight.add_keyword_color("var", set.get_setting("text_editor/theme/highlighting/keyword_color"))
		highlight.add_keyword_color("const", set.get_setting("text_editor/theme/highlighting/keyword_color"))
		
		highlight.add_keyword_color("int", set.get_setting("text_editor/theme/highlighting/base_type_color"))
		highlight.add_keyword_color("float", set.get_setting("text_editor/theme/highlighting/base_type_color"))
		highlight.add_keyword_color("String", set.get_setting("text_editor/theme/highlighting/base_type_color"))
		highlight.add_keyword_color("Vector2", set.get_setting("text_editor/theme/highlighting/base_type_color"))
		highlight.add_keyword_color("Vector2i", set.get_setting("text_editor/theme/highlighting/base_type_color"))
		highlight.add_keyword_color("Vector2i", set.get_setting("text_editor/theme/highlighting/base_type_color"))
		highlight.add_keyword_color("Vector3", set.get_setting("text_editor/theme/highlighting/base_type_color"))
		highlight.add_keyword_color("Vector3i", set.get_setting("text_editor/theme/highlighting/base_type_color"))
		highlight.add_keyword_color("Vector4", set.get_setting("text_editor/theme/highlighting/base_type_color"))
		highlight.add_keyword_color("Vector4i", set.get_setting("text_editor/theme/highlighting/base_type_color"))
		highlight.add_keyword_color("Quaternion", set.get_setting("text_editor/theme/highlighting/base_type_color"))
		highlight.add_keyword_color("Color", set.get_setting("text_editor/theme/highlighting/base_type_color"))
		highlight.add_keyword_color("Array", set.get_setting("text_editor/theme/highlighting/base_type_color"))
