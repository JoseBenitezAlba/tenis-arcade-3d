extends SceneTree
class ProbeView extends MatchView:
	var hits:Array=[]
	func drain_events()->void:
		for ev in sim.events:
			if ev.t=="hit" and ev.id==0:hits.append(ev.duplicate())
		super.drain_events()
func _initialize():call_deferred("run")
func run():
	var h=load("res://scripts/main.gd").new();h._register_inputs()
	# Human control always plays the near side in the actual game. Mirrored
	# selection/flight is covered separately; the pre-existing far-side human
	# contact path hardcodes incoming vz<0 and is not a supported gameplay mode.
	for side in [true]:
		for gap in [1.5,6.0,9.5]:
			for moving in [false,true]:
				seed(42117);var m=ProbeView.new();m.set_meta("surface","hard");m.setup({"demo":false,"surface":"hard","AIP":h.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(m);m.set_physics_process(false);await process_frame
				var s=m.sim;var e=s.pl[0];var b=s.ball
				s.state="play";s.state_t=1;s.serve_unreturned=false;s.serve_stage="rally"
				e.near=side;s.pl[1].near=not side;e.x=0;e.z=gap if side else s.L-gap;e.swing=0;e.getup_t=0;e.speed=3.0 if moving else 0.0;e.vx=3.0 if moving else 0.0
				b.x=0;b.z=e.z+(0.55 if side else -0.55);b.y=1.2;b.vx=0;b.vy=-1;b.vz=-12 if side else 12;b.bounces=1;b.held=false;b.toss=false;b.in_play=true;b.last=1
				s.pl[1].x=8
				Input.action_press("drop")
				if moving:Input.action_press("move_right")
				for i in 8:
					m._physics_process(1.0/60)
					if i==0:Input.action_release("drop")
					await process_frame
				Input.action_release("move_right")
				assert(m.hits.size()==1 and m.hits[0].kind=="drop")
				print("PASS drop action route side=",side," gap=",gap," moving=",moving," hits=",m.hits.size())
				m._amb.stop();m.queue_free();await process_frame
	h.free();quit()
