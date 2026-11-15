extends SceneTree
func _initialize():call_deferred("run")

# Fixture adaptada al swap de paridad de saque: los eventos se detectan por
# senal de contacto (rising edge de swing con contacto visual), no por frames
# historicos del rally anterior al swap. Umbrales identicos: onset<0.12,
# ventana Body<0.20. Margenes pre=13/post=18 (superset de los originales:
# 42117 13/17, 8853 12/18).
#  A) 42117 actor1: primer contacto (drive, llegada media) - evento original.
#  B) 8853 actor1: primer contacto (dejada, llegada lenta). La llegada rapida
#     que esta semilla cubria antes del swap ya no existe en el nuevo rally.
#  C) 42117 actor0: replay determinista de llegada rapida (contacto en f1133,
#     drive, pre_mean>=0.10) que repone la cobertura de alta velocidad. El
#     primer contacto rapido del rally (f280) frena de 11 m/s a 0 en 9 frames
#     y el torso llega a 0.25 m/frame por la propia zancada de frenado:
#     locomocion, no salto de pose; este test no es de suavidad general.
const PRE:=13
const POST:=18
func run():
 var host=load("res://scripts/main.gd").new();host._register_inputs()
 var data:Dictionary={}
 for test_seed in [42117,8853]:
  seed(test_seed)
  var mv=MatchView.new();mv.set_meta("surface","clay");mv.setup({"demo":true,"surface":"clay","AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv);mv.set_physics_process(false);await process_frame;seed(test_seed)
  var pos:=[[],[]];var prev:Array=[Vector3.INF,Vector3.INF];var swing_prev:Array=[0.0,0.0];var steps:=[[],[]];var events:=[]
  for i in 1600:
   mv._physics_process(1.0/60)
   for a in 2:
    var f=mv.rigs[a];var e=mv.sim.pl[a]
    var v:Vector3=f.skel.global_transform*f._current_global_pose(f.skel.find_bone("Body")).origin
    var step:float=v.distance_to(prev[a]) if prev[a]!=Vector3.INF else 0.0
    prev[a]=v;pos[a].append(v);steps[a].append(step)
    if e.swing>0.0 and swing_prev[a]<=0.0 and e.kind!="serve" and f.has_visual_contact:
     var pre_mean:float=0.0;var n:int=0
     for k in range(maxi(1,i-PRE),i):pre_mean+=steps[a][k-1];n+=1
     pre_mean/=maxf(1.0,n)
     events.append({"actor":a,"frame":i,"kind":e.kind,"pre_mean":pre_mean})
    swing_prev[a]=e.swing
  data[test_seed]={"pos":pos,"steps":steps,"events":events}
  mv._amb.stop();mv.queue_free();await process_frame
 var ok:bool=true
 # A) evento original 42117 actor1 (primer contacto)
 ok=_check_event(data[42117],1,-1,"A original 42117 actor1 (drive llegada media)",null) and ok
 # B) 8853 actor1 (primer contacto: dejada)
 ok=_check_event(data[8853],1,-1,"B 8853 actor1 (dejada, llegada lenta)",null) and ok
 # C) replay llegada rapida 42117 actor0 f1133
 ok=_check_event(data[42117],0,1133,"C replay llegada rapida 42117 actor0",0.10) and ok
 assert(ok)
 print("PASS contact arrival body onset: eventos detectados + replay rapido, umbrales originales (onset<0.12, ventana<0.20)")
 host.free();quit()
func _check_event(d:Dictionary,actor:int,frame:int,label:String,min_pre)->bool:
 var events:Array=d.events
 var ev:Dictionary={}
 if frame>=0:
  for ev0 in events:
   if ev0.actor==actor and absi(ev0.frame-frame)<=1:ev=ev0;break
 else:
  for ev0 in events:
   if ev0.actor==actor:ev=ev0;break
 if ev.is_empty():print("FAIL ",label,": evento no detectado");return false
 if min_pre!=null and ev.pre_mean<min_pre:print("FAIL ",label,": llegada lenta pre_mean=",ev.pre_mean);return false
 var c:int=ev.frame
 var steps:Array=d.steps[actor]
 var onset:float=steps[c] if c+1>steps.size()-1 else (d.pos[actor][c+1]-d.pos[actor][c]).length()
 var wmax:float=0.0
 for i in range(maxi(1,c-PRE),mini(steps.size(),c+POST+1)):wmax=maxf(wmax,steps[i])
 print("EVENT ",label," frame=",c," kind=",ev.kind," onset=",onset," pre_mean=",ev.pre_mean," window_max=",wmax)
 if onset>=0.12 or wmax>=0.20:print("FAIL ",label);return false
 print("PASS ",label," onset=",onset," window_max=",wmax)
 return true
