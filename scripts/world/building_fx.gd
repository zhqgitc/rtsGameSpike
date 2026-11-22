class_name BuildingFX
extends Node3D
## Wear and tear on a building: sparks and dust where it is hit, smoke once it
## is badly damaged, flames (with a flickering glow) when it is nearly gone.
## Listens to the building's health_changed; the simulation does not know it
## exists. Lives under the building, so it hides with it in the fog of war.

const SMOKE_BELOW := 0.55
const FIRE_BELOW := 0.28

var _building: Building
var _last_health: int = 0
var _smoke: CPUParticles3D
var _fire: CPUParticles3D
var _glow: OmniLight3D
var _flicker: float = 0.0


func attach(building: Building) -> void:
	_building = building
	_last_health = building.health
	position = Vector3(0, building.def.size.y * 0.85, 0)
	building.health_changed.connect(_on_health_changed)


func _process(delta: float) -> void:
	if _glow == null:
		return
	_flicker -= delta
	if _flicker <= 0.0:
		_flicker = randf_range(0.05, 0.14)
		_glow.light_energy = randf_range(1.2, 2.6)


func _on_health_changed(current: int, maximum: int) -> void:
	var fraction := float(current) / float(maximum)
	if current < _last_health:
		_impact()
	_last_health = current
	if fraction < SMOKE_BELOW and _smoke == null:
		_smoke = Effects.smoke_emitter(16, 3.2, 1.3)
		add_child(_smoke)
	if fraction < FIRE_BELOW and _fire == null:
		_fire = Effects.fire_emitter()
		add_child(_fire)
		_glow = OmniLight3D.new()
		_glow.light_color = Color(1.0, 0.55, 0.2)
		_glow.omni_range = 7.0
		_glow.shadow_enabled = false
		_glow.position = Vector3(0, 0.5, 0)
		add_child(_glow)


## Sparks at a random spot on the walls.
func _impact() -> void:
	var effects := Effects.find(get_tree())
	if effects == null:
		return
	var rect := _building.footprint()
	var spot := Vector3(
			randf_range(rect.position.x, rect.end.x),
			randf_range(0.2, 0.85) * _building.def.size.y,
			randf_range(rect.position.y, rect.end.y))
	effects.hit_spark(spot)
