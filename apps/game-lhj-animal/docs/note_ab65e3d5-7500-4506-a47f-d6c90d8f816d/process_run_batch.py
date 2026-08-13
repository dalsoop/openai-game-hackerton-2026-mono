from pathlib import Path
from PIL import Image, ImageChops, ImageStat
import itertools

ROOT = Path(__file__).parent / "assets"
ANIMALS = ["hippo", "panda", "crocodile", "beaver", "koala", "mole", "squirrel"]

def bbox_alpha(im):
    return im.getchannel("A").point(lambda x: 255 if x > 8 else 0).getbbox()

def magenta_center(im):
    px = im.load(); xs=[]; ys=[]
    for y in range(im.height):
        for x in range(im.width):
            r,g,b,a=px[x,y]
            if a>32 and r>180 and b>140 and g<90:
                xs.append(x); ys.append(y)
    return ((sum(xs)/len(xs),sum(ys)/len(ys)) if xs else (im.width/2,im.height/2))

def ahash(im, size=32):
    a=im.getchannel("A").resize((size,size),Image.Resampling.LANCZOS)
    vals=list(a.getdata()); mean=sum(vals)/len(vals)
    return [v>=mean for v in vals]

def process(animal):
    folder=ROOT/f"{animal}_run_24f"; folder.mkdir(exist_ok=True)
    sources=[Image.open(folder/f"{animal}-run-half-{n}-alpha.png").convert("RGBA") for n in (1,2)]
    raw=[]
    for src in sources:
        cw,ch=src.width//4,src.height//3
        for row in range(3):
            for col in range(4):
                cell=src.crop((col*cw,row*ch,(col+1)*cw,(row+1)*ch))
                bb=bbox_alpha(cell)
                if not bb: raise RuntimeError(f"{animal}: empty cell")
                raw.append(cell.crop(bb))
    if len(raw)!=24: raise RuntimeError(f"{animal}: {len(raw)} frames")
    maxw=max(x.width for x in raw); maxh=max(x.height for x in raw)
    scale=min(220/maxw,220/maxh,1.0)
    scaled=[x.resize((max(1,round(x.width*scale)),max(1,round(x.height*scale))),Image.Resampling.LANCZOS) for x in raw]
    centers=[magenta_center(x) for x in scaled]
    target_x=128
    # Preserve motion bounce while normalizing horizontal shirt/chest anchor only.
    frames=[]; margins=[]
    for i,(im,(cx,cy)) in enumerate(zip(scaled,centers),1):
        canvas=Image.new("RGBA",(256,256),(0,0,0,0))
        x=round(target_x-cx); y=round((256-im.height)/2)
        # Keep the shirt anchor when possible, but clamp translation so large
        # tails/props retain the hard five-pixel independent-cell margin.
        x=max(5,min(x,256-im.width-5))
        y=max(5,min(y,256-im.height-5))
        canvas.alpha_composite(im,(x,y))
        bb=bbox_alpha(canvas)
        if not bb: raise RuntimeError(f"{animal} frame {i}: empty")
        m=(bb[0],bb[1],256-bb[2],256-bb[3]); margins.append(m)
        if min(m)<5: raise RuntimeError(f"{animal} frame {i}: margin {m}")
        canvas.save(folder/f"frame_{i:02}.png")
        frames.append(canvas)
    sheet=Image.new("RGBA",(256*24,256),(0,0,0,0))
    for i,im in enumerate(frames): sheet.alpha_composite(im,(i*256,0))
    sheet.save(folder/f"{animal}-run-24f-sheet.png")
    frames[0].save(folder/f"{animal}-run-24f-12fps.webp",save_all=True,append_images=frames[1:],duration=83,loop=0,lossless=True)
    green=[]
    for im in frames:
        bg=Image.new("RGBA",im.size,(0,255,0,255)); bg.alpha_composite(im); green.append(bg.convert("RGB"))
    green[0].save(folder/f"{animal}-run-24f-12fps.gif",save_all=True,append_images=green[1:],duration=83,loop=0)
    hashes=[ahash(x) for x in frames]
    small=[x.getchannel("A").resize((64,64),Image.Resampling.LANCZOS) for x in frames]
    exact=[]; near=[]
    for i,j in itertools.combinations(range(24),2):
        ham=sum(a!=b for a,b in zip(hashes[i],hashes[j]))
        mad=ImageStat.Stat(ImageChops.difference(small[i],small[j])).mean[0]/255
        if ham==0 and mad<.005: exact.append((i+1,j+1,ham,mad))
        elif ham<=20 and mad<.035: near.append((i+1,j+1,ham,mad))
    report=[f"animal={animal}","frames=24","pair_count=276",f"exact_duplicates={len(exact)}",f"near_duplicates={len(near)}",f"minimum_margin={min(map(min,margins))}"]
    report += [f"exact {a:02}-{b:02} h={h} mad={m:.6f}" for a,b,h,m in exact]
    report += [f"near {a:02}-{b:02} h={h} mad={m:.6f}" for a,b,h,m in near]
    (folder/"duplicate-report.txt").write_text("\n".join(report)+"\n",encoding="utf-8")
    print(" | ".join(report[:6]))

for animal in ANIMALS: process(animal)
