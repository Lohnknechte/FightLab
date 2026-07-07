extends CanvasLayer

signal class_selected(class_id: String)
signal main_menu_requested

const CLASS_DATA := {
	"Bummer": {
		"weapon": "Shotgun",
		"icon": "res://Assets/Sprites/weapons/guns/shotgun.png",
		"description": "Explodiert auf kurze Distanz",
		"summary": "5 Pelletschüsse × 5 DMG • 5er Magazin • 1.5s Reload",
		"role": "AGGRESSOR",
		"stats": {"DMG": 5, "SPD": 2, "RNG": 1},
		"color": Color(0.95, 0.55, 0.15),
		"locked": false,
	},
	"Assassin": {
		"weapon": "Wurfmesser",
		"icon": "res://Assets/Sprites/weapons/guns/knife.png",
		"description": "Präzise Würfe für schnelle Picks",
		"summary": "34 DMG • 0.85s Cooldown • kein Magazin",
		"role": "ASSASSIN",
		"stats": {"DMG": 4, "SPD": 3, "RNG": 3},
		"color": Color(0.75, 0.25, 0.85),
		"locked": false,
	},
	"Recon": {
		"weapon": "Sniper",
		"icon": "res://Assets/Sprites/weapons/guns/sniper.png",
		"description": "Extremer Single-Target Burst auf Distanz",
		"summary": "50 DMG • 3 Schuss • 2.0s Reload • sehr hohe Reichweite",
		"role": "SNIPER",
		"stats": {"DMG": 5, "SPD": 2, "RNG": 5},
		"color": Color(0.25, 0.75, 0.45),
		"locked": false,
	},
	"Assault": {
		"weapon": "Sturmgewehr",
		"icon": "res://Assets/Sprites/weapons/guns/assault_rifle.png",
		"description": "Konstante Feuerkraft für jede Range",
		"summary": "9 DMG • 20 Schuss • 10/s • 1.8s Reload",
		"role": "SOLDIER",
		"stats": {"DMG": 2, "SPD": 5, "RNG": 4},
		"color": Color(0.45, 0.65, 1.0),
		"locked": false,
	},
}

const BANNER_SIZE := Vector2(190, 310)

var _is_selecting := false
var _font: FontFile
var _banner_style: StyleBoxFlat
var _banner_hover_style: StyleBoxFlat
var _banners: Array[ClassBanner] = []

@onready var _banner_container: HBoxContainer = $Control/CenterContainer/VBoxContainer/HBoxContainer
@onready var _title: Label = $Control/CenterContainer/VBoxContainer/Title


func _ready() -> void:
	_font = load("res://Assets/fonts/alagard/alagard.ttf") as FontFile
	_title.add_theme_font_override("font", _font)
	_title.add_theme_font_size_override("font_size", 72)
	_build_styles()
	_build_banners()
	_build_bottom_bar()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_go_to_main_menu()


func _build_bottom_bar() -> void:
	# Bottom bar: ESC-Hinweis + Hauptmenü-Button
	var root_ctrl: Control = $Control
	var bar := HBoxContainer.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -52
	bar.offset_bottom = -10
	bar.offset_left = 20
	bar.offset_right = -20
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 24)
	root_ctrl.add_child(bar)

	var hint := Label.new()
	hint.text = "[ESC] Hauptmenü"
	hint.add_theme_font_override("font", _font)
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.55, 0.6, 0.68))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(hint)

	var btn := Button.new()
	btn.text = "HAUPTMENÜ"
	btn.add_theme_font_override("font", _font)
	btn.add_theme_font_size_override("font_size", 20)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.15, 0.17, 0.22, 0.95)
	btn_style.border_color = Color(0.55, 0.6, 0.7)
	btn_style.border_width_left = 2
	btn_style.border_width_top = 2
	btn_style.border_width_right = 2
	btn_style.border_width_bottom = 2
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	btn_style.content_margin_left = 16
	btn_style.content_margin_right = 16
	btn_style.content_margin_top = 6
	btn_style.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", btn_style)
	var btn_hover := btn_style.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color(0.22, 0.25, 0.32, 0.98)
	btn_hover.border_color = Color(0.96, 0.74, 0.12)
	btn.add_theme_stylebox_override("hover", btn_hover)
	btn.add_theme_color_override("font_color", Color(0.9, 0.92, 1.0))
	btn.pressed.connect(_go_to_main_menu)
	bar.add_child(btn)


func _go_to_main_menu() -> void:
	main_menu_requested.emit()


func _build_styles() -> void:
	_banner_style = StyleBoxFlat.new()
	_banner_style.bg_color = Color(0.12, 0.14, 0.18, 0.92)
	_banner_style.border_color = Color(0.35, 0.4, 0.48, 1.0)
	_banner_style.border_width_left = 3
	_banner_style.border_width_top = 3
	_banner_style.border_width_right = 3
	_banner_style.border_width_bottom = 3
	_banner_style.corner_radius_top_left = 16
	_banner_style.corner_radius_top_right = 16
	_banner_style.corner_radius_bottom_right = 16
	_banner_style.corner_radius_bottom_left = 16

	_banner_hover_style = StyleBoxFlat.new()
	_banner_hover_style.bg_color = Color(0.18, 0.21, 0.27, 0.95)
	_banner_hover_style.border_color = Color(0.96, 0.74, 0.12, 1.0)
	_banner_hover_style.border_width_left = 4
	_banner_hover_style.border_width_top = 4
	_banner_hover_style.border_width_right = 4
	_banner_hover_style.border_width_bottom = 4
	_banner_hover_style.corner_radius_top_left = 16
	_banner_hover_style.corner_radius_top_right = 16
	_banner_hover_style.corner_radius_bottom_right = 16
	_banner_hover_style.corner_radius_bottom_left = 16


func _build_banners() -> void:
	for class_id in CLASS_DATA:
		var data: Dictionary = CLASS_DATA[class_id]
		var banner := ClassBanner.new()
		banner.setup(class_id, data, _font, _banner_style, _banner_hover_style, BANNER_SIZE)
		banner.selected.connect(_on_banner_selected.bind(banner))
		_banners.append(banner)
		_banner_container.add_child(banner)


func _on_banner_selected(class_id: String, banner: ClassBanner) -> void:
	if _is_selecting:
		return
	_is_selecting = true

	# Freeze all banners so hovering/clicking others can't interrupt the
	# selection animation.
	for b in _banners:
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE

	await banner.play_selected_animation()

	var fade := create_tween()
	fade.tween_property($Control, "modulate:a", 0.0, 0.25)
	await fade.finished

	class_selected.emit(class_id)
	queue_free()
