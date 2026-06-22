extends Node2D

@export var shower_duration: float = 10.0
@export var min_spawn_delay: float = 1.0  
@export var max_spawn_delay: float = 2.5  

@export var min_time_between_showers: float = 30.0
@export var max_time_between_showers: float = 60.0

# Der maximale Bereich, um den sich der Meteor nach links oder rechts verschieben darf
@export var x_variance: float = 100.0

var meteors: Array = []
var is_shower_active: bool = false

func _ready():
	for child in get_children():
		if child.has_method("_start_fall"):
			# WICHTIG: Wir holen uns hier die Area2D (das Kind)
			meteors.append(child)
			_sleep_meteor(child)
			
	_schedule_next_shower()

func _schedule_next_shower():
	var next_time = randf_range(min_time_between_showers, max_time_between_showers)
	get_tree().create_timer(next_time).timeout.connect(start_meteor_shower)

func start_meteor_shower():
	if is_shower_active: return
	is_shower_active = true
	
	get_tree().create_timer(shower_duration).timeout.connect(stop_meteor_shower)
	_fire_meteor_loop()

func _fire_meteor_loop():
	if not is_shower_active: return
	
	var available_meteor = null
	for m in meteors:
		if m.has_exploded:
			available_meteor = m
			break
			
	if available_meteor:
		# Berechnet einen zufälligen Versatz auf der X-Achse (+- 100 Pixel)
		var random_x_offset = randf_range(-x_variance, x_variance)
		
		# Verändert die spawn_position im Meteor-Skript, BEVOR er fällt
		available_meteor.spawn_position.x = available_meteor.spawn_position.x + random_x_offset
		
		# Startet den Fall
		available_meteor._start_fall()
		
		# Setzt die spawn_position direkt wieder auf den Ursprung zurück, 
		# damit sich die Offsets beim nächsten Mal nicht aufaddieren
		available_meteor.spawn_position.x = available_meteor.spawn_position.x - random_x_offset
		
	var next_delay = randf_range(min_spawn_delay, max_spawn_delay)
	get_tree().create_timer(next_delay).timeout.connect(_fire_meteor_loop)

func stop_meteor_shower():
	is_shower_active = false
	_schedule_next_shower()

func _sleep_meteor(meteor_node):
	meteor_node.has_exploded = true
	meteor_node.monitoring = false
	var p = meteor_node.parent_rigid
	if p:
		p.freeze = true
		p.gravity_scale = 0.0
		p.collision_layer = 0
		p.collision_mask = 0
		p.visible = false
		for child in p.get_children():
			if child is Node2D: child.visible = false
