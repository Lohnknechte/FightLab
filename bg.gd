extends Sprite2D

@export var amplitude := 10.0   # how far it moves up/down
@export var speed := 1.0        # how fast it moves

var start_y := 0.0
var time := 0.0

func _ready():
	start_y = position.y

func _process(delta):
	time += delta
	position.y = start_y + sin(time * speed) * amplitude
