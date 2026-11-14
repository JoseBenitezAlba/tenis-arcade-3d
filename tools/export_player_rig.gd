extends SceneTree
func v(a:Vector3):return [a.x,a.y,a.z]
func t(a:Transform3D):return {"o":v(a.origin),"b":[v(a.basis.x),v(a.basis.y),v(a.basis.z)]}
func _initialize():
 var fig=PlayerFig.new(0,true);root.add_child(fig)
 var bones=[]
 for i in fig.skel.get_bone_count():
  bones.append({"name":fig.skel.get_bone_name(i),"parent":fig.skel.get_bone_parent(i),"rest":t(fig.skel.get_bone_rest(i)),"pose":t(fig.skel.get_bone_pose(i)),"bind":t(fig._skin_bind.get(i,fig.skel.get_bone_global_rest(i)))})
 var output: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size()>0 else "/tmp/players-rig.json"
 var f=FileAccess.open(output,FileAccess.WRITE);f.store_string(JSON.stringify(bones));f.close();quit()
