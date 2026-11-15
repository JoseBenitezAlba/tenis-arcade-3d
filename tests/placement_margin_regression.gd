extends SceneTree
# Selected CPU target, real integration and actual human action/contact route.
# These fixtures do not measure a person's reaction, touch latency or win rate.
class ProbeSim extends TennisSim:
 var target := Vector2.ZERO
 func launch(tx:float,tz:float,T:float,y0:float,clear:float=1.3,vcap:float=0.0)->void:
  target=Vector2(tx,tz)
  super.launch(tx,tz,T,y0,clear,vcap)
func _initialize():call_deferred('run')
func run():
 var reach=TennisSim.new(false,{}, {},'CPU',1)
 var human=reach.pl[0];human.near=true;human.x=0;human.z=0
 assert(reach._in_hit_win(human,.5,1.2,.7,2.9,2.5,2.2))
 assert(not reach._in_hit_win(human,2.5,1.0,2.0,2.9,2.5,2.2))
 assert(not reach._in_hit_win(human,0.0,1.0,2.4,2.9,2.5,2.2))
 reach.demo=true
 assert(reach._in_hit_win(human,2.5,1.0,2.0,2.9,2.5,2.2))
 print('PASS physical human envelope, unchanged demo window')
 var D=load('res://scripts/main.gd').DIFF_PARAMS[1].duplicate()
 D.err=0.0;D.miss=0.0
 var n=0;var min_flight=99.0;var max_error=0.0
 for surface in ['hard','clay','grass']:
  for near in [true,false]:
   for depth in [1.0,6.0,10.0]:
    for y in [.55,1.2,2.0]:
     for hz in [60.0,120.0]:
      seed(42117)
      var s=ProbeSim.new(false,D,{'speed':7.0,'T':1.0,'err':0.0},'CPU',1)
      s.surface=surface;s.state='play';s.serve_unreturned=false;s.serve_stage='rally';s.rally_hits=2
      var e=s.pl[1];var b=s.ball
      e.near=near;e.x=0;e.z=depth if near else s.L-depth;e.kind_roll=.9
      s.pl[0].near=not near;s.pl[0].x=8;s.pl[0].z=s.L if near else 0.0
      b.x=0;b.z=e.z+(.55 if near else -.55);b.y=y;b.vx=0;b.vy=-1;b.vz=-12 if near else 12;b.bounces=1;b.held=false;b.toss=false;b.in_play=true;b.last=0
      s.do_hit(e,'drive',true)
      assert(b.kind=='drive')
      # launch() targets ground height 0, while a real bounce is at radius BR.
      # Check the contract's target-plane time; measure the earlier bounce below.
      assert(absf((s.target.y-b.z)/b.vz)>=1.0-0.000001)
      var flight=0.0
      while flight<4 and b.bounces==0 and b.in_play:
       s.step_ball(1.0/hz/2);flight+=1.0/hz/2
      var error=Vector2(b.x,b.z).distance_to(s.target)
      if not (b.bounces==1 and b.in_play):
       print("FAIL flight ",surface," near=",near," depth=",depth," y=",y," hz=",hz," bounce=",b.bounces," play=",b.in_play," pos=",Vector3(b.x,b.y,b.z)," target=",s.target," time=",flight," events=",s.events);quit(1);return

      assert(error<.65)
      assert((b.z>s.NZ) if near else (b.z<s.NZ))
      min_flight=minf(min_flight,flight);max_error=maxf(max_error,error);n+=1
 print('PASS placement flight n=',n,' min_s=',min_flight,' max_target_error_m=',max_error)
 # A fixed known input trace: start wide, already moving the wrong way,
 # wait 0.2s, steer toward the other side and hold GOLPE once. No remote hit.
 for press in [false,true]:
  seed(42117)
  var s=ProbeSim.new(false,load('res://scripts/main.gd').DIFF_PARAMS[1],{'speed':7.0,'T':1.0,'err':1.0},'CPU',1)
  s.surface='grass';s.state='play';s.serve_unreturned=false;s.serve_stage='rally';s.rally_hits=2
  var e=s.pl[1];var b=s.ball;var p=s.pl[0]
  e.near=false;e.x=0;e.z=s.L-1;e.kind_roll=.9
  p.near=true;p.x=3;p.z=0;p.vx=6
  b.x=0;b.z=e.z-.55;b.y=1.2;b.vx=0;b.vy=-1;b.vz=12;b.bounces=1;b.held=false;b.toss=false;b.in_play=true;b.last=0
  s.do_hit(e,'drive',true);s.events.clear()
  var hits=0;var at=-1.0
  for i in 120:
   if i>=12:
    s.inp.x=-1.0 if p.x>-2.95 else 0.0
    if i==12 and press:s.inp.hit=true
   s.time+=1.0/60;s.state_t+=1.0/60
   var in_reach=s._physical_contact_ok(p,b.x,b.y,b.z) or s._physical_contact_ok(p,(b.x+b.px)*.5,(b.y+b.py)*.5,(b.z+b.pz)*.5)
   s.human_control(p,1.0/60)
   for ev in s.events:
    if ev.t=='hit' and ev.id==0:
     assert(in_reach)
     hits+=1;at=float(i)/60
   s.events.clear()
   if hits>0:break
   s.update_player(p,1.0/60)
   for j in 2:s.step_ball(1.0/120)
   if not b.in_play:break
  assert(hits==(1 if press else 0))
  print('PASS placement action press=',press,' contacts=',hits,' contact_s=',at)
 quit()
