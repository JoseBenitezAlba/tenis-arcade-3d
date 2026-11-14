extends SceneTree
func _initialize():call_deferred("run")
func run():
 var D=load("res://scripts/main.gd").DIFF_PARAMS[1]
 for near in [true,false]:
  seed(42117)
  var s=TennisSim.new(false,D,{"speed":7.0,"T":1.0,"err":1.0},"CPU",1)
  s.M.server=0 if near else 1;s.prep_serve()
  var score:Array=s.M.pts.duplicate();var initial_server:int=s.M.server
  s.toss_ball();s.ball.toss_t=0.05;s.fault("SIN CONTACTO")
  assert(s.serve_fault==1 and s.M.pts==score)
  s.fault("SIN CONTACTO");assert(s.serve_fault==1 and s.M.pts==score)
  s.toss_ball();s.fault("SIN CONTACTO")
  assert(s.serve_fault==0 and s.stats[initial_server].df==1)
  assert(s.M.pts[1-initial_server]==score[1-initial_server]+1)
  print("PASS double fault and duplicate token side=",near)
 for near in [true,false]:
  var s=TennisSim.new(false,D,{"speed":7.0,"T":1.0,"err":1.0},"CPU",1)
  s.M.server=0 if near else 1;s.prep_serve();s.toss_ball()
  s.ball.last=s.M.server;s.ball.in_play=true;s.ball.serving=true;s.ball.serve_net=true
  s.ball.x=-1.0 if near else 1.0;s.ball.z=TennisSim.NZ+(3.0 if near else -3.0)
  s.judge_landing()
  assert(s.serve_fault==0 and s.serve_stage=="ready" and s.state=="serve")
  var found:bool=false
  for event in s.events:
   if event.t=="let":found=true
  assert(found)
  print("PASS net let side=",near)
 for timing in [0.2,0.38,0.5,0.75,0.9]:
  seed(42117)
  var s=TennisSim.new(false,D,{"speed":7.0,"T":1.0,"err":1.0},"CPU",1)
  s.rut_t=1.8;s.step_ball(0);s.toss_ball()
  while s.ball.toss_t<timing:s.step_ball(1.0/120)
  var y:float=s.ball.y;s.inp.hit=true;s.human_control(s.pl[0],0.0)
  if y>=2.75:assert(s.serve_stage=="hit" and s.ball.in_play)
  else:assert(s.serve_fault==1 and s.serve_stage=="ready")
  print("PASS human height window t=",timing," y=",y," stage=",s.serve_stage)
 var reach_sim=TennisSim.new(true,D,{"speed":7.0,"T":1.0,"err":1.0},"CPU",1)
 var e=reach_sim.pl[0];e.x=0.0;e.z=0.0
 assert(reach_sim._physical_contact_ok(e,0.5,1.2,0.8))
 assert(not reach_sim._physical_contact_ok(e,1.84,2.14,1.54))
 print("PASS reach envelope excludes 2.4m remote volley, keeps close contact")
 quit()
