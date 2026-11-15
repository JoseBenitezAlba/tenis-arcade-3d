extends SceneTree
class ProbeSim extends TennisSim:
	var target := Vector2.ZERO
	var raw := Vector3.ZERO
	func launch(tx:float,tz:float,T:float,y0:float,clear:float=1.3,vcap:float=0.0)->void:
		super.launch(tx,tz,T,y0,clear,vcap)
		target=Vector2(tx,tz)
		raw=Vector3(ball.vx,ball.vy,ball.vz)
func _initialize(): call_deferred("run")
func run():
	var D=load("res://scripts/main.gd").DIFF_PARAMS[1]
	var n:=0
	var landed:=0
	var maxerr:=0.0
	var errors:=[]
	var cases:=[]
	for hz in [60.0,120.0]:
		for lateral in [-3.0,0.0,3.0]:
			for side in [true,false]:
				for zdist in [-18.0,1.5,6.0,9.5,11.0]:
					for y in [0.55,1.2,2.0]:
						for bn in [0,1]:
							for kind in ["lob","toplob"]:
								for sd in [42117,8853,1337]:
									seed(sd)
									var s=ProbeSim.new(false,D,{"speed":7.0,"T":1.0,"err":0.0},"CPU",1)
									s.state="play";s.serve_unreturned=false;s.serve_stage="rally"
									var e=s.pl[0];var b=s.ball
									e.near=side;s.pl[1].near=not side
									e.x=lateral;e.z=zdist if side else s.L-zdist
									s.pl[1].x=8.0
									e.speed=0.0;e.swing=0.2;e.aim_lx=lateral/3.75
									b.x=lateral;b.z=e.z+(0.55 if side else -0.55);b.y=y
									b.vx=0;b.vy=-1;b.vz=-12 if side else 12
									b.bounces=bn;b.held=false;b.toss=false;b.in_play=true;b.last=1
									s.do_hit(e,kind,false)
									var v:=Vector3(b.vx,b.vy,b.vz)
									var cross_y:float=-1
									for i in 600:
										var oldz:float=b.z
										s.events.clear();s.step_ball(1.0/hz)
										if (oldz-s.NZ)*(b.z-s.NZ)<=0:cross_y=b.y
										if b.bounces>0 or not b.in_play:break
									var err:float=Vector2(b.x,b.z).distance_to(s.target)
									var target_opposite:bool=s.target.y>s.NZ if side else s.target.y<s.NZ
									var bounce_opposite:bool=b.z>s.NZ if side else b.z<s.NZ
									var ok:bool=b.bounces>0 and target_opposite and bounce_opposite and b.z>=-s.BR and b.z<=s.L+s.BR and absf(b.x)<=4.115+s.BR and cross_y>=1.03
									if ok:landed+=1
									maxerr=maxf(maxerr,err)
									cases.append({"hz":hz,"x":lateral,"side":side,"zdist":zdist,"y":y,"bn":bn,"kind":kind,"seed":sd,"target":[s.target.x,s.target.y],"bounce":[b.x,b.z],"error":err,"speed":v.length(),"raw_speed":s.raw.length(),"net_y":cross_y,"in":ok})
									# Far-behind-baseline shots already exceed the floor. They must remain
									# velocity-equivalent to the original launch solution;
									# its existing radius/integration landing offset is not this fix.
									if zdist < 0.0:
										if v.distance_to(s.raw)>0.0001 or not ok:errors.append(cases[-1])
									elif err>0.45 or not ok:errors.append(cases[-1])
									n+=1
	print("LOB_REGRESSION n=",n," in=",landed," max_error_m=",maxerr," failures=",errors)
	if not errors.is_empty():quit(1);return
	quit()
