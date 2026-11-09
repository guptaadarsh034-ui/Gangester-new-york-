extends CanvasLayer
# Touch-first mobile controls: analog movement, camera drag and hold buttons.

class Joystick extends Control:
	signal changed(value: Vector2)
	var value := Vector2.ZERO
	var dragging := false
	var finger := -1
	var radius := 78.0

	func _ready() -> void:
		custom_minimum_size = Vector2(200, 200)
		size = Vector2(200, 200)
		mouse_filter = Control.MOUSE_FILTER_STOP
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			if event.pressed and Rect2(Vector2.ZERO, size).has_point(event.position):
				dragging = true
				finger = event.index
				_update_value(event.position)
				accept_event()
			elif not event.pressed and dragging and event.index == finger:
				_release_stick()
				accept_event()
		elif event is InputEventScreenDrag and dragging and event.index == finger:
			_update_value(event.position)
			accept_event()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				_update_value(event.position)
			else:
				_release_stick()
			accept_event()
		elif event is InputEventMouseMotion and dragging:
			_update_value(event.position)
			accept_event()

	func _update_value(point: Vector2) -> void:
		var offset := point - size * 0.5
		value = offset.limit_length(radius) / radius
		changed.emit(value)
		queue_redraw()

	func _release_stick() -> void:
		dragging = false
		finger = -1
		value = Vector2.ZERO
		changed.emit(value)
		queue_redraw()

	func _draw() -> void:
		var center := size * 0.5
		draw_circle(center, radius + 8.0, Color(0.02, 0.035, 0.055, 0.42))
		draw_arc(center, radius, 0.0, TAU, 64, Color(0.9, 0.72, 0.42, 0.8), 3.0)
		draw_circle(center + value * radius, 34.0, Color(0.12, 0.19, 0.27, 0.9))
		draw_arc(center + value * radius, 34.0, 0.0, TAU, 48, Color(1.0, 0.78, 0.43, 0.95), 3.0)

class LookZone extends Control:
	signal dragged(delta: Vector2)
	var finger := -1
	var mouse_down := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			if event.pressed and finger == -1:
				finger = event.index
			elif not event.pressed and event.index == finger:
				finger = -1
			accept_event()
		elif event is InputEventScreenDrag and event.index == finger:
			dragged.emit(event.relative)
			accept_event()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			mouse_down = event.pressed
			accept_event()
		elif event is InputEventMouseMotion and mouse_down:
			dragged.emit(event.relative)
			accept_event()

var joystick: Joystick
var look_zone: LookZone

func _ready() -> void:
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ui)

	look_zone = LookZone.new()
	look_zone.anchor_left = 0.40
	look_zone.anchor_top = 0.12
	look_zone.anchor_right = 0.96
	look_zone.anchor_bottom = 0.94
	ui.add_child(look_zone)

	joystick = Joystick.new()
	joystick.position = Vector2(26, -218)
	joystick.anchor_top = 1.0
	joystick.anchor_bottom = 1.0
	ui.add_child(joystick)
	joystick.changed.connect(_move)

	_add_button(ui, "FIRE", Vector2(-126, -126), Vector2(104, 82), "fire", true)
	_add_button(ui, "AIM", Vector2(-246, -116), Vector2(98, 68), "aim", true)
	_add_button(ui, "ACTION", Vector2(-246, -204), Vector2(98, 68), "interact", false)
	_add_button(ui, "JUMP", Vector2(-126, -224), Vector2(104, 78), "jump", false)
	_add_button(ui, "SPRINT", Vector2(-126, -318), Vector2(104, 70), "sprint", true)

func _move(value: Vector2) -> void:
	_set_action("move_left", maxf(0.0, -value.x))
	_set_action("move_right", maxf(0.0, value.x))
	_set_action("move_forward", maxf(0.0, -value.y))
	_set_action("move_back", maxf(0.0, value.y))

func _set_action(action: String, strength: float) -> void:
	if strength > 0.02:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)

func _add_button(parent: Control, caption: String, offset: Vector2, dimensions: Vector2, action: String, hold: bool) -> void:
	var button := Button.new()
	button.text = caption
	button.position = offset
	button.size = dimensions
	button.anchor_left = 1.0
	button.anchor_right = 1.0
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _style(Color(0.035, 0.065, 0.10, 0.86)))
	button.add_theme_stylebox_override("pressed", _style(Color(0.62, 0.17, 0.075, 0.96)))
	parent.add_child(button)
	if hold:
		button.button_down.connect(func(): Input.action_press(action))
		button.button_up.connect(func(): Input.action_release(action))
	else:
		button.pressed.connect(func(): _tap(action))

func _tap(action: String) -> void:
	Input.action_press(action)
	await get_tree().create_timer(0.12).timeout
	Input.action_release(action)

func _style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.98, 0.70, 0.34, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	return style
