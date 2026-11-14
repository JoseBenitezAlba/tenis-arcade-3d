extends SceneTree
# Regresión: al entrar al saque hay una pausa de 0.4 s antes de que GOLPE lance
# la bola. Un toque para avanzar el punto (o un retoque inmediato) no debe
# lanzar el saque al instante (dobles faltas accidentales en táctil).
func _initialize(): call_deferred("run")
func run():
 var D=load("res://scripts/main.gd").DIFF_PARAMS[1]
 var s=TennisSim.new(false,D,{"speed":7.0,"T":1.0,"err":1.0},"CPU",1)
 s.M.server=0;s.prep_serve()
 assert(s.state=="serve" and s.serve_stage=="ready")
 # Toque inmediato al entrar al saque: bloqueado por la pausa.
 s.inp.hit=true;s.human_control(s.pl[0],1.0/60.0)
 assert(s.serve_stage=="ready" and not s.ball.toss)
 print("PASS early serve press blocked during cooldown")
 # Sigue bloqueado justo antes de 0.4 s.
 s.state_t=0.38
 s.inp.hit=true;s.human_control(s.pl[0],1.0/60.0)
 assert(s.serve_stage=="ready" and not s.ball.toss)
 print("PASS press at 0.38s still blocked")
 # A partir de 0.4 s el mismo toque sí lanza.
 s.state_t=0.45
 s.inp.hit=true;s.human_control(s.pl[0],1.0/60.0)
 assert(s.ball.toss)
 print("PASS press after 0.4s tosses")
 quit()
