extends SceneTree
func _initialize():call_deferred("run")
func run():
 var host=load("res://scripts/main.gd").new();host._register_inputs();seed(42117)
 var mv=MatchView.new();mv.set_meta("surface","clay");mv.setup({"demo":true,"surface":"clay","AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv);await process_frame;mv.set_physics_process(false)
 var samples:int=0;var slip:float=0.0;var max_slip:float=0.0;var anchors:int=0
 for i in 1800:
  mv._physics_process(1.0/60)
  for f in mv.rigs:
   if f._support_age<0.14:
    samples+=1;slip+=f._support_measured_error;max_slip=maxf(max_slip,f._support_measured_error)
   if f._support_age==0.0:anchors+=1
 print("SUPPORT frames=",samples," anchors=",anchors," mean_error_m=",slip/maxi(1,samples)," max_error_m=",max_slip)
 mv._amb.stop();mv.queue_free();host.free();await process_frame;quit()
