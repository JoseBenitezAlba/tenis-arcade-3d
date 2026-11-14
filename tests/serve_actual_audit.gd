extends SceneTree
var root3: Node3D
var fig
var phase: String
var out: String = "/tmp/anim-baseline"
func _initialize():
 call_deferred("run")
func run():
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("out="): out=arg.substr(4)
 DirAccess.make_dir_recursive_absolute(out)
 root3=Node3D.new()
 root.add_child(root3)
 var env=WorldEnvironment.new()
 var en=Environment.new()
 en.background_mode=Environment.BG_COLOR
 en.background_color=Color("#303d47")
 en.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 en.ambient_light_color=Color.WHITE
 en.ambient_light_energy=0.7
 env.environment=en
 root3.add_child(env)
 var light=DirectionalLight3D.new()
 light.rotation_degrees=Vector3(-45,-30,0)
 root3.add_child(light)
 var floor_mesh=MeshInstance3D.new()
 var box=BoxMesh.new()
 box.size=Vector3(12,0.05,12)
 floor_mesh.mesh=box
 floor_mesh.position.y=-0.025
 var mat=StandardMaterial3D.new()
 mat.albedo_color=Color("#846446")
 floor_mesh.material_override=mat
 root3.add_child(floor_mesh)
 fig=load("res://scripts/player_fig.gd").new(0,true)
 root3.add_child(fig)
 var cam=Camera3D.new()
 root3.add_child(cam)
 cam.position=Vector3(-2.5,1.6,3.2)
 cam.look_at(Vector3(0,1,0))
 cam.fov=34
 cam.current=true
 var e={"x":0.0,"z":0.0,"near":true,"speed":0.0,"vx":0.0,"vz":0.0,"swing":0.0,"kind":"serve","want_t":0.0,"prep_t":0.0,"want":"normal","wait_serve":true,"dive_t":0.0,"getup_t":0.0,"hit_side":"fore"}
 for clip in ["articulated/Servicio"]:
  for i in range(31):
   fig._pose_overrides.clear();fig.skel.clear_bones_global_pose_override()
   fig.rotation=Vector3.ZERO
   fig.state=clip;fig.ap.play(clip,0);fig.ap.seek(i/10.0,true);fig.ap.advance(0)
   await process_frame
   await process_frame
   fig._place_racket(1.0/60)
   await process_frame
   print("CLIP ",clip," ",i/10.0," head=",fig.racket_node.to_global(Vector3(0,-0.7,0))," hand=",fig.racket_node.global_position)
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(out+"/"+clip.replace("/","_")+"_%02d.png"%i)
 quit()
