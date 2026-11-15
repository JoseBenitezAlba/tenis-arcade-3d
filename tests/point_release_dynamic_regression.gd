extends SceneTree
# Point-aligned counterpart to the unchanged fixed-frame historical replay.
# Observe real point events first, then exercise a moving loser with a residual
# timer. Keep the 76-frame observation and strict Idle_Sword stationary contract.
class PointView extends MatchView:
	var point_count:int=0
	func drain_events()->void:
		for ev in sim.events:
			if ev.t=="point":point_count+=1
		super.drain_events()
func _initialize():call_deferred("run")
func run():
	var host=load("res://scripts/main.gd").new();host._register_inputs();seed(8853)
	var mv=PointView.new();mv.set_meta("surface","clay");mv.setup({"demo":true,"surface":"clay","AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv);mv.set_physics_process(false);await process_frame;seed(8853)
	var natural_samples:int=0;var natural_moving:int=0
	for i in 3600:
		mv._physics_process(1.0/60)
		if mv.sim.state=="point":
			for p in 2:
				var e=mv.sim.pl[p];var f=mv.rigs[p]
				assert(f.point_finished_visual)
				if p!=mv.sim.last_winner and e.swing<=0 and e.dive_t<=0 and e.getup_t<=0 and f._full_stroke_age>0.65:
					natural_samples+=1
					assert(f.state in ["Idle_Sword","Walk","Run","Run_Left","Run_Right","Run_Back"])
					if e.speed>0.9:natural_moving+=1
	assert(mv.point_count>=2 and natural_samples>=76 and natural_moving>0)
	# Dynamic stress fixture after a real point, without setting speed=0 or
	# teleporting to break_pos. A real award creates the same point transition.
	mv.sim.state="play";mv.sim.state_t=1.0
	var e=mv.sim.pl[1];e.want_t=1.8;e.swing=0;e.dive_t=0;e.getup_t=0
	e.x=0.0;e.z=24.8;e.vx=3.0;e.vz=0;e.speed=3.0
	mv.sim.award_point(0,"PUNTO","")
	var moving:int=0;var resting:int=0
	for i in 76:
		mv._physics_process(1.0/60)
		var f=mv.rigs[1]
		assert(mv.sim.state=="point" and e.want_t>0 and f.point_finished_visual)
		assert(f.state in ["Idle_Sword","Walk","Run","Run_Left","Run_Right","Run_Back"])
		if e.speed<=0.05:
			assert(f.state=="Idle_Sword");resting+=1
		if e.speed>0.9:moving+=1
	assert(moving>0 and resting>0)
	print("PASS dynamic point release natural_events=",mv.point_count," natural_samples=",natural_samples," natural_moving=",natural_moving," fixture_frames=76 moving=",moving," idle=",resting)
	mv._amb.stop();mv.queue_free();host.free();await process_frame;quit()
