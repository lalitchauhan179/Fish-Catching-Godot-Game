extends Area2D

@export var speed: float = 100.0
@export var direction: int = 1
var can_move: bool = true
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	scale.x = abs(scale.x) * direction

func _process(delta):
	if can_move:
		position.x += speed * direction * delta
		var viewport_size = get_viewport_rect().size
		if (direction == 1 and position.x > viewport_size.x + 550) or (direction == -1 and position.x < -50):
			queue_free()

func play_caught_animation():
	can_move = false
	if animation_player.has_animation("caught"):
		animation_player.play("caught")
	else:
		queue_free()
