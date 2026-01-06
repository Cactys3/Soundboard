extends Control
class_name Option
@export var line_edit: LineEdit
@export var play_button: Button 
const CONTEXTMENU = preload("uid://b8gmq0nupsndv")
var option_name: String
var method: Callable
var audio: AudioStreamPlayer
var filepath: String 
var playing: bool = false
var looping: bool = false
var hovering: bool = false
var option_volume: float = 1
var stream: AudioStream
var repeating: bool = false
var pausing: bool = false
var restarting: bool = true
var soundboard: Soundboard
var volume_offset: float = 0.1
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
	stream = new_audio.stream
	soundboard = new_soundboard
	option_name = new_name
	filepath = new_name
	audio = new_audio
	soundboard.popup_parent.add_child(audio)
	var pack: PackedStringArray = new_name.split('\\')
	if pack.size() == 1:
		pack = new_name.split('/')
	line_edit.text = pack[pack.size() - 1].split(".")[0]
	audio.finished.connect(done_playing)
func _on_play_pressed() -> void:
	#audio.queue_free()
	#audio = AudioStreamPlayer.new()
	#audio.stream = stream
	#soundboard.add_child(audio)
	#play(audio)
	#return
	if repeating:
		var new_audio: AudioStreamPlayer = AudioStreamPlayer.new()
		new_audio.stream = stream
		add_child(new_audio)
		play(new_audio)
		repeating_audios.append(new_audio)
	elif pausing:
		if paused:
			audio.stream_paused = false
			paused = false
		else:
			if !playing:
				play(audio)
				playing = !playing
			else:
				audio.stream_paused = true
				paused = true
	elif restarting:
		if !playing:
			play(audio)
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
		play_button.text = "Play (Multiple)"
	elif pausing:
		if paused:
			play_button.text = "Paused " + str(int(audio.get_playback_position())) + "/" + str(int(audio.stream.get_length()))
		elif playing:
			play_button.text = "Stop " + str(int(audio.get_playback_position())) + "/" + str(int(audio.stream.get_length()))
		else:
			play_button.text = "Play"
	elif restarting:
		if playing:
			play_button.text = "Stop " + str(int(audio.get_playback_position())) + "/" + str(int(audio.stream.get_length()))
		else:
			play_button.text = "Play"
func play(player: AudioStreamPlayer):
	set_volume(player)
	player.play()
func set_volume(player: AudioStreamPlayer):
	player.volume_linear = clamp((option_volume * soundboard.global_volume) * volume_offset, 0, 2)
func open_context_menu():
	menu = CONTEXTMENU.instantiate()
	if ContextParent.instance:
		ContextParent.instance.add_child(menu)
		ContextParent.instance.visible = true
	else:
		add_child(menu)
	soundboard.clamp_on_position(get_global_mouse_position(), menu)
	menu.setup(self, restarting, repeating, pausing, looping, soundboard.is_saved(filepath), option_volume)
func done_playing():
	if !repeating:
		playing = false
		play_button.text = "Play"
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
	stop_all_sounds()
	die()
func _on_mouse_entered() -> void:
	hovering = true
func _on_mouse_exited() -> void:
	hovering = false
func volume(new_volume: float, max_volume: float):
	option_volume = (new_volume / max_volume) * 2
	var popup: PopupLabel = soundboard.POPUP.instantiate()
	soundboard.popup_parent.add_child(popup)
	soundboard.call_deferred("clamp_on_position", get_global_mouse_position() + Vector2(20, -10), popup)
	popup.setup("Volume: " + str(int(option_volume * 100)) + "%", 1)
	volume_changed()
func volume_changed():
	if restarting || looping:
		set_volume(audio)
	if repeating:
		for repeat_audio in repeating_audios:
			set_volume(repeat_audio)
func die():
	queue_free()
	if soundboard.Files.has(filepath):
		soundboard.Files.erase(filepath)
	if soundboard.Options.has(self):
		soundboard.Options.erase(self)
