extends Node2D

const ROOT_SCENE_PATH: String = "res://scenes/"  # Base path for scenes
const FISH_TEXTURE_FOLDER: String = "res://assets/fish/"  # Path to the fish texture folder

@export var spawn_interval: float = 2.0  # Time between spawns
@export var max_fish: int = 20  # Maximum number of fish in the scene
@export var target_time: float = 20.0  # Time to catch the target fish

var score: int = 0
var fish_textures: Array = []  # Array to store loaded fish textures
var target_fish_texture: Texture2D  # Texture for the target fish
var timer_running: bool = false

@onready var path_2d: Path2D = $Path2D  # First path for spawning fish
@onready var path_2d_2: Path2D = $Path2D2  # Second path for spawning fish
@onready var fish_scene: PackedScene = preload(ROOT_SCENE_PATH + "fish.tscn")  # Dynamic path to fish scene
@onready var hook: Area2D = $Hook  # Reference to the hook node
@onready var timer_bar: ProgressBar = $TimerBar  # Reference to the progress bar
@onready var target_fish_display: Sprite2D = $TargetFish  # Display for the target fish

func _ready():
	load_fish_textures()
	set_new_target_fish()
	timer_bar.max_value = target_time
	timer_bar.value = target_time
	spawn_fish_periodically()

# Load fish textures from the assets folder
func load_fish_textures():
	var dir = DirAccess.open(FISH_TEXTURE_FOLDER)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name:
			if file_name.ends_with(".png"):  # Check for image files
				var texture_path = FISH_TEXTURE_FOLDER + file_name
				var texture = load(texture_path)
				if texture and texture is Texture2D:
					fish_textures.append(texture)
			file_name = dir.get_next()
		dir.list_dir_end()

# Periodically spawn fish on paths
func spawn_fish_periodically():
	while true:
		var total_fish = path_2d.get_child_count() + path_2d_2.get_child_count()
		if total_fish < max_fish:
			spawn_fish()
		await get_tree().create_timer(spawn_interval).timeout

# Spawn a new fish at a random position along the selected path
func spawn_fish():
	var selected_path = path_2d if randf() > 0.5 else path_2d_2
	var curve_length = selected_path.curve.get_baked_length()
	var random_pos = selected_path.curve.sample_baked(randf_range(0, curve_length))

	var new_fish = fish_scene.instantiate()
	new_fish.position = random_pos

	if fish_textures.size() > 0 and new_fish.has_node("Sprite2D"):
		var fish_sprite = new_fish.get_node("Sprite2D") as Sprite2D
		fish_sprite.texture = fish_textures[randi() % fish_textures.size()]

	var fish_script = new_fish as Area2D
	if selected_path == path_2d:
		fish_script.direction = 1
	else:
		fish_script.direction = -1

	selected_path.add_child(new_fish)

# Set a new target fish and reset timer
func set_new_target_fish():
	if fish_textures.size() > 0:
		target_fish_texture = fish_textures[randi() % fish_textures.size()]
		print("New target fish texture set!")
		timer_bar.value = target_time
		timer_running = true
		target_fish_display.texture = target_fish_texture  # Display the target fish texture on the UI
		track_timer()

# Track the timer and handle the game-over condition
func track_timer():
	while timer_running:
		await get_tree().create_timer(0.1).timeout
		timer_bar.value -= 0.1
		if timer_bar.value <= 0:
			timer_running = false
			game_over()

# Game over function that ends the game and switches scenes
func game_over():
	print("Game Over!")  # Debug output
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")

# Function that is triggered when the hook catches a fish
func _on_fish_caught(fish_texture: Texture2D):
	print("Calling on fish caught")
	if fish_texture == target_fish_texture:
		# Increase timer, capped at target_time
		timer_bar.value = min(timer_bar.value + 10, target_time)
		set_new_target_fish()  # Switch to a new target fish
	else:
		# Penalize the player for catching the wrong fish
		timer_bar.value = max(timer_bar.value - 10, 0)
		if timer_bar.value <= 0:
			game_over()

# Function triggered by the hook when a fish is caught
func catch_fish(caught_fish: Area2D):
	# Safely access the fish sprite texture
	var fish_sprite = caught_fish.get_node("Sprite2D") as Sprite2D
	if fish_sprite and fish_sprite.texture:
		# Call _on_fish_caught with the fish texture
		_on_fish_caught(fish_sprite.texture)
	# Free the caught fish after the action is completed
	caught_fish.queue_free()
