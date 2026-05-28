p=r"d:\ki8\prm\PM-Grade-Assistant\lib\screens\setup\setup_screen.dart"
with open(p, 'r', encoding='utf-8') as f:
    lines=f.readlines()
count=0
for i,l in enumerate(lines,1):
    if '{' in l or '}' in l:
        o=l.count('{')
        c=l.count('}')
        count += o - c
        print(f"{i:4}: +{o} -{c} => {count}   | {l.rstrip()}")
        if count<0:
            break
print('done')
