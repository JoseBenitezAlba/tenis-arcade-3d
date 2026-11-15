extends SceneTree
# Mirror selection and integrate the real flight. No rival, no aim error.
# The 4m short-ball bound covers the existing drop depth (d=0.1), not a new target.
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
				for zdist in [1.5,6.0,9.5]:
					for y in [0.55,1.2,2.0,2.6]:
						for bn in [0,1]:
							for kind in ["drop"]:
								for sd in [42117,8853,1337]:
									seed(sd)
									var s=ProbeSim.new(false,D,{"speed":7.0,"T":1.0,"err":0.0},"CPU",1)
									s.state="play";s.serve_unreturned=false;s.serve_stage="rally"
									var e=s.pl[0];var b=s.ball
									e.near=side;s.pl[1].near=not side
									e.x=lateral;e.z=zdist if side else s.L-zdist
									s.pl[1].x=8.0
									e.speed=3.0 if sd==1337 else 0.0;e.swing=0.0;e.aim_lx=lateral/3.75;s.inp.x=lateral/3.75
									b.x=lateral;b.z=e.z+(0.55 if side else -0.55);b.y=y
									b.vx=0;b.vy=-1;b.vz=-12 if side else 12
									b.bounces=bn;b.held=false;b.toss=false;b.in_play=true;b.last=1
									s.inp.drop=true;s.human_control(e,1.0/60)
									var selected:String=e.kind
									s.do_hit(e,e.kind,false)
									var v:=Vector3(b.vx,b.vy,b.vz)
									var path:=[];var cross_y:float=-1;var apex:float=b.y;var flight_time:float=0
									for i in 600:
										var oldz:float=b.z
										s.events.clear();s.step_ball(1.0/hz)
										apex=maxf(apex,b.y);flight_time+=1.0/hz
										if n==0 and i%4==0:path.append([b.x,b.y,b.z])
										if (oldz-s.NZ)*(b.z-s.NZ)<=0:cross_y=b.y
										if b.bounces>0 or not b.in_play:break
									var err:float=Vector2(b.x,b.z).distance_to(s.target)
									var opposite:bool=b.z>s.NZ if side else b.z<s.NZ
									var target_opposite:bool=s.target.y>s.NZ if side else s.target.y<s.NZ
									var ok:bool=target_opposite and opposite and b.bounces>0 and b.z>=-s.BR and b.z<=s.L+s.BR and absf(b.x)<=4.115+s.BR and cross_y>=1.03
									if ok:landed+=1
									maxerr=maxf(maxerr,err)
									cases.append({"apex":apex,"flight_s":flight_time,"hz":hz,"x":lateral,"side":side,"zdist":zdist,"y":y,"bn":bn,"selected":selected,"kind":b.kind,"seed":sd,"target":[s.target.x,s.target.y],"bounce":[b.x,b.z],"error":err,"speed":v.length(),"raw_speed":s.raw.length(),"net_y":cross_y,"in":ok,"near_net":absf(b.z-s.NZ)<4.0})
									if not ok or selected!="drop" or b.kind!="drop" or absf(b.z-s.NZ)>=4.0 or err>0.65:
										errors.append(cases[-1])
									n+=1
	print("DROP_REGRESSION n=",n," legal_short=",landed," max_error_m=",maxerr," failures=",errors)
	if not errors.is_empty():quit(1);return
	quit()
