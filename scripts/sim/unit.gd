class_name Unit
extends Node3D
## A unit in the world. Holds its definition and builds placeholder visuals.

var def: UnitDef


func setup(unit_def: UnitDef) -> void:
	def = unit_def
	name = "%s_%d" % [def.id, get_instance_id()]
	_build_placeholder_mesh()


func _build_placeholder_mesh() -> void:
	var mesh_instance := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = def.color
	match def.shape:
		UnitDef.Shape.CAPSULE:
			var capsule := CapsuleMesh.new()
			capsule.radius = def.size.x * 0.5
			capsule.height = def.size.y
			mesh_instance.mesh = capsule
		_:
			var box := BoxMesh.new()
			box.size = def.size
			mesh_instance.mesh = box
	mesh_instance.material_override = mat
	mesh_instance.position.y = def.size.y * 0.5
	add_child(mesh_instance)
