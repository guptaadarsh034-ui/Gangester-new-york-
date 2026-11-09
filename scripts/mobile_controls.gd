extends CanvasLayer
## Touch-first controls. Raw screen events are used so independent fingers can
## move, look and press action buttons simultaneously on Android.

signal look_dragged(delta: Vector2)

const STICK_RADIUS := 92.0
const STICK_DEADZONE := 0.12
const LOOK_SENSITIVITY := 1.0

class TouchOverlay extends Control:
	var controller: Node
	func _draw() -> void:
		if is_instance_valid(controller): controller._draw_overlay(self)

var ui: Control
var stick_finger := -1
var look_finger := -1
var button_fingers: Dictionary = {}
var action_fingers: Dictionary = {}
var stick_value := Vector2.ZERO
var stick_center := Vector2.ZERO
var button_rects: Dictionary = {}
var look_last := Vector2.ZERO
var mouse_stick := false
var mouse_look := false
var mouse_buttons: Array[String] = []

func _ready() -> void:
	layer = 15
	ui = TouchOverlay.new()
	(ui as TouchOverlay).controller = self
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	_layout()
	get_viewport().size_changed.connect(_layout)

func _layout() -> void:
	if not is_instance_valid(ui): return
	var s := get_viewport().get_visible_rect().size
	stick_center = Vector2(150.0, s.y - 150.0)
	button_rects = {
		"fire": Rect2(Vector2(s.x-150.0,s.y-220.0),Vector2(118,100)),
		"aim": Rect2(Vector2(s.x-280.0,s.y-150.0),Vector2(100,82)),
		"interact": Rect2(Vector2(s.x-285.0,s.y-255.0),Vector2(108,82)),
		"jump": Rect2(Vector2(s.x-145.0,s.y-345.0),Vector2(108,82)),
		"sprint": Rect2(Vector2(s.x-285.0,s.y-365.0),Vector2(108,82))
	}
	ui.queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var captured := _touch_begin(event.index,event.position) if event.pressed else _touch_end(event.index)
		if captured: get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if _touch_drag(event.index,event.position,event.relative): get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var captured := _touch_begin(-2,event.position) if event.pressed else _touch_end(-2)
		if captured: get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		if mouse_stick:
			_update_stick(event.position)
			get_viewport().set_input_as_handled()
		elif mouse_look:
			_update_look(-2,event.position,event.relative)
			get_viewport().set_input_as_handled()

func _touch_begin(finger: int, point: Vector2) -> bool:
	if finger == -2:
		if _inside_stick(point):
			mouse_stick = true
			stick_finger = finger
			_update_stick(point)
			return true
		var action := _button_at(point)
		if action != "":
			mouse_buttons.append(action)
			_press_action(action,finger)
			return true
		var s := get_viewport().get_visible_rect().size
		if point.x > s.x*0.42 and point.y > s.y*0.16 and point.y < s.y*0.76:
			mouse_look = true
			look_finger = finger
			look_last = point
			return true
		return false
	if stick_finger == -1 and _inside_stick(point):
		stick_finger = finger
		_update_stick(point)
		return true
	var action := _button_at(point)
	if action != "":
		_press_action(action,finger)
		return true
	var s := get_viewport().get_visible_rect().size
	if look_finger == -1 and point.x > s.x*0.42 and point.y > s.y*0.16 and point.y < s.y*0.76:
		look_finger = finger
		look_last = point
		return true
	return false

func _touch_drag(finger: int, point: Vector2, relative: Vector2) -> bool:
	if finger == stick_finger:
		_update_stick(point)
		return true
	elif finger == look_finger:
		_update_look(finger,point,relative)
		return true
	return button_fingers.values().any(func(v): return (v as Dictionary).has(finger))

func _touch_end(finger: int) -> bool:
	var captured := finger == stick_finger or finger == look_finger
	if finger == stick_finger:
		stick_finger = -1
		mouse_stick = false
		stick_value = Vector2.ZERO
		_apply_move()
		ui.queue_redraw()
	if finger == look_finger:
		look_finger = -1
		mouse_look = false
	for action in button_fingers.keys():
		var fingers: Dictionary = button_fingers[action]
		if fingers.has(finger):
			captured = true
			fingers.erase(finger)
			if fingers.is_empty():
				button_fingers.erase(action)
				_release_action(action)
	return captured

func _inside_stick(point: Vector2) -> bool:
	return point.distance_to(stick_center) < STICK_RADIUS*2.0

func _update_stick(point: Vector2) -> void:
	var offset := point-stick_center
	stick_value = offset.limit_length(STICK_RADIUS)/STICK_RADIUS
	if stick_value.length() < STICK_DEADZONE: stick_value = Vector2.ZERO
	_apply_move()
	ui.queue_redraw()

func _apply_move() -> void:
	_set_action("move_left",maxf(0.0,-stick_value.x))
	_set_action("move_right",maxf(0.0,stick_value.x))
	_set_action("move_forward",maxf(0.0,-stick_value.y))
	_set_action("move_back",maxf(0.0,stick_value.y))

func _update_look(finger: int, point: Vector2, relative: Vector2) -> void:
	var delta := relative
	if delta.length() < 0.001:
		delta = point-look_last
	look_last = point
	look_dragged.emit(delta*LOOK_SENSITIVITY)

func _button_at(point: Vector2) -> String:
	for action in button_rects:
		if (button_rects[action] as Rect2).has_point(point): return action
	return ""

func _press_action(action: String, finger: int) -> void:
	if not button_fingers.has(action): button_fingers[action] = {}
	var fingers: Dictionary = button_fingers[action]
	fingers[finger] = true
	if action == "interact" or action == "jump":
		if fingers.size() == 1: _tap_action(action)
	else:
		_set_action(action,1.0)

func _tap_action(action: String) -> void:
	Input.action_press(action)
	await get_tree().create_timer(0.14).timeout
	if not button_fingers.has(action) or (button_fingers[action] as Dictionary).is_empty():
		Input.action_release(action)

func _release_action(action: String) -> void:
	if action == "interact" or action == "jump":
		Input.action_release(action)
	else:
		_set_action(action,0.0)

func _set_action(action: String, strength: float) -> void:
	if strength > 0.02: Input.action_press(action,strength)
	else: Input.action_release(action)

func _draw_overlay(canvas: Control) -> void:
	var center := stick_center
	canvas.draw_circle(center,STICK_RADIUS+12.0,Color(0.015,0.025,0.04,0.52))
	canvas.draw_arc(center,STICK_RADIUS,0.0,TAU,64,Color(0.95,0.72,0.38,0.88),3.0)
	canvas.draw_circle(center+stick_value*STICK_RADIUS,35.0,Color(0.12,0.2,0.29,0.92))
	canvas.draw_arc(center+stick_value*STICK_RADIUS,35.0,0.0,TAU,48,Color(1.0,0.8,0.48),3.0)
	for action in button_rects:
		var rect: Rect2 = button_rects[action]
		var active := button_fingers.has(action) and not (button_fingers[action] as Dictionary).is_empty()
		var fill := Color(0.58,0.16,0.07,0.92) if active else Color(0.025,0.06,0.10,0.78)
		canvas.draw_rect(rect,fill,true)
		canvas.draw_rect(rect,Color(0.96,0.7,0.35,0.95),false,3.0)
		var label := action.to_upper()
		var font := ThemeDB.fallback_font
		var font_size := 22
		canvas.draw_string(font,rect.position+Vector2((rect.size.x-font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x)*0.5,rect.size.y*0.58),label,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color.WHITE)
