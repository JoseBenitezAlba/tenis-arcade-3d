extends SceneTree
func _init():
	var Sim = load("res://scripts/sim.gd")
	var s = Sim.new(false, {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}, {"speed": 7.0, "T": 1.0, "err": 1.0}, "CPU", 1)
	var dt = 1.0 / 60.0
	for i in range(10800):
		s.update(dt)
	print("BOOT_OK t=", s.time)
	quit()
