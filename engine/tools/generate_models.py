#!/usr/bin/env python3
"""Generate original low-poly OBJ/MTL models for GANGSTER: NEW YORK. No ripped game assets."""
from pathlib import Path
import math
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'android/src/main/assets/models'
OUT.mkdir(parents=True,exist_ok=True)
MATS={
 'skin':'0.78 0.55 0.40','jacket':'0.055 0.11 0.20','shirt':'0.75 0.76 0.72',
 'pants':'0.07 0.085 0.12','shoes':'0.025 0.025 0.03','hair':'0.035 0.025 0.02',
 'glass':'0.12 0.28 0.38','paint':'0.10 0.22 0.42','rubber':'0.025 0.025 0.028',
 'metal':'0.45 0.48 0.50','trunk':'0.24 0.12 0.055','leaves':'0.10 0.30 0.14',
 'concrete':'0.48 0.49 0.50','brick':'0.42 0.23 0.17','roof':'0.18 0.19 0.21'}
def box(x,y,z,w,h,d):
 a,b=x-w/2,x+w/2;c,e=y-h/2,y+h/2;f,g=z-d/2,z+d/2
 v=[(a,c,f),(b,c,f),(b,e,f),(a,e,f),(a,c,g),(b,c,g),(b,e,g),(a,e,g)]
 faces=[(0,2,1),(0,3,2),(4,5,6),(4,6,7),(0,1,5),(0,5,4),(1,2,6),(1,6,5),(2,3,7),(2,7,6),(3,0,4),(3,4,7)]
 return v,faces
def cylinder(x,y,z,r,h,n=12,axis='y'):
 v=[]
 for t in (-h/2,h/2):
  for i in range(n):
   a=2*math.pi*i/n
   if axis=='y':v.append((x+r*math.cos(a),y+t,z+r*math.sin(a)))
   else:v.append((x+t,y+r*math.cos(a),z+r*math.sin(a)))
 f=[]
 for i in range(n):
  j=(i+1)%n;f.extend([(i,j,n+j),(i,n+j,n+i)])
 v.extend([(x,y-h/2,z),(x,y+h/2,z)])
 f.extend([(2*n,i,(i+1)%n) for i in range(n)])
 f.extend([(2*n+1,n+(i+1)%n,n+i) for i in range(n)])
 return v,f
def sphere(x,y,z,rx,ry,rz,rings=8,segs=12):
 v=[]
 for r in range(rings+1):
  p=math.pi*r/rings
  for s in range(segs):
   t=2*math.pi*s/segs;v.append((x+rx*math.sin(p)*math.cos(t),y+ry*math.cos(p),z+rz*math.sin(p)*math.sin(t)))
 f=[]
 for r in range(rings):
  for s in range(segs):
   a=r*segs+s;b=r*segs+(s+1)%segs;c=(r+1)*segs+(s+1)%segs;d=(r+1)*segs+s
   f.extend([(a,d,b),(b,d,c)])
 return v,f
def write(name,parts):
 mtl=['# Original generated material library']
 for k,c in MATS.items():mtl += [f'newmtl {k}',f'Ka {c}',f'Kd {c}','Ks 0.12 0.12 0.12','Ns 24','']
 obj=[];vi=1;ni=1
 for mat,(v,faces) in parts:
  obj.append('usemtl '+mat);obj += [f'v {x:.5f} {y:.5f} {z:.5f}' for x,y,z in v]
  for face in faces:
   a,b,c=[v[i] for i in face[:3]];u=[b[i]-a[i] for i in range(3)];q=[c[i]-a[i] for i in range(3)]
   n=[u[1]*q[2]-u[2]*q[1],u[2]*q[0]-u[0]*q[2],u[0]*q[1]-u[1]*q[0]]
   l=math.sqrt(sum(t*t for t in n)) or 1
   obj.append('vn '+' '.join(f'{t/l:.6f}' for t in n))
  for j,face in enumerate(faces):obj.append('f '+' '.join(f'{vi+i}//{ni+j}' for i in face))
  vi+=len(v);ni+=len(faces)
 (OUT/(name+'.obj')).write_text(f'mtllib {name}.mtl\n'+'\n'.join(obj)+'\n')
 (OUT/(name+'.mtl')).write_text('\n'.join(mtl)+'\n')
def build():
 p=[('pants',box(0,-.5,0,.42,.72,.27)),('shoes',box(0,-.91,-.035,.48,.16,.42)),
 ('jacket',box(0,.25,0,.66,.82,.34)),('shirt',box(0,.27,-.18,.25,.6,.08)),
 ('skin',box(0,.83,0,.34,.36,.32)),('hair',box(0,1.02,0,.36,.13,.34)),
 ('jacket',box(-.39,.28,0,.2,.68,.2)),('jacket',box(.39,.28,0,.2,.68,.2)),
 ('pants',box(-.14,-.48,0,.18,.55,.2)),('pants',box(.14,-.48,0,.18,.55,.2))]
 write('carl_lowpoly',p)
 p=[('paint',box(0,.48,0,1.9,.55,4.1)),('paint',box(0,.92,.15,1.55,.68,2)),
 ('glass',box(0,.98,-.42,1.48,.48,.92)),('glass',box(0,.98,.7,1.48,.48,.75))]
 for x in (-.98,.98):
  for z in (-1.35,1.35):p.append(('rubber',cylinder(x,.35,z,.39,.22,16,'x')))
 for x in (-.58,.58):p.append(('metal',box(x,.54,-2.07,.25,.15,.06)))
 write('sedan_blue',p)
 write('street_tree',[('trunk',cylinder(0,1.1,0,.22,2.2)),('leaves',sphere(0,2.55,0,1.05,1.15,1.05)),('leaves',sphere(.55,2.3,.15,.72,.78,.72))])
 write('streetlight',[('metal',cylinder(0,2.5,0,.09,5)),('metal',box(.75,4.8,0,1.5,.09,.09)),('roof',box(1.42,4.7,0,.28,.22,.28))])
 for name,w,d,h,mat in [('building_low',12,12,10,'brick'),('building_mid',12,12,24,'concrete'),('building_tower',13,13,48,'concrete'),('warehouse',20,14,9,'brick')]:
  p=[(mat,box(0,h/2,0,w,h,d)),('roof',box(0,h+.18,0,w+.3,.36,d+.3))]
  rows=max(1,int(h//3));cols=max(2,int(w//2.6))
  for row in range(rows):
   yy=2+row*2.7
   if yy>h-1:continue
   for col in range(cols):
    xx=-w/2+1.3+col*(w-2.6)/max(1,cols-1)
    p.append(('glass',box(xx,yy,-d/2-.015,.85,1.35,.035)))
    p.append(('glass',box(w/2+.015,yy,xx,.035,1.35,.85)))
  write(name,p)
 (OUT/'ASSET_CREDITS.txt').write_text('Original procedural low-poly OBJ/MTL meshes generated for GANGSTER: NEW YORK. Import OBJ files into Blender to edit.\n')
 try:
  import trimesh
  glb=ROOT/'art-source/glb';glb.mkdir(parents=True,exist_ok=True)
  for obj in OUT.glob('*.obj'):
   scene=trimesh.load(obj,force='scene',process=False)
   (glb/(obj.stem+'.glb')).write_bytes(trimesh.exchange.gltf.export_glb(scene))
  print('Also exported GLB files to',glb)
 except ImportError:pass
 print('Generated',len(list(OUT.glob('*.obj'))),'original 3D OBJ models in',OUT)
if __name__=='__main__':build()
