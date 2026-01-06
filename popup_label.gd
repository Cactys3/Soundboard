extends Label
class_name PopupLabel
var start: bool = false
var timer: float = 0
var max_time: float = 1
static var us: Array[PopupLabel]
func setup(new_text: String, new_max_time: float):
	for one_of_us in us:
		one_of_us.queue_free()
	us.clear()
	us.append(self)
	text = new_text
	max_time = new_max_time
	timer = 0
	start = true
func _process(delta: float) -> void:
	if start:
		timer += delta
		if timer >= max_time:
			queue_free()
			us.erase(self)
