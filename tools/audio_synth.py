import numpy as np, wave, sys, os
SR=22050
OUT=sys.argv[1]
rng=np.random.default_rng(7)
def save(name,x,stereo=False):
    x=np.asarray(x,dtype=np.float64)
    m=np.max(np.abs(x))+1e-9
    x=x/m*0.89
    d=(x*32767).astype(np.int16)
    with wave.open(os.path.join(OUT,name),'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(d.tobytes())
def t(d): return np.arange(int(SR*d))/SR
def env(n,a,r):
    e=np.ones(n); A=int(a*SR); R=int(r*SR)
    if A>0: e[:A]=np.linspace(0,1,A)
    if R>0: e[-R:]*=np.linspace(1,0,R)
    return e
def lp(x,alpha):
    y=np.zeros_like(x); acc=0.0
    for i in range(len(x)):
        acc+=alpha*(x[i]-acc); y[i]=acc
    return y
def lpf(x,a):  # fast one-pole via scipy-free cumulative trick (loop ok for short)
    return lp(x,a)
def noise(d): return rng.uniform(-1,1,int(SR*d))
def midi(n): return 440*2**((n-69)/12)
# rain loop 8s seamless
n=noise(8.0); r=lpf(n,0.35)-lpf(n,0.02)
drops=np.zeros_like(r)
for k in range(900):
    p=rng.integers(0,len(r)-300); drops[p:p+300]+=rng.uniform(0.2,1)*np.exp(-np.arange(300)/30)*rng.uniform(-1,1,300)
r=r*0.6+drops*0.25
fade=int(0.5*SR); r[:fade]=r[:fade]*np.linspace(0,1,fade)+r[-fade:]*np.linspace(1,0,fade); r=r[:-fade]
save('rain_loop.wav',r)
# thunder
d=4.0; n=noise(d); x=lpf(n,0.02)*np.exp(-t(d)*0.9)*3
crack=lpf(noise(0.4),0.5)*np.exp(-t(0.4)*12); x[:len(crack)]+=crack*0.8
x*= (1+0.6*np.sin(t(d)*7))
save('thunder.wav',x)
# zap
d=0.6; tt=t(d); f=900*np.exp(-tt*3)+200
ph=np.cumsum(f)/SR; x=np.sign(np.sin(2*np.pi*ph))*0.4+noise(d)*0.6
x*=np.exp(-tt*5)*(0.6+0.4*(rng.uniform(0,1,len(tt))>0.5))
save('zap.wav',lpf(x,0.6))
# hit
d=0.25; tt=t(d); x=np.sin(2*np.pi*np.cumsum(160*np.exp(-tt*14)+50)/SR)*np.exp(-tt*16)+lpf(noise(d),0.3)*np.exp(-tt*30)*0.7
save('hit.wav',x)
# stone heavy
d=0.7; tt=t(d); x=np.sin(2*np.pi*np.cumsum(90*np.exp(-tt*6)+35)/SR)*np.exp(-tt*6)+lpf(noise(d),0.08)*np.exp(-tt*5)*1.2
save('stone.wav',x)
# slash
d=0.3; tt=t(d); n=noise(d); x=(lpf(n,0.7)-lpf(n,0.15))*np.sin(np.pi*np.clip(tt/0.3,0,1))**2
save('slash.wav',x)
# ui
def tone(fr,d,dec=20,wav='sine'):
    tt=t(d); s=np.sin(2*np.pi*fr*tt)
    if wav=='tri': s=2/np.pi*np.arcsin(s)
    return s*np.exp(-tt*dec)*env(len(tt),0.003,0.01)
save('select.wav',tone(1320,0.08,40,'tri'))
save('confirm.wav',np.concatenate([tone(988,0.07,30,'tri'),tone(1480,0.16,18,'tri')]))
save('cancel.wav',np.concatenate([tone(660,0.07,30,'tri'),tone(440,0.12,20,'tri')]))
save('blip.wav',tone(880,0.035,60,'tri'))
save('ready.wav',tone(1760,0.25,12)+tone(2637,0.25,14)*0.5)
x=np.zeros(int(SR*1.4))
for i,nn in enumerate([76,79,83,88,91]):
    s=tone(midi(nn),0.6,6); p=int(i*0.09*SR); x[p:p+len(s)]+=s
save('pickup.wav',x)
x=np.zeros(int(SR*1.6)); 
for nn in [57,60,64]: x+=tone(midi(nn),1.6,2.5,'tri')
x+=lpf(noise(1.6),0.05)*np.exp(-t(1.6)*2)*2
save('heal.wav',x)
# music explore : D minor pad 32s
BPM=60; d=32.0; tt=t(d); x=np.zeros(len(tt))
chords=[[50,57,62,65],[46,53,58,62],[48,55,60,64],[45,52,57,61]]
for ci,ch in enumerate(chords*2):
    st=ci*4.0; seg=(tt>=st)&(tt<st+4.6)
    lt=tt[seg]-st
    e=np.clip(lt/1.2,0,1)*np.clip((4.6-lt)/1.0,0,1)
    for nn in ch:
        f=midi(nn)
        x[seg]+=(np.sin(2*np.pi*f*lt)+0.3*np.sin(2*np.pi*f*2.003*lt)+0.15*np.sin(2*np.pi*f*0.5*lt))*e*0.25
mel=[74,72,69,0,72,69,65,0,70,69,67,0,69,0,64,0, 74,76,77,0,76,74,72,0,72,70,69,0,69,0,0,0]
for i,nn in enumerate(mel):
    if nn==0: continue
    p=int(i*1.0*SR); s=tone(midi(nn),2.5,1.6)+tone(midi(nn+12),2.5,3)*0.3
    s=s[:len(x)-p]; x[p:p+len(s)]+=s*0.5
x+=lpf(noise(d),0.03)*0.4
# loop crossfade
f=int(1.5*SR); x[:f]+=0  # rely on ending fade into start
x[-f:]*=np.linspace(1,0.4,f)
save('music_explore.wav',x)
# battle music 140 bpm, 16 bars (4/4)
BPM=140; beat=60/BPM; bars=16; d=bars*4*beat; tt=t(d); x=np.zeros(len(tt))
def put(s,at):
    p=int(at*SR); s=s[:max(0,len(x)-p)]; x[p:p+len(s)]+=s
kick=lambda: np.sin(2*np.pi*np.cumsum(120*np.exp(-t(0.3)*25)+45)/SR)*np.exp(-t(0.3)*10)
snare=lambda: lpf(noise(0.2),0.5)*np.exp(-t(0.2)*18)+tone(200,0.2,25)*0.5
hat=lambda: (noise(0.05)-lpf(noise(0.05),0.3))*np.exp(-t(0.05)*80)
prog=[50,50,46,48]  # D D Bb C
for b in range(bars):
    root=prog[(b//2)%4]
    for k in range(8):
        at=b*4*beat+k*beat/2
        if k in (0,3,4): put(kick()*0.9,at)
        if k in (2,6): put(snare()*0.6,at)
        put(hat()*0.25,at)
        nn=root-12+(12 if k%2 else 0)
        s=np.sin(2*np.pi*np.cumsum(np.full(int(beat/2*SR),midi(nn)))/SR)
        s=np.sign(s)*0.3+s*0.5; s*=np.exp(-t(beat/2)*6)
        put(lpf(s,0.25)*0.7,at)
    if b>=4:
        arp=[root+12,root+19,root+24,root+15] if root!=50 else [62,69,74,65]
        for k in range(8):
            nn=arp[k%4]+12
            put(tone(midi(nn),beat/2,9,'tri')*0.22,b*4*beat+k*beat/2)
lead=[74,0,72,74,77,0,76,74, 70,0,72,70,69,0,67,69]
for b in range(8,16):
    for k in range(2):
        nn=lead[((b-8)*2+k)%16]
        if nn: put(tone(midi(nn),beat*2,1.5,'tri')*0.35+tone(midi(nn)*1.005,beat*2,1.5,'tri')*0.2,b*4*beat+k*2*beat)
save('music_battle.wav',x)
# victory jingle
x=np.zeros(int(SR*3.2))
for i,(nn,dd) in enumerate([(62,0.15),(66,0.15),(69,0.15),(74,0.5),(71,0.25),(74,1.6)]):
    pass
at=0
for nn,dd in [(62,0.14),(66,0.14),(69,0.14),(74,0.42),(72,0.14),(74,1.8)]:
    s=tone(midi(nn),dd+0.6,3,'tri')+tone(midi(nn+12),dd+0.6,5)*0.3; p=int(at*SR); s=s[:len(x)-p]; x[p:p+len(s)]+=s; at+=dd
for nn in [50,57,62,66]:
    s=tone(midi(nn),2.0,1.5); p=int(0.84*SR); x[p:p+len(s)]+=s*0.4
save('victory.wav',x)
print('ok')
