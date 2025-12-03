extends Control
@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var lightning_flash: ColorRect = $LightningFlash
var time: float = 0.0
var next_lightning_time: float = 0.0
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_schedule_next_lightning()
func _process(delta: float) -> void:
	time += delta
	if dark_overlay:
		var pulse = (sin(time * 0.3) + 1.0) * 0.5 
		dark_overlay.color.a = 0.3 + (pulse * 0.4)
	if time >= next_lightning_time:
		_trigger_lightning()
		_schedule_next_lightning()
func _schedule_next_lightning() -> void:
	next_lightning_time = time + randf_range(3.0, 10.0)
func _trigger_lightning() -> void:
	if not lightning_flash: return
	var tween = create_tween()
	var intensity = randf_range(0.2, 0.6)
	tween.tween_property(lightning_flash, "color:a", intensity, 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(lightning_flash, "color:a", 0.0, 0.2).set_ease(Tween.EASE_IN)
	if randf() > 0.4:
		tween.tween_interval(0.05)
		tween.tween_property(lightning_flash, "color:a", intensity * 0.5, 0.05)
		tween.tween_property(lightning_flash, "color:a", 0.0, 0.1)
