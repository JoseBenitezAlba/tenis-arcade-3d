extends SceneTree
func _initialize():call_deferred("run")
func run():
 var D=load("res://scripts/main.gd").DIFF_PARAMS[1]
 var checked:int=0;var undercounts:int=0
 for demo in [true,false]:
  for server in [0,1]:
   for tb in [false,true]:
    var s=TennisSim.new(demo,D,{},"CPU",1)
    s.M.server=server;s.M.tb=tb;s.M.tb_total=3;s.prep_serve()
    assert(MatchView.rally_display_count(s)==0)
    s.toss_ball();assert(MatchView.rally_display_count(s)==0)
    s.do_serve(s.pl[server],.8);assert(MatchView.rally_display_count(s)==1)
    var t:float=s.time
    # Accepted opposing contacts in quick succession, below the old timer.
    for n in 4:
     var who:int=(1-server+n)%2
     s.time=t+(n+1)*.133333333333
     s.state="play";s.serve_stage="rally";s.serve_unreturned=false
     s.ball.x=0;s.ball.y=1.2;s.ball.z=s.L*.5+(-1 if s.pl[who].near else 1)
     s.do_hit(s.pl[who],"drive",demo or who==1)
     assert(MatchView.rally_display_count(s)==n+2);checked+=1
    assert(MatchView.rally_display_count(s)>s.rally_hits)
    s.award_point(0,"PUNTO","");assert(MatchView.rally_display_count(s)==5)
    s.prep_serve();assert(MatchView.rally_display_count(s)==0)
    s=TennisSim.new(demo,D,{},"CPU",1);assert(MatchView.rally_display_count(s)==0)
 for sd in [42117,8853,1337,42]:
  seed(sd);var s=TennisSim.new(true,D,{},"CPU",1);var expected:int=0
  for i in 36000:
   s.update(1.0/60)
   for e in s.events:
    if e.t=="serve":expected=1
    if e.t=="hit":expected+=1
   if s.rally_hits==0:expected=0
   assert(MatchView.rally_display_count(s)==expected)
   if expected>s.rally_hits:undercounts+=1
   checked+=1;s.events.clear()
 print("PASS rally display checked=",checked," differing_legacy_frames=",undercounts," serve/return/point/reset/newmatch demo/human/tiebreak")
 await check_final_menu()
 quit()

func label_texts(n:Node)->Array:
 var values:Array=[]
 if n is Label:values.append(n.text)
 for child in n.get_children():values.append_array(label_texts(child))
 return values
func check_final_menu()->void:
 var host=load("res://scripts/main.gd").new();root.add_child(host);await process_frame
 host._on_quick_match("clay",1,1,0)
 for i in 8:
  await process_frame
  if DisplayServer.get_name()!="headless":await RenderingServer.frame_post_draw
 var m=host.match_view;m.set_physics_process(false)
 var s=m.sim;s.state="play";s.rally_hits=10;s.ball.hit_id=110;s.rally_start_hit=100
 s.M.games=[3,0];s.M.pts=[3,0];s.M.server=0;s.ball.held=false
 s.award_point(0,"PUNTO","");m.drain_events()
 assert(s.match_over and m.rally_best==11 and s.rally_max==10)
 m.serve_speed_hold=0;m.rally_change_t=1.4;m._update_rally_label(0)
 assert(m.hud.rs_value.text=="11")
 assert(MatchView.rally_count_txt(11)=="RALLY 11")
 s.update(2.3);m.drain_events();await process_frame;await process_frame
 assert("Rally más largo: 11 golpes" in label_texts(host.menus))
 assert(host.menus.visible)
 print("PASS displayed MEJOR/popup/final maximum=11, legacy_sim_max=10, actual over signal/main callback")
 host.queue_free();await process_frame
