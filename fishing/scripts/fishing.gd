extends Node2D

const ROOT_SCENE_PATH: String = "res://scenes/"  # Base path for scenes
const FISH_TEXTURE_FOLDER: String = "res://assets/fish/"  # Path to the fish texture folder

@export var spawn_interval: float = 2.0 # Time between spawns
@export var max_fish: int = 20  # Maximum number of fish in the scene

var score: int = 0
var fish_textures: Array = []  # Array to store loaded fish textures

@onready var path_2d: Path2D = $Path2D  # First path for spawning fish
@onready var path_2d_2: Path2D = $Path2D2  # Second path for spawning fish
@onready var fish_scene: PackedScene = preload(ROOT_SCENE_PATH + "fish.tscn")  # Dynamic path to fish scene
@onready var score_label: Label = $ScoreLabel  # Reference to your score label
@onready var hook: Area2D = $Hook  # Reference to the hook node

func _ready():
	# Assign the score callback to the hook
	hook.score_callback = Callable(self, "_on_score_added")
	
	# Load all fish textures from the folder
	load_fish_textures()
	
	# Start the spawning loop
	spawn_fish_periodically()

func load_fish_textures():
	# Load all textures from the folder
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

func spawn_fish_periodically():
	# Continuously spawn fish at intervals
	while true:
		# Ensure we don't exceed the maximum number of fish
		var total_fish = path_2d.get_child_count() + path_2d_2.get_child_count()
		if total_fish < max_fish:
			spawn_fish()
		await get_tree().create_timer(spawn_interval).timeout

func spawn_fish():
	# Randomly select path
	var selected_path = path_2d if randf() > 0.5 else path_2d_2
	var curve_length = selected_path.curve.get_baked_length()
	var random_pos = selected_path.curve.sample_baked(randf_range(0, curve_length))
	
	# Instance a new fish
	var new_fish = fish_scene.instantiate()
	new_fish.position = random_pos
	
	# Assign a random texture
	if fish_textures.size() > 0 and new_fish.has_node("Sprite2D"):
		var fish_sprite = new_fish.get_node("Sprite2D") as Sprite2D
		fish_sprite.texture = fish_textures[randi() % fish_textures.size()]
	
	# Set fish direction based on spawn side
	var fish_script = new_fish as Area2D
	if selected_path == path_2d:
		fish_script.direction = 1  # Move right-to-left
	else:
		fish_script.direction = -1  # Move left-to-right
	
	selected_path.add_child(new_fish)



func _on_score_added():
	# Increment the score and update the label
	score += 1
	score_label.text = "Score: %d" % score
