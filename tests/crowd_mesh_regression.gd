extends SceneTree
func _initialize():call_deferred("run")
func run():
	var c=CrowdFX.new();root.add_child(c);c.build()
	assert(c.n>0 and c.n==c.base_pos.size())
	for mm in [c.mm_body,c.mm_head,c.mm_legs,c.mm_cap]:
		assert(mm.multimesh.instance_count==c.n)
		assert(mm.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	assert(is_equal_approx(c.mm_body.multimesh.mesh.radius,0.15))
	assert(is_equal_approx(c.mm_head.multimesh.mesh.radius,0.105))
	var original_body=CapsuleMesh.new();original_body.radial_segments=10;original_body.rings=4
	var original_head=SphereMesh.new();original_head.radial_segments=10;original_head.rings=5
	var original_cap=CylinderMesh.new();original_cap.radial_segments=10
	var old_primitives:int=(original_body.get_mesh_arrays()[Mesh.ARRAY_INDEX].size()+original_head.get_mesh_arrays()[Mesh.ARRAY_INDEX].size()+original_cap.get_mesh_arrays()[Mesh.ARRAY_INDEX].size())/3
	var new_primitives:int=0
	for mm in [c.mm_body,c.mm_head,c.mm_cap]:new_primitives+=mm.multimesh.mesh.get_mesh_arrays()[Mesh.ARRAY_INDEX].size()/3
	assert(new_primitives<old_primitives/2)
	c.update(0.05,0.0)
	c.force_ovation=true;c.update(0.5,1.0)
	# Use a nonempty seat: empty transforms intentionally stay zero.
	var moving:int=0;var visible:int=0
	for i in c.n:
		if not c.empty[i]:
			visible+=1
			var t:Transform3D=c.mm_body.multimesh.get_instance_transform(i)
			assert(t.basis.determinant()!=0)
			if absf(t.origin.y-c.base_pos[i].y-0.55)>0.01:moving+=1
	assert(visible>0 and moving>0)
	print("PASS crowd mesh seats=",c.n," nonempty=",visible," animated=",moving," primitives_per_person=",old_primitives,"->",new_primitives)
	c.queue_free();await process_frame;quit()
