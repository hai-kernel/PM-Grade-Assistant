import sys
p=r"d:\ki8\prm\PM-Grade-Assistant\lib\screens\setup\setup_screen.dart"
with open(p, 'r', encoding='utf-8') as f:
    s=f.readlines()
stack=[]
pairs={'(':')','[':']','{':'}'}
closes={v:k for k,v in pairs.items()}
for i,l in enumerate(s,1):
    for j,ch in enumerate(l,1):
        if ch in pairs:
            stack.append((ch,i,j))
        elif ch in closes:
            if not stack:
                print('Unmatched close',ch,'at',i,j)
                print('Context lines:')
                for ln in range(max(1,i-3), min(len(s), i+3)+1):
                    print(f"{ln}: {s[ln-1].rstrip()}")
                sys.exit(0)
            opench,li,c=stack.pop()
            if pairs[opench]!=ch:
                print('Mismatched',opench,'at',li,c,'vs',ch,'at',i,j)
                sys.exit(0)
print('Stack len',len(stack))
if stack:
    for opench,li,c in stack[-10:]:
        print('Unclosed',opench,'at',li,c)
