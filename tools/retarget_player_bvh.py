import sys,json,numpy as np
from scipy.spatial.transform import Rotation as R,Slerp
import bvh_math as src
if len(sys.argv) != 7:
 raise SystemExit('usage: retarget_player_bvh.py BVH START_SECONDS NAME RIG_JSON OUTPUT_TRES DURATION_SECONDS')
path=sys.argv[1];start=int(float(sys.argv[2])*100);name=sys.argv[3]
rig_path=sys.argv[4];output_path=sys.argv[5];duration=float(sys.argv[6])
j,d=src.parse_bvh(path);gm,gp=src.bvh_fk(j,d);names={a['name']:i for i,a in enumerate(j)}
bones=json.load(open(rig_path));N=len(bones);index={b['name']:i for i,b in enumerate(bones)}
bind=[]
for b in bones:
 m=np.eye(4);m[:3,3]=b['bind']['o'];m[:3,:3]=np.array(b['bind']['b']).T;bind.append(m)
rel=[m if b['parent']<0 else np.linalg.inv(bind[b['parent']])@m for b,m in zip(bones,bind)]
dir_map={}
for side in ['L','R']:
 s='Left' if side=='L' else 'Right'
 for a,b,c in [('Shoulder','Collar','Shoulder'),('UpperArm','Shoulder','Elbow'),('LowerArm','Elbow','Wrist'),('UpperLeg','Hip','Knee'),('LowerLeg','Knee','Ankle')]:dir_map[a+'_'+side]=(s+b,s+c)
child={}
for side in ['L','R']:
 for a,b in [('Shoulder','UpperArm'),('UpperArm','LowerArm'),('LowerArm','Wrist'),('UpperLeg','LowerLeg'),('LowerLeg','Foot')]:child[a+'_'+side]=b+'_'+side

def align(a,b):
 a=a/np.linalg.norm(a);b=b/np.linalg.norm(b);c=np.cross(a,b);dot=a@b
 if dot<-.9999:return R.from_rotvec(np.pi*np.array([0,1,0])).as_matrix()
 q=np.r_[c,1+dot];q/=np.linalg.norm(q);return R.from_quat(q).as_matrix()
# Turn the capture's initial facing to the target's front, preserving
# movement and the relative orientations of the full body.
root0=gm[0][start];forward=root0@np.array([0,0,1]);yaw=np.arctan2(forward[0],forward[2]);orient=R.from_euler('y',-yaw).as_matrix()
frames=[]
for frame in range(start,start+int(duration*100)+1,3):
 transforms=[]
 hipR=orient@gm[names['Hips']][frame];chestR=orient@gm[names['Chest']][frame]
 spine=Slerp([0,1],R.from_matrix([hipR,chestR]))
 for i,b in enumerate(bones):
  p=b['parent'];n=b['name'];m=rel[i].copy() if p<0 else transforms[p]@rel[i]
  if n=='Body':
   m[:3,:3]=hipR@bind[i][:3,:3]
   displacement=orient@(gp[0][frame]-gp[0][start])/100*1.1
   if name=="Servicio": displacement[[0,2]]=0
   m[:3,3]+=displacement
  elif n in ['Hips','Abdomen','Torso','Chest']:
   k={'Hips':.1,'Abdomen':.3,'Torso':.65,'Chest':1}[n];m[:3,:3]=spine([k]).as_matrix()[0]@bind[i][:3,:3]
  elif n in ['Neck','Head']:m[:3,:3]=orient@gm[names[n]][frame]@bind[i][:3,:3]
  elif n in dir_map:
   a,c=dir_map[n];direction=orient@(gp[names[c]][frame]-gp[names[a]][frame]);bi=index[child[n]];bd=bind[bi][:3,3]-bind[i][:3,3];m[:3,:3]=align(bd,direction)@bind[i][:3,:3]
  elif n.startswith('Wrist_'):
   side='Right' if n.endswith('R') else 'Left'
   sr=orient@gm[names[side+'Wrist']][frame]
   shaft=sr@np.array([0.,-1.,0.])
   if name == 'Reves' and side == 'Right':
    shaft=orient@(gp[names['LeftWrist']][frame]-gp[names['RightWrist']][frame]);shaft/=np.linalg.norm(shaft)
   elif name != 'Servicio' and side == 'Right':
    shaft=orient@(gp[names['RightWrist']][frame]-gp[names['RightElbow']][frame]);shaft/=np.linalg.norm(shaft)
   if n.endswith('R'):
    gy=np.array([-.74,0.,-.67]);gy/=np.linalg.norm(gy);gz=np.array([0.,0.,1.]);gz-=gy*(gy@gz);gz/=np.linalg.norm(gz);gx=np.cross(gy,gz)
    grip=np.stack([gx,gy,gz],axis=1)
    face=sr@np.array([0.,0.,1.]);face-=shaft*(shaft@face);face/=np.linalg.norm(face)
    rack=np.stack([np.cross(shaft,face),shaft,face],axis=1)
    m[:3,:3]=rack@grip.T
   else:
    m[:3,:3]=align(np.array([1.,0.,0.]),shaft)@bind[i][:3,:3]
  elif n.startswith('Foot_'):
   lower=index[n.replace('Foot','LowerLeg')];m=transforms[lower]@np.linalg.inv(bind[lower])@bind[i]
   ankle=names['RightAnkle' if n.endswith('R') else 'LeftAnkle']
   m[:3,:3]=bind[i][:3,:3] if name=='Servicio' else orient@gm[ankle][frame]@gm[ankle][start].T@orient.T@bind[i][:3,:3]
  transforms.append(m)
 local=[m if bones[i]['parent']<0 else np.linalg.inv(transforms[bones[i]['parent']])@m for i,m in enumerate(transforms)]
 frames.append(local)
lines=['[gd_resource type="AnimationLibrary" format=3]','[sub_resource type="Animation" id="Serve"]','length = '+str(duration)]
for i,b in enumerate(bones):
 for typ in ['rotation_3d','position_3d']:
  ti=i*2+(typ=='position_3d');vals=[]
  for k,pose in enumerate(frames):
   v=R.from_matrix(pose[i][:3,:3]).as_quat() if typ=='rotation_3d' else pose[i][:3,3]
   vals.extend([k*.03,1,*v])
  lines.extend([f'tracks/{ti}/type = "{typ}"',f'tracks/{ti}/path = NodePath("CharacterArmature/Skeleton3D:{b["name"]}")',f'tracks/{ti}/interp = 1',f'tracks/{ti}/keys = PackedFloat32Array('+', '.join(f'{v:.7g}' for v in vals)+')'])
lines+=['[resource]','_data = {"'+name+'": SubResource("Serve")}']
open(output_path,'w').write('\n'.join(lines)+'\n')
