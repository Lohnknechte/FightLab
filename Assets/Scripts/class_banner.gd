class_name ClassBanner
extends PanelContainer

## A single selectable class banner (name, icon, weapon, description, stats)
## shown on the class-selection screen. Extracted out of class_selection.gd
## so the banner isn't just an anonymous chunk of a 300-line "build everything"
## function — it's now a self-contained, reusable component with its own
## `selected` signal (signals up), configured via setup() (functions down).

signal selected(class_id: String)

const ICON_SIZE := 80

var _class_id: String = ""
var _font: FontFile
var _normal_style: StyleBoxFlat
var _hover_style: StyleBoxFlat
var _is_locked: bool = false


func setup(
	class_id: String,
	data: Dictionary,
	font: FontFile,
	normal_style: StyleBoxFlat,
	hover_style: StyleBoxFlat,
	banner_size: Vector2
) -> void:
	_class_id = class_id
	_font = font
	_normal_style = normal_style
	_hover_style = hover_style
	_is_locked = data.get("locked", false)
	var accent: Color = data["color"]

	custom_minimum_size = banner_size
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	pivot_offset = banner_size * 0.5
	add_theme_stylebox_override("panel", _normal_style)
	modulate = Color(0.55, 0.6, 0.65, 1.0) if _is_locked else Color(1, 1, 1, 1)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vbox)

	_add_name_label(vbox, class_id, accent)
	_add_icon(vbox, data)
	_add_label(
		vbox,
		str(data["weapon"]),
		22,
		Color(0.95, 0.95, 1.0, 0.8) if _is_locked else Color(0.95, 0.95, 1.0, 1.0)
	)
	_add_description(vbox, str(data["description"]))
	var summary_text := str(data.get("summary", ""))
	if summary_text != "":
		_add_summary(vbox, summary_text, accent)

	if not _is_locked and data.has("stats"):
		var sep := HSeparator.new()
		sep.add_theme_constant_override("separation", 6)
		sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(sep)
		vbox.add_child(_create_stats_bars(data["stats"], accent))

	if not _is_locked and data.has("role"):
		var role_label := _add_label(
			vbox,
			str(data["role"]),
			13,
			accent * Color(1, 1, 1, 0.55)
		)
		role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if _is_locked:
		add_child(_create_lock_overlay())
	else:
		mouse_entered.connect(_on_hover.bind(true))
		mouse_exited.connect(_on_hover.bind(false))
		gui_input.connect(_on_gui_input)


func play_selected_animation() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.1)
	tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.12)
	await tween.finished


func _add_name_label(parent: Control, class_id: String, accent: Color) -> void:
	var label := _add_label(
		parent,
		class_id.to_upper(),
		32,
		Color(0.85, 0.85, 0.85) if _is_locked else accent
	)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _add_icon(parent: Control, data: Dictionary) -> void:
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = load(data["icon"]) as Texture2D
	icon.modulate = Color(0.5, 0.5, 0.55, 1.0) if _is_locked else Color(1, 1, 1, 1)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)


func _add_description(parent: Control, text: String) -> void:
	var label := _add_label(parent, text, 16, Color(0.6, 0.65, 0.7, 1.0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _add_summary(parent: Control, text: String, accent: Color) -> void:
	var label := _add_label(parent, text, 13, accent * Color(1, 1, 1, 0.8))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _add_label(
	parent: Control,
	text: String,
	font_size: int,
	color: Color
) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _create_stats_bars(stats: Dictionary, accent: Color) -> Control:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 3)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for stat_name in stats:
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var lbl := Label.new()
		lbl.text = stat_name
		lbl.custom_minimum_size = Vector2(32, 0)
		lbl.add_theme_font_override("font", _font)
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.75, 0.78, 0.85))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(lbl)

		var bar_bg := PanelContainer.new()
		bar_bg.custom_minimum_size = Vector2(80, 7)
		bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bg_style := StyleBoxFlat.new()
		bg_style.bg_color = Color(0.15, 0.16, 0.2, 1.0)
		bg_style.corner_radius_top_left = 3
		bg_style.corner_radius_top_right = 3
		bg_style.corner_radius_bottom_left = 3
		bg_style.corner_radius_bottom_right = 3
		bar_bg.add_theme_stylebox_override("panel", bg_style)

		var bar_fill := ColorRect.new()
		var fill_frac := clampf(float(stats[stat_name]) / 5.0, 0.0, 1.0)
		bar_fill.anchor_left = 0.0
		bar_fill.anchor_right = fill_frac
		bar_fill.anchor_top = 0.0
		bar_fill.anchor_bottom = 1.0
		bar_fill.color = accent.lerp(Color(1, 1, 1, 0.9), 0.25)
		bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar_bg.add_child(bar_fill)

		row.add_child(bar_bg)
		container.add_child(row)

	return container


func _create_lock_overlay() -> Control:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.08, 0.09, 0.11, 0.55)
	overlay.add_child(bg)

	var lock_label := Label.new()
	lock_label.text = "DEMNÄCHST"
	lock_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock_label.add_theme_font_override("font", _font)
	lock_label.add_theme_font_size_override("font_size", 28)
	lock_label.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85, 0.9))
	overlay.add_child(lock_label)

	return overlay


func _on_hover(hovered: bool) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var target_scale := Vector2(1.06, 1.06) if hovered else Vector2(1.0, 1.0)
	tween.tween_property(self, "scale", target_scale, 0.15)
	add_theme_stylebox_override("panel", _hover_style if hovered else _normal_style)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected.emit(_class_id)
