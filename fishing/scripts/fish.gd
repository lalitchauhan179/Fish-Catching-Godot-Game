extends Area2D

@export var speed: float = 100.0
@export var direction: int = 1

func _ready():
	scale.x = abs(scale.x) * direction  # Flip sprite based on direction

func _process(delta):
	position.x += speed * direction * delta
	var viewport_size = get_viewport_rect().size
	if (direction == 1 and position.x > viewport_size.x + 550) or (direction == -1 and position.x < -50):
		queue_free()
