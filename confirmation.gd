extends Control
class_name Confirmation
signal confirm
@export var label: Label

func setup(text: String) -> Signal:
	label.text = text
	return confirm

func _on_yes_pressed() -> void:
	confirm.emit(true)
	queue_free()
	ContextParent.instance.visible = false
func _on_no_pressed() -> void:
	confirm.emit(false)
	queue_free()
	ContextParent.instance.visible = false
