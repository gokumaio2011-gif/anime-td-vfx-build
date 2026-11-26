extends Node3D

const ATTACKS := {
	"Ace": ["Fire Fist", "Flame Bullet", "Fire Pillar", "Flame Emperor", "Enō no Kokyū"],
	"Mikasa": ["Dual Slash", "Spinning Strike", "Thunder Spear", "ODM Assault", "Ackerman's Fury"]
}
const FIRE := Color(1.0, 0.22, 0.035)
const ICE := Color(0.35, 0.82, 1.0)

var selected_unit := "Ace"
var attack_index := 0
var auto_demo := false
var enemies: Array[Dictionary] = []
var attack_timer := 0.0
var spawn_timer := 0.0
var demo_timer := 0.0
var ui: CanvasLayer
var status_label: Label
var arena_root: Node3D
var effects_root: Node3D
var unit_nodes := {}
var enemy_nodes: Array[Node3D] = []
var path_points := [Vector3(-11,0,-5), Vector3(-6,0,-5), Vector3(-2,0,-1), Vector3(3,0,2), Vector3(8,0,2), Vector3(12,0,5)]

func _ready() -> void:
	_build_world()
	_build_ui()
	_spawn_unit("Ace", Vector3(-3,0,5))
	_spawn_unit("Mikasa", Vector3(3,0,5))
	_spawn_enemy(false)
	_spawn_enemy(true)
	_update_ui()

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	e.sky = Sky.new()
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.48,0.55,0.78)
	e.ambient_light_energy = 0.65
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52,-28,0)
	sun.light_energy = 1.25
	add_child(sun)
	var camera := Camera3D.new()
	camera.position = Vector3(0,18,23)
	camera.look_at(Vector3(0,0,0))
	camera.current = true
	add_child(camera)
	arena_root = Node3D.new()
	add_child(arena_root)
	effects_root = Node3D.new()
	add_child(effects_root)
	_box(arena_root, Vector3(0,-0.35,0), Vector3(30,0.5,18), Color(0.12,0.16,0.22))
	_box(arena_root, Vector3(0,-0.05,0), Vector3(26,0.12,14), Color(0.22,0.25,0.3))
	for i in range(path_points.size()-1):
		var a: Vector3 = path_points[i]
		var b: Vector3 = path_points[i+1]
		var mid := (a+b)*0.5
		var length := Vector2(b.x-a.x,b.z-a.z).length()
		var tile := _box(arena_root, Vector3(mid.x,0.04,mid.z), Vector3(length,0.08,1.65), Color(0.42,0.34,0.25))
		tile.rotation.y = atan2(b.z-a.z,b.x-a.x)
	for x in [-14,14]:
		_box(arena_root, Vector3(x,1,0), Vector3(0.5,2,18), Color(0.08,0.11,0.17))
	_add_label_3d("VFX TEST ARENA", Vector3(0,4,-7), 30, Color(0.7,0.82,1))

func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	m.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.78
	m.material_override = mat
	m.position = pos
	parent.add_child(m)
	return m

func _sphere(parent: Node3D, pos: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius*2
	mesh.radial_segments = 12
	mesh.rings = 8
	m.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color*0.45
	m.material_override = mat
	m.position = pos
	parent.add_child(m)
	return m

func _add_label_3d(text_value: String, pos: Vector3, size: int, color: Color) -> void:
	var label := Label3D.new()
	label.text = text_value
	label.position = pos
	label.font_size = size
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	arena_root.add_child(label)

func _spawn_unit(kind: String, pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	arena_root.add_child(root)
	var color := FIRE if kind == "Ace" else Color(0.28,0.48,0.62)
	_box(root, Vector3(0,0.95,0), Vector3(0.75,1.05,0.42), color)
	_sphere(root, Vector3(0,1.75,0), 0.38, Color(0.91,0.72,0.58))
	if kind == "Ace":
		_sphere(root, Vector3(0,2.08,0), 0.43, Color(0.12,0.07,0.045))
		_box(root, Vector3(0,2.35,0), Vector3(1.0,0.12,0.75), Color(0.82,0.65,0.22))
		_box(root, Vector3(0,0.3,0), Vector3(0.8,0.55,0.45), Color(0.15,0.12,0.13))
	else:
		_box(root, Vector3(0,1.2,-0.28), Vector3(0.82,1.0,0.12), Color(0.72,0.68,0.55))
		_box(root, Vector3(0,1.65,-0.25), Vector3(0.12,0.75,0.12), Color(0.65,0.08,0.12))
		_box(root, Vector3(-0.55,0.85,0), Vector3(0.25,0.3,0.3), Color(0.68,0.68,0.7))
		_box(root, Vector3(0.55,0.85,0), Vector3(0.25,0.3,0.3), Color(0.68,0.68,0.7))
	_add_label_3d(kind, pos+Vector3(0,2.8,0), 24, Color.WHITE)
	unit_nodes[kind] = root

func _spawn_enemy(is_titan: bool) -> void:
	var root := Node3D.new()
	var start := path_points[0] + Vector3(0,0.1,0)
	root.position = start
	arena_root.add_child(root)
	var skin := Color(0.66,0.42,0.32) if is_titan else Color(0.7,0.68,0.62)
	var scale_factor := 1.8 if is_titan else 0.85
	_box(root, Vector3(0,0.9*scale_factor,0), Vector3(0.75,1.0,0.42)*scale_factor, skin)
	_sphere(root, Vector3(0,1.65*scale_factor,0), 0.34*scale_factor, skin)
	_box(root, Vector3(-0.48*scale_factor,0.85*scale_factor,0), Vector3(0.25,0.9,0.3)*scale_factor, skin)
	_box(root, Vector3(0.48*scale_factor,0.85*scale_factor,0), Vector3(0.25,0.9,0.3)*scale_factor, skin)
	_add_label_3d("TITAN" if is_titan else "SOLDIER", root.position+Vector3(0,2.5*scale_factor,0), 18, Color(1,0.85,0.75))
	enemies.append({"node":root,"hp":500 if is_titan else 160,"max":500 if is_titan else 160,"path":0,"progress":0.0,"speed":0.8 if is_titan else 1.35,"titan":is_titan})
	enemy_nodes.append(root)

func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var panel := PanelContainer.new()
	panel.position = Vector2(18,18)
	panel.custom_minimum_size = Vector2(360,0)
	ui.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation",8)
	panel.add_child(v)
	var title := Label.new()
	title.text = "ANIME TD  /  VFX SHOWCASE"
	title.add_theme_font_size_override("font_size",20)
	v.add_child(title)
	status_label = Label.new()
	v.add_child(status_label)
	var row := HBoxContainer.new()
	v.add_child(row)
	_button(row,"ACE",func(): selected_unit="Ace"; attack_index=0; _update_ui())
	_button(row,"MIKASA",func(): selected_unit="Mikasa"; attack_index=0; _update_ui())
	var attacks := VBoxContainer.new()
	v.add_child(attacks)
	for i in range(5):
		var idx := i
		_button(attacks,"ATTACK %d — %s" % [i+1,ATTACKS["Ace"][i]],func(): attack_index=idx; _fire_attack())
	var controls := HBoxContainer.new()
	v.add_child(controls)
	_button(controls,"DEMO: OFF",func(): auto_demo=!auto_demo; _update_ui())
	_button(controls,"SPAWN SOLDIER",func(): _spawn_enemy(false))
	_button(controls,"SPAWN TITAN",func(): _spawn_enemy(true))
	_button(v,"REPLAY SELECTED ATTACK",func(): _fire_attack())
	var hint := Label.new()
	hint.text = "Escolha a unidade e um ataque. WASD não é necessário."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(hint)

func _button(parent: Node, text_value: String, action: Callable) -> void:
	var b := Button.new()
	b.text = text_value
	b.custom_minimum_size.y = 34
	b.pressed.connect(action)
	parent.add_child(b)

func _update_ui() -> void:
	if status_label:
		status_label.text = "UNIDADE: %s   |   ATAQUE: %s   |   ALVOS: %d" % [selected_unit,ATTACKS[selected_unit][attack_index],enemies.size()]

func _process(delta: float) -> void:
	spawn_timer += delta
	attack_timer += delta
	demo_timer += delta
	if spawn_timer > 9.0:
		spawn_timer = 0
		if enemies.size() < 5:
			_spawn_enemy(randf() > 0.5)
	if auto_demo and demo_timer > 2.8:
		demo_timer = 0
		attack_index = (attack_index+1)%5
		selected_unit = "Mikasa" if selected_unit=="Ace" else "Ace"
		_fire_attack()
	_update_enemies(delta)
	if attack_timer > 3.5:
		attack_timer = 0
		if not enemies.is_empty():
			_fire_attack()

func _update_enemies(delta: float) -> void:
	for i in range(enemies.size()-1,-1,-1):
		var data: Dictionary = enemies[i]
		var node: Node3D = data.node
		if not is_instance_valid(node):
			enemies.remove_at(i)
			continue
		var p: int = data.path
		if p < path_points.size()-1:
			var target: Vector3 = path_points[p+1]
			node.position = node.position.move_toward(target, float(data.speed)*delta)
			if node.position.distance_to(target)<0.12:
				data.path = p+1
		else:
			node.queue_free()
			enemies.remove_at(i)

func _fire_attack() -> void:
	if enemies.is_empty():
		_spawn_enemy(selected_unit=="Mikasa")
	if enemies.is_empty():
		return
	var target: Node3D = enemies[0].node
	var origin: Vector3 = unit_nodes[selected_unit].global_position + Vector3(0,1.8,0)
	var destination: Vector3 = target.global_position + Vector3(0,1.0,0)
	var color: Color = FIRE if selected_unit=="Ace" else ICE
	var name_attack: String = ATTACKS[selected_unit][attack_index]
	var burst_count := 18 + attack_index*10
	var core := _sphere(effects_root,origin,0.28+attack_index*0.12,color)
	var tween := create_tween()
	tween.tween_property(core,"global_position",destination,0.42+attack_index*0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(core,"scale",Vector3.ONE*(1.5+attack_index*0.45),0.45)
	tween.tween_callback(func():
		if is_instance_valid(core): core.queue_free()
		_make_burst(destination,color,burst_count,1.0+attack_index*0.22)
		_damage_target(target,65+attack_index*35)
	)
	_add_label_3d(name_attack.to_upper(),origin+Vector3(0,1.0,0),20,color)
	var flash := OmniLight3D.new()
	flash.light_color = color
	flash.light_energy = 3.5
	flash.omni_range = 7+attack_index*2
	flash.position = origin
	effects_root.add_child(flash)
	var lt := create_tween()
	lt.tween_property(flash,"light_energy",0.0,0.55)
	lt.tween_callback(flash.queue_free)
	_update_ui()

func _make_burst(pos: Vector3, color: Color, count: int, power: float) -> void:
	for i in range(count):
		var angle := TAU*float(i)/count
		var dir := Vector3(cos(angle),randf_range(-0.35,0.8),sin(angle)).normalized()
		var bit := _sphere(effects_root,pos,randf_range(0.07,0.18),color)
		var tw := create_tween()
		tw.tween_property(bit,"position",pos+dir*randf_range(1.5,4.5)*power,0.35+randf()*0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(bit,"scale",Vector3.ZERO,0.7)
		tw.tween_callback(bit.queue_free)

func _damage_target(target: Node3D, damage: int) -> void:
	for i in range(enemies.size()-1,-1,-1):
		if enemies[i].node == target:
			enemies[i].hp -= damage
			if enemies[i].hp <= 0:
				_make_burst(target.global_position+Vector3(0,1,0),Color(1,0.75,0.42),35,1.5)
				target.queue_free()
				enemies.remove_at(i)
			break
	_update_ui()
