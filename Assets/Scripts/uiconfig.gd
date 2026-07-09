# UIConfig.gd
class_name UIConfig extends Resource

@export_group("Gadget Colors")
@export var fill_charging: Color = Color(0.88, 0.28, 0.23, 0.55)
@export var fill_ready: Color = Color(0.96, 0.74, 0.12, 0.8)

@export_group("Border Colors")
@export var border_idle: Color = Color(0.32, 0.36, 0.45, 1.0)
@export var border_ready: Color = Color(0.96, 0.74, 0.12, 1.0)
@export var border_ready_hi: Color = Color(1.0, 0.95, 0.65, 1.0)
@export var border_denied: Color = Color(0.9, 0.25, 0.22, 1.0)

@export_group("Icon Colors")
@export var icon_idle: Color = Color(0.92, 0.94, 1.0)
@export var icon_ready: Color = Color(1.0, 0.97, 0.85)

@export_group("Selector Colors")
@export var sel_active: Color = Color(0.96, 0.74, 0.12)
@export var sel_inactive: Color = Color(0.55, 0.6, 0.7)
