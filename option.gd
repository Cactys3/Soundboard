extends Control
class_name Option
@export var text_edit: TextEdit
@export var line_edit: LineEdit
@export var play: Button 
const CONTEXTMENU = preload("uid://b8gmq0nupsndv")

var option_name: String
var method: Callable
var audio: AudioStreamPlayer
var filepath: String 
var playing: bool = false
var looping: bool = false
var hovering: bool = false

var repeating: bool = false
var pausing: bool = false
var restarting: bool = true

var soundboard: Soundboard

var paused: bool = false
var repeating_audios: Array[AudioStreamPlayer]
static var menu: ContextMenu = null
var timer: float = 0.0
func _process(delta: float) -> void:
	## Once a second
	timer += delta
	if timer >= 1.0:
		timer -= 1.0
		set_label()
	if menu == null && hovering && Input.is_action_just_pressed("RightClick"):
		open_context_menu()

func setup(new_soundboard: Soundboard, new_name: String, new_audio: AudioStreamPlayer):
	soundboard = new_soundboard
	option_name = new_name
	filepath = new_name
	audio = new_audio
	add_child(audio)
	audio.volume_db = -20
	var pack: PackedStringArray = new_name.split('\\')
	if pack.size() == 1:
		pack = new_name.split('/')
	line_edit.text = pack[pack.size() - 1].split(".")[0]
	audio.finished.connect(done_playing)

func _on_play_pressed() -> void:
	if repeating:
		var new_audio: AudioStreamPlayer = audio.duplicate()
		add_child(new_audio)
		new_audio.play()
		repeating_audios.append(new_audio)
	elif pausing:
		if paused:
			audio.stream_paused = false
			paused = false
		else:
			if !playing:
				audio.play()
				playing = !playing
			else:
				audio.stream_paused = true
				paused = true
	elif restarting:
		if !playing:
			audio.play()
		else:
			audio.stop()
		playing = !playing
	set_label()
	## Reset Timer to align with seconds of sound
	timer = 0

func loop_play():
	playing = false
	_on_play_pressed()

func stop_all_sounds():
	audio.stop()
	playing = false
	for sound in repeating_audios:
		sound.stop()
		sound.queue_free()
	repeating_audios.clear()
	set_label()

func set_label():
	if repeating:
		play.text = "Play (Multiple)"
	elif pausing:
		if paused:
			play.text = "Paused " + str(int(audio.get_playback_position())) + "/" + str(int(audio.stream.get_length()))
		elif playing:
			play.text = "Stop " + str(int(audio.get_playback_position())) + "/" + str(int(audio.stream.get_length()))
		else:
			play.text = "Play"
	elif restarting:
		if playing:
			play.text = "Stop " + str(int(audio.get_playback_position())) + "/" + str(int(audio.stream.get_length()))
		else:
			play.text = "Play"

func open_context_menu():
	menu = CONTEXTMENU.instantiate()
	if ContextParent.instance:
		ContextParent.instance.add_child(menu)
		ContextParent.instance.visible = true
	else:
		add_child(menu)
	var mouse_pos = get_global_mouse_position()
	var window_size = get_viewport_rect().size
	menu.global_position = Vector2(clamp(mouse_pos.x, 0, window_size.x - menu.size.x), clamp(mouse_pos.y, 0, window_size.y - menu.size.y))
	menu.setup(self, restarting, repeating, pausing, looping, soundboard.is_saved(filepath))

func done_playing():
	if !repeating:
		playing = false
		play.text = "Play"
## Context Menu
func disable_loop():
	looping = false
	if audio.finished.is_connected(loop_play):
		audio.finished.disconnect(loop_play)
	if !audio.finished.is_connected(done_playing):
		audio.finished.connect(done_playing)
func loop():
	if !repeating:
		looping = true
		if !audio.finished.is_connected(loop_play):
			audio.finished.connect(loop_play)
		if audio.finished.is_connected(done_playing):
			audio.finished.disconnect(done_playing)
func pause():
	repeating = false
	restarting = false
	pausing = true
	playing = false
	audio.stream_paused = false
	stop_all_sounds()
	set_label()
func repeat():
	repeating = true
	restarting = false
	pausing = false
	playing = false
	audio.stream_paused = false
	disable_loop()
	stop_all_sounds()
	set_label()
func restart():
	repeating = false
	restarting = true
	pausing = false
	playing = false
	audio.stream_paused = false
	stop_all_sounds()
	set_label()
func save(already_saved: bool):
	soundboard.save_option(filepath, line_edit.text + "." + filepath.get_extension())
	if !already_saved || (filepath.get_file().split(".").size() > 0 && line_edit.text != filepath.get_file().split(".")[0]):
		die()
		if soundboard.Files.has(filepath):
			soundboard.Files.erase(filepath)
func delete():
	soundboard.delete_option(filepath)
	die()
func _on_mouse_entered() -> void:
	hovering = true
func _on_mouse_exited() -> void:
	hovering = false

func die():
	queue_free()
	if soundboard.Files.has(filepath):
		soundboard.Files.erase(filepath)
	if soundboard.Options.has(self):
		soundboard.Options.erase(self)
