class_name Orders
extends RefCounted
## Command layer: turns a player intent into orders for individual units.
## The UI calls this; it does not know about mice or screens.


## Send a group to a point. Units spread over a formation around the target so
## they don't all fight over the same spot. Spacing comes from the unit data.
static func move_group(units: Array[Unit], target: Vector3) -> void:
	if units.is_empty():
		return
	var centroid := Vector3.ZERO
	var spacing := 0.0
	for unit in units:
		centroid += unit.global_position
		spacing = maxf(spacing, unit.def.formation_spacing)
	centroid /= units.size()

	var forward := target - centroid
	forward.y = 0.0
	forward = forward.normalized() if forward.length() > 0.01 else Vector3.FORWARD

	var slots := _formation_slots(target, units.size(), spacing, forward)
	var remaining: Array[Unit] = units.duplicate()
	for slot in slots:
		var best := 0
		var best_dist := INF
		for i in remaining.size():
			var d := remaining[i].global_position.distance_squared_to(slot)
			if d < best_dist:
				best_dist = d
				best = i
		remaining[best].issue_move(slot)
		remaining.remove_at(best)


## Rectangular grid centred on the target, facing the direction of travel.
## Slots are ordered front row first.
static func _formation_slots(center: Vector3, count: int, spacing: float, forward: Vector3) -> Array[Vector3]:
	var right := forward.cross(Vector3.UP).normalized()
	var cols := ceili(sqrt(float(count)))
	var rows := ceili(count / float(cols))
	var slots: Array[Vector3] = []
	for i in count:
		var col := i % cols
		var row := floori(i / float(cols))
		var across := (col - (cols - 1) * 0.5) * spacing
		var depth := (row - (rows - 1) * 0.5) * spacing
		slots.append(center + right * across - forward * depth)
	return slots
