extends SceneTree
# A missed return must not keep a stale want_t freezing preparation after point.
func _initialize():call_deferred("run")
func run():
 var host=load("res://scripts/main.gd").new();host._register_inputs()
 seed(8853)
 var mv=MatchView.new();mv.set_meta("surface","clay");mv.setup({"demo":true,"surface":"clay","AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv);mv.set_physics_process(false);await process_frame;seed(8853)
 # Controlled fixture: preserve the original replay test unchanged. A real
 # award leaves the actor with a stale preparation timer, regardless of
 # which rallies now occur before frame 1800 in a seeded match.
 mv.sim.state="play"
 # Stationary loser fixture: locomotion is not the preparation contract.
 mv.sim.AIP.speed=0.0
 mv.sim.pl[1].want_t=1.8
 mv.sim.pl[1].x=0.0
 mv.sim.pl[1].z=mv.sim.L+1.0
 mv.sim.pl[1].vx=0.0
 mv.sim.pl[1].vz=0.0
 mv.sim.pl[1].speed=0.0
 mv.sim.award_point(0,"PUNTO","")
 var rest:Vector2=mv.sim.break_pos(mv.sim.pl[1])
 mv.sim.pl[1].x=rest.x
 mv.sim.pl[1].z=rest.y
 var checked:int=0
 for i in 76:
  mv._physics_process(1.0/60)
  var f=mv.rigs[1]
  assert(mv.sim.state=="point" and mv.sim.pl[1].want_t>0.0)
  assert(f.point_finished_visual and f.state=="Idle_Sword")
  checked+=1
 assert(checked==76)
 print("PASS point release: ",checked," frames idle despite stale preparation timer; stationary fixture, no animation/simulation source changes")
 mv._amb.stop();mv.queue_free();host.free();await process_frame;quit()
