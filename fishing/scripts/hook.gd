extends Area2D

@export var drag_speed: float = 2.0
@export var reel_speed: float = 1.0
@export var reel_audio: AudioStreamPlayer2D
@export var catch_sound: AudioStreamPlayer2D
@export var score_callback: Callable = Callable()

var is_dragging: bool = false
var original_position: Vector2
var caught_fish: Area2D = null
var tween = null

func _ready():
	original_position = position
	connect("body_entered", Callable(self, "_on_body_entered"))

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed and is_mouse_over():
			is_dragging = true
			stop_tween()
		elif not event.pressed:
			is_dragging = false
			start_reeling()
	elif event is InputEventMouseMotion and is_dragging:
		position += event.relative * drag_speed

func _on_body_entered(body):
	print("i n")
	print("Body entered:", body.name)
	if body.name == "fish" and not caught_fish:
		caught_fish = body
		caught_fish.position = to_local(body.global_position)
		add_child(caught_fish)
		if catch_sound:
			catch_sound.play()

func start_reeling():
	stop_tween()
	tween = get_tree().create_tween()
	tween.tween_property(self, "position", original_position, reel_speed)
	tween.tween_callback(Callable(self, "_on_reel_complete"))
	if reel_audio:
		reel_audio.play()

func _on_reel_complete():
	if caught_fish:
		caught_fish.queue_free()
		caught_fish = null
		if score_callback.is_valid():
			score_callback.call()

func stop_tween():
	if tween:
		tween.kill()
		tween = null

func is_mouse_over() -> bool:
	return (get_global_mouse_position() - global_position).length() <= 30
