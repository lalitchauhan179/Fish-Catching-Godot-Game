extends Area2D

@export var drag_speed: float = 2.0  # Speed for dragging the hook
@export var reel_speed: float = 1.0  # Duration for reeling the hook back
@export var reel_audio: AudioStreamPlayer2D  # Node for reel sound
@export var catch_sound: AudioStreamPlayer2D  # Node for catch sound
var is_dragging: bool = false  # Whether the hook is being dragged
var original_position: Vector2  # Stores the hook's initial position
const ROOT_SCENE_PATH: String = "res://scenes/"
@onready var fishing_game: PackedScene = preload(ROOT_SCENE_PATH + "fishing_game.tscn")
#var fishing_game: Node = null
var caught_fish: Area2D = null  # Reference to the caught fish
var tween = null  # Tween for smooth reeling back


func _ready():
	original_position = position  # Save the starting position of the hook
	if not reel_audio:
		print("Warning: Reel audio node is not assigned!")
	if not catch_sound:
		print("Warning: Catch sound node is not assigned!")

	
func _input(event):
	# Handle mouse events for dragging and reeling
	if event is InputEventMouseButton:
		if event.pressed and is_mouse_over():  # Start dragging if mouse is over the hook
			is_dragging = true
			stop_tween()  # Stop any active tween
		elif not event.pressed:
			is_dragging = false
			start_reeling()  # Reel the hook back when mouse button is released
	elif event is InputEventMouseMotion and is_dragging:
		# Move the hook based on mouse motion
		position += event.relative * drag_speed

func is_mouse_over() -> bool:
	# Check if the mouse is close to the hook
	return (get_global_mouse_position() - global_position).length() <= 30

func start_reeling():
	# Reel the hook back to its original position
	stop_tween()
	if is_inside_tree():
		tween = get_tree().create_tween()
		tween.tween_property(self, "position", original_position, reel_speed).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
		tween.tween_callback(Callable(self, "_on_reel_complete"))
		play_reel_sound()

func stop_tween():
	# Stop any active tween
	if tween:
		tween.kill()
		tween = null

func _on_reel_complete():
	# Called when the reeling animation completes
	if caught_fish:
		call_deferred("remove_fish")  # Remove the caught fis

func remove_fish():
	# Remove the caught fish from the scene
	if caught_fish and is_inside_tree():
		caught_fish.queue_free()
		caught_fish = null

func play_reel_sound():
	# Play the reel sound if assigned
	if reel_audio and not reel_audio.playing:
		reel_audio.play()

#var caught_fish: Area2D = null  # Initialize the caught_fish variable

# Called when the hook enters the area of another object
func _on_area_entered(area: Area2D):
	if area.is_in_group("fish") and not caught_fish:  # Check if the area belongs to a fish
		caught_fish = area
		caught_fish.can_move = false  # Stop the fish's movement
		call_deferred("_attach_fish_to_hook", caught_fish)

		# Check if the fishing_game is valid and call _on_fish_caught
		if fishing_game:
			print("Fishing game exists")
			if fishing_game.has_method("_on_fish_caught"):
				print("Fishing game has _on_fish_caught method")
				var fish_sprite = caught_fish.get_node("Sprite2D") as Sprite2D
				if fish_sprite and fish_sprite.texture:
					print("Fish caught: " + str(fish_sprite.texture))
					fishing_game._on_fish_caught(fish_sprite.texture)
				else:
					print("Fish sprite or texture is invalid")
			else:
				print("Fishing game does not have _on_fish_caught method")
		else:
			print("Fishing game is not assigned or is null")

# Function to attach fish to the hook
func _attach_fish_to_hook(fish: Area2D):
	if fish.get_parent():
		fish.get_parent().remove_child(fish)
	add_child(fish)
	fish.global_position = self.global_position

	# Play the fish's caught animation (optional)
	if fish.has_method("play_caught_animation"):
		fish.play_caught_animation()
	# Optional: Reset `caught_fish` after attaching it to the hook, if needed
	# This might not be necessary if you handle it elsewhere in the game logic
