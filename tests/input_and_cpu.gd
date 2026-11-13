extends SceneTree
func _initialize():
 var D=load("res://scripts/main.gd").DIFF_PARAMS[1]
 for v in [Vector2(1,0),Vector2(1,1),Vector2(0.3,0.4)]:
  var sim=TennisSim.new(false,D,{"speed":7.0,"T":1.0,"err":1.0},"CPU",1)
  sim.state="play";sim.ball.last=1;sim.ball.in_play=true
  var movement=MatchView.movement_input(v)
  sim.inp.x=movement.x;sim.inp.y=movement.y
  sim.human_control(sim.pl[0],1.0/60)
  var target=Vector2(sim.pl[0].tvx,sim.pl[0].tvz).length()
  assert(target <= 7.001)
  print("MOVEMENT ",v," target=",target)
 var hist={};var points=0
 seed(42117)
 var sim=TennisSim.new(true,D,{"speed":7.0,"T":1.0,"err":1.0},"CPU",1)
 for i in 60*240:
  sim.update(1.0/60)
  for e in sim.events:
   if e.t=="hit":hist[e.kind]=hist.get(e.kind,0)+1
   if e.t=="point":points+=1
  sim.events.clear()
 print("AI_AUDIT 240s shots=",hist," points=",points)
 quit()
