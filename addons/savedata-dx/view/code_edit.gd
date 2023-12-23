@tool
extends CodeEdit

var highlight_color: Color = Color.BLACK

func _ready():
	if not Engine.is_editor_hint():
		queue_free()
		return
	
	var settings = EditorInterface.get_editor_settings()
	highlight_color = settings.get_setting("text_editor/theme/highlighting/background_color")
	highlight_color = highlight_color.lightened(0.15)

func setup_search_highlight(search: String):
	var index_list: Array[int] = []
	
	for line in range(get_line_count()):
		var text: String = get_line(line)
		if text.findn(search) != -1:
			index_list.push_back(line)
			set_line_background_color(line, highlight_color)
		else:
			set_line_background_color(line, Color(0, 0, 0, 0))
	
	return index_list

func remove_search_highlight():
	for line in range(get_line_count()):
		set_line_background_color(line, Color(0, 0, 0, 0))
