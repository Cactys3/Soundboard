extends Control
class_name ContextMenu
@export var multiple: Button
@export var restart: Button
@export var pause: Button
@export var save: Button
@export var delete: Button 
@export var stop_all_sounds: Button 
@export var loop: Button 

var option: Option
var unloop: bool = false

func _process(_delta: float) -> void:
	if Input.is_action_just_released("LeftClick"):
		queue_free()
		ContextParent.instance.visible = false

var already_saved: bool

func setup(new_option: Option, restarting: bool, repeating: bool, pausing: bool, looping: bool, saved: bool):
	option = new_option
	unloop = !looping
	already_saved = saved
	if restarting:
		restart.text = "Restart On Click✔"
	if repeating:
		multiple.text = "Play Multiple On Click✔"
	if pausing:
		pause.text = "Pause On Click✔"
	if !looping:
		loop.text = "Disable Loop"
	if saved:
		save.text = "Rename (Saved✔)"

func _on_repeat_pressed() -> void:
	option.repeat()
func _on_save_pressed() -> void:
	option.save(already_saved)
func _on_delete_pressed() -> void:
	option.delete()
func _on_stop_all_sounds_pressed() -> void:
	option.stop_all_sounds()
func _on_restart_pressed() -> void:
	option.restart()
func _on_pause_pressed() -> void:
	option.pause()
func _on_loop_pressed() -> void:
	option.loop()
