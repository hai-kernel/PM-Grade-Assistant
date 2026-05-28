p=r"d:\ki8\prm\PM-Grade-Assistant\lib\screens\setup\setup_screen.dart"
with open(p, 'r', encoding='utf-8') as f:
    lines=f.readlines()
count=0
for i,l in enumerate(lines,1):
    for ch in l:
        if ch=='{': count+=1
        elif ch=='}': count-=1
    if count<0:
        print('Negative at line',i)
        for ln in range(max(1,i-3), min(len(lines), i+3)+1):
            print(f"{ln}: {lines[ln-1].rstrip()}")
        break
else:
    print('Final count',count)
