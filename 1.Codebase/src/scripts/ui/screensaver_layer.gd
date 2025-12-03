extends Control
const CHARACTER_TEXTURES = [
	preload("res://1.Codebase/src/assets/characters/ark_happy.png"),
	preload("res://1.Codebase/src/assets/characters/donkey_confused.png"),
	preload("res://1.Codebase/src/assets/characters/gloria_protagonis_thinking.png"),
	preload("res://1.Codebase/src/assets/characters/one_shocked.png"),
	preload("res://1.Codebase/src/assets/characters/protagonist_neutral.png"),
	preload("res://1.Codebase/src/assets/characters/teacher_chan_embarrassed.png"),
	preload("res://1.Codebase/src/assets/characters/ark_sad.png"),
	preload("res://1.Codebase/src/assets/characters/donkey_happy.png"),
]
const EXPLOSION_TEXTURE = preload("res://1.Codebase/src/assets/characters/Explosion Effect.png")
const MIN_ICONS = 10
const MAX_ICONS = 15
const SPEED_MIN = 100.0
const SPEED_MAX = 200.0
const ICON_SIZE = Vector2(120, 120) 
class BouncingIcon extends TextureRect:
	var velocity: Vector2
	var rotation_speed: float
	var is_dying: bool = false
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		gui_input.connect(_on_gui_input)
	func _on_gui_input(event: InputEvent) -> void:
		if is_dying: return
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			is_dying = true
			accept_event()
			if ServiceLocator:
				var audio = ServiceLocator.get_audio_manager()
				if audio:
					audio.play_sfx("happy_click", 1.2)
			texture = EXPLOSION_TEXTURE
			var tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
			tween.tween_property(self, "modulate:a", 0.0, 0.15)
			tween.chain().tween_callback(queue_free)
	func _process(delta: float) -> void:
		if is_dying: return
		position += velocity * delta
		rotation += rotation_speed * delta
		var viewport_rect = get_viewport_rect()
		if position.x <= 0:
			position.x = 0
			velocity.x *= -1
		elif position.x + size.x >= viewport_rect.size.x:
			position.x = viewport_rect.size.x - size.x
			velocity.x *= -1
		if position.y <= 0:
			position.y = 0
			velocity.y *= -1
		elif position.y + size.y >= viewport_rect.size.y:
			position.y = viewport_rect.size.y - size.y
			velocity.y *= -1
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var num_icons = randi_range(MIN_ICONS, MAX_ICONS)
	for i in range(num_icons):
		_spawn_icon()
func _spawn_icon() -> void:
	var icon = BouncingIcon.new()
	icon.texture = CHARACTER_TEXTURES.pick_random()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = ICON_SIZE
	icon.size = ICON_SIZE
	var viewport_size = get_viewport_rect().size
	icon.position = Vector2(
		randf_range(0, viewport_size.x - ICON_SIZE.x),
		randf_range(0, viewport_size.y - ICON_SIZE.y)
	)
	var speed = randf_range(SPEED_MIN, SPEED_MAX)
	var angle = randf_range(0, TAU)
	icon.velocity = Vector2(cos(angle), sin(angle)) * speed
	icon.rotation_speed = randf_range(-0.5, 0.5)
	icon.modulate.a = 0.7
	add_child(icon)
