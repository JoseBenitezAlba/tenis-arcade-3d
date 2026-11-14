extends SceneTree
var mv:MatchView
var out="/tmp/players-match"
var focus=0
func _initialize():call_deferred("run")
func run():
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("out="):out=arg.substr(4)
  if arg=="far":focus=1
 DirAccess.make_dir_recursive_absolute(out)
 var host=load("res://scripts/main.gd").new();host._register_inputs()
 seed(42117)
 mv=MatchView.new();mv.set_meta("surface","clay");mv.setup({"demo":true,"surface":"clay","AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv)
 await process_frame;mv.set_physics_process(false)
 if focus==1:mv.sim.M.server=1;mv.sim.prep_serve()
 var last_swing=0.0
 for i in 240:
  mv._physics_process(1.0/60)
  var actor=mv.rigs[focus]
  var serve_hit=mv.sim.pl[focus].kind=="serve" and mv.sim.pl[focus].swing>last_swing
  last_swing=mv.sim.pl[focus].swing
  if serve_hit:
   var a=actor._current_global_pose(actor.skel.find_bone("UpperArm_R")).origin
   var b=actor._current_global_pose(actor.skel.find_bone("LowerArm_R")).origin
   var c=actor._current_global_pose(actor.skel.find_bone("Wrist_R")).origin
   var h=actor.skel.global_transform*(actor._current_global_pose(actor.racket_hand_idx)*(actor._fist_center_hand+actor.grip_basis.y*0.57/actor.CHAR_SCALE))
   print("SERVECONTACT ",i," focus=",focus," elbow_bend=",rad_to_deg((b-a).angle_to(c-b))," head=",h," ball=",Vector3(mv.sim.ball.x,mv.sim.ball.y,mv.sim.ball.z))
  mv.cam.position=actor.position+Vector3(-3.3,1.8,4.4 if focus==0 else -4.4)
  mv.cam.look_at(actor.position+Vector3(0,1.35,0));mv.cam.fov=34;mv.cam.near=0.05
  if mv.sim.pl[focus].swing>0.0 and i%3==0:print("ACTORSTROKE ",i," ",mv.sim.pl[focus].kind," side=",mv.sim.pl[focus].hit_side," swing=",mv.sim.pl[focus].swing," layer=",actor.upper_stroke_weight)
  if i%60==0:print("MATCH ",i/60," ",mv.sim.state," hits=",mv.sim.rally_hits," p0=",mv.rigs[0].state," layer=",mv.rigs[0].upper_stroke_weight," p1=",mv.rigs[1].state," layer=",mv.rigs[1].upper_stroke_weight)
  if i%3==0 or serve_hit:
   await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(out+"/frame_%04d.png"%i)
 mv._amb.stop();mv.queue_free();host.free();await process_frame;quit()
