def add(p1, p2):
    return tuple(map(sum, zip(p1, p2)))

s = 4

t = [(i * (i - 1)) >> 1 for i in range(0, s + 1)]
# t = [((1, 0) if (i%2 == 0) else (0, 1)) for i in range(0, s + 1)]

for n in range(s + 1, 100):
    t.append(n - 1 + t[n >> 1] + t[(n + 1) >> 1])

for a, v in enumerate(t):
    print(a, v)