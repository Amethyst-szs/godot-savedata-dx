extends Node2D

func _process(_delta):
	%Slider.value = SaveHolder.save_common.progress

func _on_slider_value_changed(value):
	SaveHolder.save_common.progress = value

func _on_save_pressed():
	SaveAccessor.write_common()

func _on_load_pressed():
	SaveAccessor.read_common()
