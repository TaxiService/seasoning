#!/usr/bin/env python3
from __future__ import annotations
from datetime import datetime
def line(p: float, w: int = 24) -> str:
    full=int(p*w); rem=p*w-full; s=[" "]*w
    for i in range(full): s[i]="█"
    if 0<rem<1 and full<w: s[full]="▌"
    for i in range(0,w,6): s[i]="┃" if s[i].strip() else "|"
    return "".join(s)
now=datetime.now(); w=24
h=((now.hour%12)+now.minute/60)/12; m=(now.minute+now.second/60)/60; s=now.second/60
print(line(h,w)); print(line(m,w)); print(line(s,w))
