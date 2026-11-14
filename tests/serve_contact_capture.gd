extends SceneTree
var mv:MatchView
var out="/tmp/players-serve-detail"
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
 for i in 185:
  mv._physics_process(1.0/60)
  var actor=mv.rigs[focus]
  mv.cam.position=actor.position+Vector3(-2.5,1.6,3.2 if focus==0 else -3.2)
  mv.cam.look_at(actor.position+Vector3(0,1,0));mv.cam.fov=34;mv.cam.near=0.05
  if mv.sim.pl[focus].swing>0.0 and i%3==0:print("ACTORSTROKE ",i," ",mv.sim.pl[focus].kind," side=",mv.sim.pl[focus].hit_side," swing=",mv.sim.pl[focus].swing," layer=",actor.upper_stroke_weight)
  if i>=135 and i<185:
   var hand=actor._current_global_pose(actor.racket_hand_idx)
   var head=actor.skel.global_transform*(hand*(actor._fist_center_hand+actor.grip_basis.y*0.57/PlayerFig.CHAR_SCALE))
   print("SERVEHEAD ",i," head=",head," ball=",Vector3(mv.sim.ball.x,mv.sim.ball.y,mv.sim.ball.z))
  if i>=135 and i<185:print("SERVEDETAIL ",i," toss=",actor.serve_toss," swing=",mv.sim.pl[focus].swing," ball=",mv.sim.ball.y)
  if i%60==0:print("MATCH ",i/60," ",mv.sim.state," hits=",mv.sim.rally_hits," p0=",mv.rigs[0].state," layer=",mv.rigs[0].upper_stroke_weight," p1=",mv.rigs[1].state," layer=",mv.rigs[1].upper_stroke_weight)
  if i>=153 and i<=180:
   await process_frame
   await RenderingServer.frame_post_draw
   print("RENDEREDHEAD ",i," ",actor.racket_node.to_global(Vector3(0,0.60,0)))
   root.get_texture().get_image().save_png(out+"/frame_%04d.png"%i)
 mv._amb.stop();mv.queue_free();host.free();await process_frame;quit()
