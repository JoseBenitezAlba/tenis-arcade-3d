extends SceneTree
# A missed return must not keep a stale want_t freezing preparation after point.
func _initialize():call_deferred("run")
func run():
 var host=load("res://scripts/main.gd").new();host._register_inputs()
 seed(8853)
 var mv=MatchView.new();mv.set_meta("surface","clay");mv.setup({"demo":true,"surface":"clay","AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv);mv.set_physics_process(false);await process_frame;seed(8853)
 var checked:int=0
 for i in 1921:
  mv._physics_process(1.0/60)
  if i>=1800 and i<=1875:
   var f=mv.rigs[1]
   assert(mv.sim.state=="point" and mv.sim.pl[1].want_t>0.0)
   assert(f.point_finished_visual and f.state=="Idle_Sword")
   checked+=1
 assert(checked==76)
 print("PASS point release: ",checked," frames idle despite stale preparation timer; simulation not edited")
 mv._amb.stop();mv.queue_free();host.free();await process_frame;quit()
