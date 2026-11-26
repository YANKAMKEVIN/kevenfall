import random, statistics, sys
def run(P, policy='smart', shards=0, seed=None):
    R=random.Random(seed)
    F=25.0; dt=0.05; MENU=P['menu']
    H={'gamin':dict(hp=P['g_hp']+8*shards,mhp=P['g_hp']+8*shards,pr=12,mpr=12,spd=P['g_spd'],atb=55,alive=True,defend=False),
       'soldate':dict(hp=120,mhp=120,pr=8,mpr=8,spd=0.85,atb=30,alive=True,defend=False)}
    E={'golem':dict(hp=P['golem_hp'],spd=P['golem_spd'],atb=10,alive=True,armor=True,charging=False,turns=0),
       'spectre':dict(hp=P['sp_hp'],spd=P['sp_spd'],atb=25,alive=True,turns=0)}
    guard=False; t=0.0
    def hurt(tid,base):
        nonlocal guard
        h=H[tid]
        if tid=='gamin' and guard and H['soldate']['alive']:
            h=H['soldate']; base*=0.6
        if not h['alive']: return
        if h['defend']: base*=0.5
        h['hp']-=max(1,round(base))
        if h['hp']<=0: h['hp']=0; h['alive']=False
    def hit(eid,base,kind):
        e=E[eid]
        if not e['alive']: return
        d=base
        if eid=='spectre' and kind=='phys' and R.random()<0.4: return
        if eid=='spectre' and kind=='foudre': d*=1.5
        if eid=='golem':
            if e['armor'] and kind=='phys': d*=0.4
            elif kind=='foudre': d*=0.8
            elif kind=='phys': d*=1.2
        e['hp']-=max(1,round(d))
        if e['hp']<=0: e['hp']=0; e['alive']=False
    def enemy(eid):
        e=E[eid]; alive=[k for k in H if H[k]['alive']]
        if not alive: return
        e['turns']+=1
        def pick():
            if 'gamin' in alive and R.random()<0.6: return 'gamin'
            return R.choice(alive)
        if eid=='golem':
            if e['charging']:
                e['charging']=False
                for k in alive: hurt(k,R.randint(*P['ebou']))
            elif e['turns']%3==0: e['charging']=True
            else: hurt(pick(),R.randint(*P['roc']))
        else:
            tg=pick()
            if R.random()<0.3:
                hurt(tg,R.randint(4,6))
                real='soldate' if (tg=='gamin' and guard and H['soldate']['alive']) else tg
                H[real]['atb']=0
            else: hurt(tg,R.randint(8,11))
        e['atb']=0
    def menu_wait():
        nonlocal t
        tt=0
        while tt<MENU:
            for k,e in E.items():
                if e['alive']:
                    e['atb']+=F*e['spd']*dt*0.3
                    if e['atb']>=100: enemy(k)
            tt+=dt; t+=dt
    while t<600:
        if not any(e['alive'] for e in E.values()): return True,t,H
        if not any(h['alive'] for h in H.values()): return False,t,H
        for k,e in E.items():
            if e['alive']:
                e['atb']+=F*e['spd']*dt
                if e['atb']>=100: enemy(k)
        ready=[]
        for k,h in H.items():
            if h['alive'] and h['atb']<100:
                h['atb']=min(100,h['atb']+F*h['spd']*dt)
            if h['alive'] and h['atb']>=100: ready.append(k)
        t+=dt
        for k in ready:
            h=H[k]
            if not h['alive'] or h['atb']<100: continue
            menu_wait()
            if not h['alive']: continue
            h['defend']=False
            if k=='soldate': guard=False
            g,s=H['gamin'],H['soldate']; gol=E['golem']; sp=E['spectre']
            ealive=[x for x in E if E[x]['alive']]
            if not ealive: break
            act=None
            other='soldate' if k=='gamin' else 'gamin'
            rnd = policy=='novice' and R.random()<0.35
            if not rnd and H[other]['alive'] and H[other]['atb']>=100 and g['pr']>=3 and s['pr']>=2 and (gol['alive'] and gol['armor'] or len(ealive)>=2):
                g['pr']-=3; s['pr']-=2
                for x in ealive:
                    hit(x,R.randint(24,28),'combo')
                if gol['alive']: gol['armor']=False
                sp['atb']=0
                g['atb']=0; s['atb']=0
                continue
            if rnd:
                act=R.choice(['attack','attack','skill','defend'])
            elif gol['alive'] and gol['charging']:
                act='skill' if (k=='soldate' and h['pr']>=2 and g['alive']) else 'defend'
            else:
                act='skill' if (k=='gamin' and h['pr']>=3) else 'attack'
            tgt='spectre' if sp['alive'] else 'golem'
            if k=='soldate' and gol['alive'] and not rnd: tgt='golem' if not gol['armor'] else tgt
            if act=='attack':
                hit(tgt if E[tgt]['alive'] else ealive[0], R.randint(7,9) if k=='gamin' else R.randint(12,15),'phys')
            elif act=='skill':
                if k=='gamin' and h['pr']>=3:
                    h['pr']-=3; hit(tgt if E[tgt]['alive'] else ealive[0],R.randint(16,20),'foudre')
                elif k=='soldate' and h['pr']>=2:
                    h['pr']-=2; guard=True
                else:
                    hit(ealive[0],7,'phys')
            else:
                h['defend']=True; h['pr']=min(h['mpr'],h['pr']+3)
            if act!='defend': h['pr']=min(h['mpr'],h['pr']+1)
            h['atb']=0
    return False,t,H
P=dict(menu=1.5,g_hp=64,g_spd=1.25,golem_hp=150,golem_spd=0.42,sp_hp=80,sp_spd=0.8,roc=(13,16),ebou=(13,16))
import json
if len(sys.argv)>1: P.update(json.loads(sys.argv[1]))
for pol in ['smart','novice']:
  for sh in [0,3]:
    res=[run(P,pol,sh,i) for i in range(600)]
    w=[r for r in res if r[0]]
    print(pol,'eclats',sh,'win %.0f%%'%(100*len(w)/len(res)),'dur %.0fs'%statistics.mean(r[1] for r in res),
      'hp restant %.0f%%'%(100*statistics.mean((r[2]['gamin']['hp']+r[2]['soldate']['hp'])/(r[2]['gamin']['mhp']+r[2]['soldate']['mhp']) for r in w)) if w else '')
