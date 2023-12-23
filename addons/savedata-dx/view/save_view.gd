@tool
extends Control

#region Constants and Node References

# SaveData accessor script
const accessor_script = preload("res://addons/savedata-dx/backend/save_accessor.gd")
var accessor_inst = null

# Reference to editor plugin
var editor_plugin: EditorPlugin

# Constants
const root_slot_path: String = "res://addons/savedata-dx/data_slot.gd"
const root_common_path: String = "res://addons/savedata-dx/data_common.gd"

const max_search_results: int = 50

# Header buttons
@onready var head_button_load := %HeadLoad
@onready var head_button_save := %HeadSave
@onready var head_button_edit_slot := %HeadEditSlot
@onready var head_button_edit_common := %HeadEditCommon
@onready var head_button_settings := %HeadSettings
@onready var head_button_info := %HeadInfo
@onready var head_button_close := %HeadClose

# Search window
@onready var search_box := %SearchBox
@onready var search_result_box := %SearchResultBox

# Code editor
@onready var code_editor := %CodeEdit
@onready var code_error_footer := %ErrorFooter
@onready var code_error_text := %ErrorText

# Dialog popups
@onready var inspector_file_dialog := $InspectorFileDialog
@onready var inspector_save_fail_dialog := $InspectorSaveFailDialog
@onready var settings_dialog := $SettingsDialog
@onready var settings_view := %SettingsView

#endregion

#region State Variables

# Current editor information
var open_file_path: String

var unsaved_changes: bool = false:
	set (value):
		if value:
			head_button_save.text = " Save*"
		else:
			head_button_save.text = " Save"
		
		unsaved_changes = value

#endregion

#region Virtual Functions

func _ready() -> void:
	if not is_instance_valid(editor_plugin):
		return
	
	# Setup save accessor
	accessor_inst = accessor_script.new()
	add_child(accessor_inst)
	
	# Disable save button
	code_editor_close()
	
	# Ensure the save directory in user folder
	DirAccess.make_dir_recursive_absolute(accessor_inst.SAVE_DIR)
	
	# Setup settings menu dialog
	settings_dialog.theme = EditorInterface.get_editor_theme()
	settings_view.main_view = self
	
	apply_theme()

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
			"Ctrl+W", "Command+W":
				get_viewport().set_input_as_handled()
				_on_head_close_pressed()

#endregion

#region Header Button Interactions

func _on_head_load_pressed():
	inspector_file_dialog.popup()

func _on_head_save_pressed():
	if open_file_path.is_empty():
		return
	
	# If in inspector mode, verify user input and then write to disk
	var test_parse = JSON.parse_string(code_editor.text)
	if test_parse == null:
		inspector_save_fail_dialog.popup()
		return
	
	unsaved_changes = false
	accessor_inst._write_backend_with_json_string(open_file_path, code_editor.text)

func _on_head_edit_slot_pressed():
	var script: Script = load("res://addons/savedata-dx/data_slot.gd")
	EditorInterface.edit_script(script)
	EditorInterface.set_main_screen_editor("Script")

func _on_head_edit_common_pressed():
	var script: Script = load("res://addons/savedata-dx/data_common.gd")
	EditorInterface.edit_script(script)
	EditorInterface.set_main_screen_editor("Script")

func _on_head_settings_pressed():
	settings_dialog.popup()

func _on_head_info_pressed():
	OS.shell_open("https://github.com/Amethyst-szs/godot-savedata-dx/wiki")

func _on_head_close_pressed():
	code_editor_close()
	head_button_close.disabled = true

#endregion

#region Decrypt Save Data

# Called upon selecting a file in the debugger mode
func _on_inspector_select_file(path: String) -> void:
	var data: String = accessor_inst._read_backend_raw_data(path)
	if data.is_empty():
		code_editor_close("Save data could not be opened, check output for more info")
		return
	
	# Copy the selected file's path to the open file path variable
	open_file_path = path
	
	# Setup code editor
	head_button_close.disabled = false
	code_editor_open()
	code_editor.text = data

#endregion

#region JSON Searching

func update_text_search(text: String = ""):
	# Clear out the list of search results
	search_box.clear()
	
	for child in search_result_box.get_children():
		search_result_box.remove_child(child)
	
	if open_file_path.is_empty() or text.is_empty():
		code_editor.remove_search_highlight()
		return
	
	var index_list: Array[int] = code_editor.setup_search_highlight(text)
	
	# Ensure there is at least one index in list
	if index_list.is_empty():
		return
	
	# Load in the new search results
	for index in range(min(index_list.size(), max_search_results)):
		var button := Button.new()
		var line_text: String = code_editor.get_line(index_list[index])
		line_text = line_text.replace("\t", "")
		line_text = line_text.replace("\"", "")
		line_text = line_text.replace(",", "")
		
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = line_text
		
		button.pressed.connect(_jump_to_search_result.bind(index_list[index]))
		search_result_box.add_child(button)
	
	# Add notice to bottom if not every result was given a button
	if index_list.size() > max_search_results:
		var label := Label.new()
		label.text = "...and %s more results" % [index_list.size() - max_search_results]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		search_result_box.add_child(label)

func _on_search_box_submitted(new_text: String):
	update_text_search(new_text)

func _on_search_button():
	update_text_search(search_box.text)

func _jump_to_search_result(line: int):
	code_editor.set_caret_line(line)

#endregion

#region Utility

func _on_code_edit_text_changed():
	unsaved_changes = true
	$CompileTimer.start()

func _on_compile_timer_timeout():
	# Try parsing the JSON
	var json: JSON = JSON.new()
	var test_parse: Error = json.parse(code_editor.text)
	
	# If the parse was unsuccessful, handle that here
	if not test_parse == Error.OK:
		head_button_save.disabled = true
		code_error_footer.visible = true
		code_error_text.text = "Error on Line %s: %s" % [str(json.get_error_line()), json.get_error_message()]
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
	
	update_text_search()
	
	code_editor.clear_undo_history()

func code_editor_open() -> void:
	unsaved_changes = false
	
	code_editor.editable = true
	code_editor.text = ""
	code_editor.placeholder_text = ""
	head_button_save.disabled = false
	code_error_footer.visible = false
	
	update_text_search()
	
	code_editor.clear_undo_history()

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
	
	update_text_search()
	
	code_editor.clear_undo_history()

func apply_theme() -> void:
	if is_instance_valid(editor_plugin) and is_instance_valid(code_editor):
		var scale: float = editor_plugin.get_editor_interface().get_editor_scale()
		var set = editor_plugin.get_editor_interface().get_editor_settings()
		var highlight: CodeHighlighter = code_editor.syntax_highlighter
		
		head_button_load.icon = get_theme_icon("Load", "EditorIcons")
		head_button_save.icon = get_theme_icon("Save", "EditorIcons")
		head_button_edit_slot.icon = get_theme_icon("Edit", "EditorIcons")
		head_button_edit_common.icon = get_theme_icon("EditInternal", "EditorIcons")
		head_button_settings.icon = get_theme_icon("Tools", "EditorIcons")
		head_button_info.icon = get_theme_icon("Help", "EditorIcons")
		head_button_close.icon = get_theme_icon("Back", "EditorIcons")
		
		code_editor.add_theme_color_override("background_color", set.get_setting("text_editor/theme/highlighting/background_color"))
		highlight.number_color = set.get_setting("text_editor/theme/highlighting/number_color")
		highlight.symbol_color = set.get_setting("text_editor/theme/highlighting/symbol_color")
		highlight.function_color = set.get_setting("text_editor/theme/highlighting/function_color")
		highlight.member_variable_color = set.get_setting("text_editor/theme/highlighting/member_variable_color")

#endregion
