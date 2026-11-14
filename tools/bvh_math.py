import numpy as np

# ---------- BVH ----------
def parse_bvh(path):
    lines = open(path,'r',errors='ignore').read().splitlines()
    joints=[]; stack=[]; i=0
    while i < len(lines):
        l=lines[i].strip()
        if l.startswith(('ROOT','JOINT')):
            name=l.split()[1]; parent=stack[-1] if stack else -1
            joints.append({'name':name,'parent':parent,'offset':np.zeros(3),'chans':[]})
            stack.append(len(joints)-1); i+=1
        elif l=='End Site':
            joints.append({'name':'End'+str(len(joints)),'parent':stack[-1],'offset':np.zeros(3),'chans':[],'end':True})
            i+=1
            while lines[i].strip()!='}':
                ll=lines[i].strip()
                if ll.startswith('OFFSET'): joints[-1]['offset']=np.array([float(x) for x in ll.split()[1:4]])
                i+=1
            i+=1
        elif l=='{': i+=1
        elif l=='}': stack.pop(); i+=1
        elif l.startswith('OFFSET'):
            joints[stack[-1]]['offset']=np.array([float(x) for x in l.split()[1:4]]); i+=1
        elif l.startswith('CHANNELS'):
            p=l.split(); joints[stack[-1]]['chans']=p[2:2+int(p[1])]; i+=1
        elif l.startswith('MOTION'):
            i+=3; break
        else: i+=1
    data=np.loadtxt(lines[i:],dtype=float)
    return joints, data

def rot_axis(axis, deg):
    a=np.deg2rad(deg); c=np.cos(a); s=np.sin(a)
    Z=np.zeros_like(a); O=np.ones_like(a)
    if axis=='X': return np.stack([O,Z,Z,Z,c,-s,Z,s,c],-1).reshape(-1,3,3)
    if axis=='Y': return np.stack([c,Z,s,Z,O,Z,-s,Z,c],-1).reshape(-1,3,3)
    return np.stack([c,-s,Z,s,c,Z,Z,Z,O],-1).reshape(-1,3,3)

def bvh_fk(joints, data):
    N=data.shape[0]; gm=[None]*len(joints); gp=[None]*len(joints); ch=0
    for idx,j in enumerate(joints):
        rots=None; pos=np.zeros((N,3))
        for c in j['chans']:
            v=data[:,ch]; ch+=1
            if c=='Xposition': pos[:,0]+=v
            elif c=='Yposition': pos[:,1]+=v
            elif c=='Zposition': pos[:,2]+=v
            else:
                m=rot_axis(c[0],v); rots=m if rots is None else rots@m
        if rots is None: rots=np.tile(np.eye(3),(N,1,1))
        if j['parent']==-1: gm[idx]=rots; gp[idx]=pos+j['offset']
        else:
            p=j['parent']; gm[idx]=gm[p]@rots; gp[idx]=gp[p]+np.einsum('nij,j->ni',gm[p],j['offset'])
    return gm,gp
