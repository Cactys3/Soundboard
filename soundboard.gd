extends Control
class_name Soundboard
@export var grid: GridContainer
@export var randomize_colors: Button 
@export var search: LineEdit 
@export var volume_slider: VSlider
@export var popup_parent: Control
@export var description: RichTextLabel
const OPTION = preload("uid://dg0hl4dpjiqhh")
const CONFIRMATION = preload("uid://cknxag736p0rx")
const POPUP = preload("uid://capfc3v3d41ut")
## In Percent from 0 to 2 
var global_volume: float = 1
var option_size: Vector2 = Vector2(150, 80)
var Options: Array[Option]
var Files: Array[String]
var SavedFiles: Array[String] 
var PopupQueue: Array[Pop]
var folder: String = "res://SavedAudio/"
var timer: float = 0
func _ready() -> void:
	description.meta_clicked.connect(_on_meta_clicked)
	var exe_folder = OS.get_executable_path().get_base_dir()
	folder = exe_folder + "/SavedAudio/"
	folder = folder.replace("\\", "/")
	get_window().files_dropped.connect(drop_file)
	get_window().size_changed.connect(resize)
	create_folder_if_needed(folder)
	SavedFiles = get_files_in_folder(folder)
	drop_file(get_files_in_folder(folder))
	search.text_changed.connect(edit_search)
	volume_slider.value_changed.connect(volume)
	call_deferred("resize")
	var save_value: float = read_number_from_json(folder)
	if save_value != -999 && save_value != 1:
		volume_slider.value = (save_value * volume_slider.max_value) / 2
		global_volume = (volume_slider.value / volume_slider.max_value) * 2
		var popup: PopupLabel = POPUP.instantiate()
		popup_parent.add_child(popup)
		call_deferred("clamp_on_position", get_viewport().get_visible_rect().end * Vector2(1, -1), popup)
		popup.setup("Saved Application Volume: " + str(int(save_value * 100)) + "%", 2)
	tree_exited.connect(save_volume)
func _on_meta_clicked(meta):
	OS.shell_open(meta)
func save_volume():
	write_number_to_json(folder, global_volume)
func _process(delta: float) -> void:
	timer += delta
	if timer > 5:
		timer = 0
		refresh()
func refresh():
	for file in get_files_in_folder(folder):
		if !SavedFiles.has(file) && !Files.has(file):
			SavedFiles.append(file)
			drop_file([file])
func drop_file(files: Array[String]):
	var drop: Drop = Drop.new()
	drop.files = files
	drop.location = get_global_mouse_position()
	handle_drop(drop)
## Evaluates the file from drop.filepath, adding a soundbyte option if it's valid
func handle_drop(drop: Drop):
	var files = drop.files
	for file in files:
		var breaking: bool = false
		if file.to_lower().ends_with(".ogg") || file.to_lower().ends_with(".wav") || file.to_lower().ends_with(".mp3"):
			var pack: PackedStringArray = file.split('\\')
			var filename: String = pack[pack.size() - 1]
			## On Duplicate Soundbyte dragged in, Confirm with User that they want to add the duplicate
			print("")
			for filez in Files:
				print(filez + " Eq: " + str(filez == file))
			print("File: " + file)
			if Files.has(file):
				var confirmation: Confirmation = CONFIRMATION.instantiate()
				ContextParent.instance.add_child(confirmation)
				ContextParent.instance.visible = true
				clamp_on_position(get_global_mouse_position(), confirmation)
				var sig: Signal = confirmation.setup("Add Duplicate: " + filename + "?")
				var answer: bool = await sig
				if !answer:
					breaking = true
			else:
				Files.append(file)
			if !breaking:
				var stream: AudioStream = load_audio_file(file)
				if stream == null:
					breaking = true
				if !breaking:
					var option: Option = OPTION.instantiate()
					grid.add_child(option)
					var player: AudioStreamPlayer = AudioStreamPlayer.new()
					player.stream = stream
					if !SavedFiles.has(file):
						add_child(player)
						player.volume_linear = 0.5
						player.play()
						remove_child(player)
					option.setup(self, file, player)
					Options.append(option)
					option.size = option_size
					option.custom_minimum_size = option_size
func save_option(filepath: String, new_name: String):
	create_folder_if_needed(folder)
	new_name = new_name.replace(" ", "_")
	new_name = new_name.replace("\n", "_")
	new_name = new_name.validate_filename()
	if new_name.length() > 32:
		new_name = new_name.substr(0, 32) + "." + filepath.get_extension()
	if !SavedFiles.has(filepath) || filepath.get_file() != new_name:
		if filepath.get_file() != new_name:
			copy_file_to_folder(filepath, new_name)
			if SavedFiles.has(filepath):
				SavedFiles.erase(filepath)
				remove_file_from_folder(filepath)
		else:
			copy_file_to_folder(filepath, filepath.get_file())
		Files.erase(filepath)
		refresh()
func delete_option(filepath: String):
	Files.erase(filepath)
	if SavedFiles.has(filepath):
		SavedFiles.erase(filepath)
		remove_file_from_folder(filepath)
func is_saved(filepath: String):
	return SavedFiles.has(filepath)
func resize():
	var new_size: Vector2 = get_window().size
	var NumWillFit: float
	if new_size.x < 400:
		randomize_colors.visible = false
	else:
		randomize_colors.visible = true
	NumWillFit = (new_size.x / option_size.x) - 1
	grid.columns = roundi(NumWillFit)
func volume(_new_volume: float):
	global_volume = (volume_slider.value / volume_slider.max_value) * 2
	var popup: PopupLabel = POPUP.instantiate()
	popup_parent.add_child(popup)
	call_deferred("clamp_on_position", get_global_mouse_position(), popup)
	popup.setup("Volume: " + str(int(global_volume * 100)) + "%", 1.5)
	for option in Options:
		option.volume_changed()
func edit_search(text: String):
	var queries: PackedStringArray = search.text.split(" ")
	var empty: bool = true
	if !queries.size() == 0:
		for q in queries:
			if q.replace(" ", "") != "":
				empty = false
	if !empty:
		for option in Options:
			var is_it_good: bool = false
			for query in queries:
				if option.option_name.to_lower().replace(" ", "").contains(query.to_lower().replace(" ", "")):
					is_it_good = true
			if is_it_good:
				option.visible = true
			else:
				option.visible = false
	else:
		for option in Options:
			option.visible = true
func clamp_on_position(drop_location: Vector2, drop_item: Control):
	if drop_location == null:
		drop_location = get_global_mouse_position()
	var window_size = get_viewport_rect().size
	drop_item.position = Vector2(
		clamp(drop_location.x, 0, window_size.x - (drop_item.size.x + 15)),
		clamp(drop_location.y, 0, window_size.y - (drop_item.size.y + 15))
	)
func _on_randomize_colors_pressed() -> void:
	pass # Replace with function body.
func _on_stop_all_sounds_pressed() -> void:
	for option in Options:
		option.stop_all_sounds()
func make_popup(text: String, duration: float):
	var pop = Pop.new()
	pop.duration = duration
	pop.text = text
	PopupQueue.append(pop)
	if PopupQueue.size() == 1:
		handle_popup(pop)
	else:
		PopupQueue.append(pop)
func handle_popup(pop: Pop):
	## Check because this method is called when things exit tree (application is closed)
	if !get_viewport():
		return
	var popup: PopupLabel = POPUP.instantiate()
	popup_parent.add_child(popup)
	popup.global_position = get_viewport().get_visible_rect().size * 0.5
	call_deferred("clamp_on_position", get_viewport().get_visible_rect().size * 0.5, popup)
	popup.setup(pop.text, pop.duration)
	await popup.tree_exited
	PopupQueue.erase(pop)
	if !PopupQueue.is_empty():
		handle_popup(PopupQueue[0])
class Drop:
	var files: Array[String]
	var location: Vector2
	func setup(new_file: Array[String], new_location: Vector2):
		files = new_file
		location = new_location
class Pop:
	var text: String
	var duration: float
## Claude:
func load_audio_file(file_path: String) -> AudioStream:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		make_popup("File: " + file_path.get_file() + "\n" + "Failed to open file" + "\n" + file_path, 4)
		return null
	var audio_data = file.get_buffer(file.get_length())
	file.close()
	var audio_stream: AudioStream
	if file_path.ends_with(".mp3"):
		audio_stream = AudioStreamMP3.new()
		audio_stream.data = audio_data
	elif file_path.ends_with(".ogg"):
		audio_stream = AudioStreamOggVorbis.load_from_buffer(audio_data)
	elif file_path.ends_with(".wav"):
		audio_stream = load_wav_as_audiostream(file_path)#AudioStreamWAV.new()
	else:
		make_popup("File: " + file_path.get_file() + "\n" + "Unsupported audio format:" + "\n" + file_path, 4)
		return null
	return audio_stream
func get_files_in_folder(folder_path: String) -> Array[String]:
	var files: Array[String] = []
	var dir = DirAccess.open(folder_path)
	if dir == null:
		return files
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		var file: String = (folder_path + "/" + file_name).replace("//", "\\")
		file = file.replace("/", "\\")
		files.append(file)
		file_name = dir.get_next()
	dir.list_dir_end()
	return files
func copy_file_to_folder(filepath: String, filename: String) -> bool:
	var destination = folder + "/" + filename
	if destination == filepath:
		return false
	var err = DirAccess.copy_absolute(filepath, destination)
	if err != OK:
		push_error("Failed to copy file: " + str(err))
		return false
	return true
func remove_file_from_folder(filepath: String) -> bool:
	var filename = filepath.get_file()
	var destination = folder + "/" + filename
	
	# Convert res:// or user:// to absolute path
	destination = ProjectSettings.globalize_path(destination)
	
	# Check if file exists
	if !FileAccess.file_exists(destination):
		push_error("File does not exist: " + destination)
		return false
	
	var err = OS.move_to_trash(destination)
	if err != OK:
		push_error("Failed to move file to trash: " + str(err))
		return false
	return true
func load_wav_as_audiostream(file_path: String) -> AudioStreamWAV:
	if not FileAccess.file_exists(file_path):
		make_popup("Invalid File: " + file_path.get_file() + " - WAV file not found" + "\n" + file_path + "\nTry converting WAV files to mp3 online! (google 'WAV to mp3')", 4)
		return null
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		make_popup("Invalid File: " + file_path.get_file() + " - Cannot open WAV file" + "\n" + file_path + "\nTry converting WAV files to mp3 online! (google 'WAV to mp3')", 4)
		return null
	var riff = file.get_buffer(4).get_string_from_ascii()
	if riff != "RIFF":
		make_popup("Invalid File: " + file_path.get_file() + " - Invalid WAV file: missing RIFF header" + "\n" + file_path + "\nTry converting WAV files to mp3 online! (google 'WAV to mp3')", 4)
		return null
	file.get_32()
	var wave = file.get_buffer(4).get_string_from_ascii()
	if wave != "WAVE":
		make_popup("Invalid File: " + file_path.get_file() + " - Invalid WAV file: missing WAVE signature" + "\n" + file_path + "\nTry converting WAV files to mp3 online! (google 'WAV to mp3')", 4)
		return null
	var fmt_data = _find_wav_chunk(file, "fmt ")
	if fmt_data == null:
		make_popup("Invalid File: " + file_path.get_file() + " - Invalid WAV file: missing fmt chunk" + "\n" + file_path + "\nTry converting WAV files to mp3 online! (google 'WAV to mp3')", 4)
		return null
	var audio_format = fmt_data.get_16()
	var channels = fmt_data.get_16()
	var sample_rate = fmt_data.get_32()
	var bits_per_sample = fmt_data.get_16()
	if audio_format != 1:
		make_popup("Invalid File: " + file_path.get_file() + " - Unsupported WAV format: %d (only PCM is supported)" % audio_format + "\n" + file_path + "\nTry converting WAV files to mp3 online! (google 'WAV to mp3')", 4)
		return null
	if bits_per_sample not in [8, 16]:
		make_popup("Invalid File: " + file_path.get_file() + " - Unsupported bit depth: %d (only 8 and 16 bit supported)" % bits_per_sample + "\n" + file_path + "\nTry converting WAV files to mp3 online! (google 'WAV to mp3')", 4)
		return null
	var audio_data = _find_wav_chunk(file, "data")
	if audio_data == null:
		make_popup("Invalid File: " + file_path.get_file() + " - Invalid WAV file: missing data chunk" + "\n" + file_path + "\nTry converting WAV files to mp3 online! (google 'WAV to mp3')", 4)
		return null
	var audio_stream = AudioStreamWAV.new()
	audio_stream.mix_rate = sample_rate
	audio_stream.stereo = (channels == 2)
	if bits_per_sample == 8:
		audio_stream.format = AudioStreamWAV.FORMAT_8_BITS
	else:
		audio_stream.format = AudioStreamWAV.FORMAT_16_BITS
	var data_size = audio_data.get_length()
	var audio_buffer = audio_data.get_buffer(data_size)
	audio_stream.data = audio_buffer
	return audio_stream
func _find_wav_chunk(file: FileAccess, chunk_id: String) -> FileAccess:
	file.seek(12)
	while not file.eof_reached():
		var chunk_header = file.get_buffer(4)
		if chunk_header.size() < 4:
			break
		var chunk_name = chunk_header.get_string_from_ascii()
		var chunk_size = file.get_32()
		if chunk_name == chunk_id:
			var chunk_data = file.get_buffer(chunk_size)
			if chunk_data.size() > 0:
				var chunk_stream = FileAccess.open("user://temp_chunk.tmp", FileAccess.WRITE)
				chunk_stream.store_buffer(chunk_data)
				chunk_stream = FileAccess.open("user://temp_chunk.tmp", FileAccess.READ)
				return chunk_stream
			return null
		else:
			file.seek(file.get_position() + chunk_size + (chunk_size % 2))
	return null
func write_number_to_json(folder_path: String, number: float) -> bool:
	var file_path = folder_path + "save.json"
	var json_data = {"value": number}
	var json_string = JSON.stringify(json_data)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(json_string)
	return true
func read_number_from_json(folder_path: String) -> float:
	var file_path = folder_path + "save.json"
	if not FileAccess.file_exists(file_path):
		return -999
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		make_popup("For File: save.json - Failed to read number from JSON", 3)
		return -999
	var json_string = file.get_as_text()
	var json = JSON.new()
	if json.parse(json_string) != OK:
		return -999
	var json_data = json.data
	if json_data == null or !json_data.has("value"):
		return -999
	return json_data["value"]
func create_folder_if_needed(folder_path: String) -> bool:
	if not DirAccess.dir_exists_absolute(folder_path):
		var err = DirAccess.make_dir_recursive_absolute(folder_path)
		return err == OK
	return false
