extends Control
class_name Soundboard
@export var grid: GridContainer
@export var randomize_colors: Button 
@export var search: LineEdit 

const OPTION = preload("uid://dg0hl4dpjiqhh")
const CONFIRMATION = preload("uid://cknxag736p0rx")

var option_size: Vector2 = Vector2(150, 80)

var Options: Array[Option]
var Files: Array[String]
var SavedFiles: Array[String] 
var Queue: Array[Drop]

var folder: String = "res://SavedAudio/"
 
var timer: float = 0
func _ready() -> void:
	get_window().files_dropped.connect(drop_file)
	get_window().size_changed.connect(resize)
	SavedFiles = get_files_in_folder(folder)
	drop_file(get_files_in_folder("res://SavedAudio/"))
	search.text_changed.connect(edit_search)

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
	if Queue.is_empty():
		handle_drop(drop)
	else:
		Queue.append(drop)

func handle_drop(drop: Drop):
	var files = drop.files
	for file in files:
		if file.to_lower().ends_with(".ogg") || file.to_lower().ends_with(".wav") || file.to_lower().ends_with(".mp3"):
			var pack: PackedStringArray = file.split('\\')
			var filename: String = pack[pack.size() - 1]
			if Files.has(filename):
				var confirmation: Confirmation = CONFIRMATION.instantiate()
				ContextParent.instance.add_child(confirmation)
				ContextParent.instance.visible = true
				var mouse_pos = drop.location
				var window_size = get_viewport_rect().size
				confirmation.position = Vector2(
					clamp(mouse_pos.x, 0, window_size.x - confirmation.size.x),
					clamp(mouse_pos.y, 0, window_size.y - confirmation.size.y)
				)
				var sig: Signal = confirmation.setup("Add Duplicate: " + filename + "?")
				var answer: bool = await sig
				if !answer:
					return
			else:
				Files.append(file)
			var option: Option = OPTION.instantiate()
			grid.add_child(option)
			var stream: AudioStreamPlayer = AudioStreamPlayer.new()
			stream.stream = load_audio_file(file)
			option.setup(self, file, stream)
			Options.append(option)
			option.size = option_size
			option.custom_minimum_size = option_size
		elif file.to_lower().ends_with(".mp4"):
			pass
	if !Queue.is_empty():
		handle_drop(Queue[0])

func save_option(filepath: String, new_name: String):
	new_name = new_name.replace(" ", "_")
	new_name = new_name.replace("\n", "_")
	new_name = new_name.validate_filename()
	if new_name.length() > 32:
		new_name = new_name.substr(0, 32) + "." + filepath.get_extension()
	print(new_name)
	print(new_name.validate_filename())
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

func edit_search():
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

func load_audio_file(file_path: String) -> AudioStream:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file: " + file_path)
		return null
	# Read the file data
	var audio_data = file.get_buffer(file.get_length())
	file.close()
	# Create the appropriate AudioStream based on extension
	var audio_stream: AudioStream
	if file_path.ends_with(".mp3"):
		audio_stream = AudioStreamMP3.new()
		audio_stream.data = audio_data
	elif file_path.ends_with(".ogg"):
		audio_stream = AudioStreamOggVorbis.new()
		audio_stream.data = audio_data
	elif file_path.ends_with(".wav"):
		audio_stream = AudioStreamWAV.new()
		audio_stream.data = audio_data
	else:
		push_error("Unsupported audio format: " + file_path)
		return null
	return audio_stream
func get_files_in_folder(folder_path: String) -> Array[String]:
	var files: Array[String] = []
	var dir = DirAccess.open(folder_path)
	if dir == null:
		push_error("Failed to open directory: " + folder_path)
		return files
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if !dir.current_is_dir():  # Skip subdirectories
			files.append(folder_path + "/" + file_name)
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
class Drop:
	var files: Array[String]
	var location: Vector2
	func setup(new_file: Array[String], new_location: Vector2):
		files = new_file
		location = new_location

func _on_randomize_colors_pressed() -> void:
	pass # Replace with function body.

func _on_stop_all_sounds_pressed() -> void:
	for option in Options:
		option.stop_all_sounds()
