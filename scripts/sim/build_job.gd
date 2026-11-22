class_name BuildJob
extends Job
## A worker's construction orders: walk to the site and add build progress
## until the building is finished. Several workers on one site build faster.

var _unit: Unit
var _site: Building


func _init(unit: Unit, site: Building) -> void:
	_unit = unit
	_site = site


## The site this job is building.
func site_node() -> Building:
	return _site


func tick(delta: float) -> void:
	if _site == null or not is_instance_valid(_site) or _site.complete:
		_unit.job_stop()
		_unit.end_job()
		return
	var offset := _site.global_position - _unit.global_position
	offset.y = 0.0
	if offset.length() <= _site.reach():
		if _unit.is_moving():
			_unit.job_stop()
		_site.add_progress(_unit.def.build_speed * delta)
	elif not _unit.is_moving():
		_unit.job_move_to(_site.global_position)
