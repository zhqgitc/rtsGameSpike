class_name HealthBar
extends Node3D
## Floating health bar above a unit or building. Shown only once it is damaged.
## Listens to the target's health_changed signal; the simulation doesn't know
## about it. Assumes the fixed RTS camera yaw (the bar shrinks toward its left).

const WIDTH := 1.4
const THICKNESS := 0.16

var _fill: MeshInstance3D
var _width: float = WIDTH


## `height` is how high above the target's origin the bar floats; `width`
## scales the bar for big targets such as buildings.
func attach(target: Damageable, height: float, width: float = WIDTH) -> void:
	position.y = height
	_add_quad(Color(0.08, 0.08, 0.08), width + 0.1, THICKNESS + 0.06, 0.0)
	_fill = _add_quad(Color(0.25, 0.9, 0.25), width, THICKNESS, 0.001)
	_width = width
	visible = false
	target.health_changed.connect(_on_health_changed)


func _on_health_changed(current: int, maximum: int) -> void:
	var fraction := clampf(float(current) / float(maximum), 0.0, 1.0)
	visible = fraction < 1.0
	_fill.scale.x = maxf(fraction, 0.001)
	_fill.position.x = -(1.0 - fraction) * _width * 0.5
	var mat := _fill.material_override as StandardMaterial3D
	mat.albedo_color = Color(0.9, 0.2, 0.2) if fraction < 0.3 else Color(0.25, 0.9, 0.25)


func _add_quad(color: Color, width: float, height: float, z_offset: float) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = Vector2(width, height)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.billboard_keep_scale = true
	mat.no_depth_test = true
	mat.render_priority = 1 if z_offset > 0.0 else 0
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = quad
	mesh_instance.material_override = mat
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh_instance)
	return mesh_instance
