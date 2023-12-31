extends Control

func _ready():
	SaveAccessor.save_slot_complete.connect(_on_slot_saved)
	SaveAccessor.load_slot_complete.connect(_on_slot_loaded)
	SaveAccessor.save_error.connect(_on_save_error)
	SaveAccessor.load_error.connect(_on_load_error)
	SaveAccessor.thread_busy.connect(_on_thread_busy)
	SaveAccessor.thread_complete.connect(_on_thread_complete)

func _process(_delta):
	%ProgressSlider.value = SaveHolder.slot.progress

func _on_h_slider_changed(value: float):
	SaveHolder.slot.progress = value

func _on_spin_box_value_changed(value: int):
	SaveAccessor.set_active_slot(value)

func _on_button_save_pressed():
	SaveAccessor.write_active_slot()

func _on_button_load_pressed():
	SaveAccessor.read_active_slot()

func _on_autosave_button_save_pressed():
	SaveAccessor.write_autosave_slot()

func _on_autosave_button_load_pressed():
	SaveAccessor.read_autosave_slot()

func _on_slot_saved():
	%SignalNotif.text = "Signal: Save Completed"
	
func _on_slot_loaded():
	%SignalNotif.text = "Signal: Load Completed"
	
func _on_save_error():
	%SignalNotif.text = "Signal: Save Errored"
	
func _on_load_error():
	%SignalNotif.text = "Signal: Load Errored"

func _on_thread_busy():
	%ThreadNotif.text = "Thread Busy!"
	
func _on_thread_complete():
	%ThreadNotif.text = "Thread Inactive"
