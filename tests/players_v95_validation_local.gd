extends SceneTree
var mv:MatchView
var out="/tmp/players-match"
func _initialize():call_deferred("run")
func run():
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("out="):out=arg.substr(4)
 DirAccess.make_dir_recursive_absolute(out)
 var host=load("res://scripts/main.gd").new();host._register_inputs()
 seed(1234)
 mv=MatchView.new();mv.set_meta("surface","clay");mv.setup({"demo":true,"surface":"clay","AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv)
 mv.set_physics_process(false);await process_frame;seed(1234)
 for i in 60*24:
  mv._physics_process(1.0/60)
  if i%60==0:print("MATCH ",i/60," ",mv.sim.state," hits=",mv.sim.rally_hits," p0=",mv.rigs[0].state," layer=",mv.rigs[0].upper_stroke_weight," p1=",mv.rigs[1].state," layer=",mv.rigs[1].upper_stroke_weight)
  if i>=480:
   var focus:int=0 if i<960 else 1
   var actor=mv.rigs[focus]
   mv.cam.position=actor.position+Vector3(2.5,1.8,3.5 if focus==0 else -3.5)
   mv.cam.look_at(actor.position+Vector3(0,1.0,0));mv.cam.fov=34;mv.cam.near=0.05
  if i>=480 and i%3==0:
   await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(out+"/frame_%04d.png"%i)
 mv._amb.stop();mv.queue_free();host.free();await process_frame;quit()
