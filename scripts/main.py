from random import shuffle
from copy import copy
from random import randint


# Note: process time only includes time spent in the running or waiting states
# Using this timer should remove variance resulting from the CPU scheduler
from time import process_time

# largest integer possible in data set
x = 10**18

def gen_random_list(n):
    return list(map(lambda _: randint(1, x), range(n)))

s = 10
keycomp = 0
def hybrid_merge(a):
    global keycomp, s
    if(len(a) <= s):
        for i in range(1, len(a)):
            for j in range(i - 1, -1, -1):
                keycomp += 1
                if(a[j] > a[j + 1]):
                    a[j], a[j + 1] = a[j + 1], a[j]
                else:
                    break
    else:
        n = len(a)
        m = n >> 1
        l = a[0:m]
        r = a[m:n]
        l = hybrid_merge(l)
        r = hybrid_merge(r)
        ls = m
        rs = n - m
        i = 0
        j = 0
        p = 0
        while(i < ls and j < rs):
            keycomp += 1
            if(l[i] <= r[j]):
                a[p] = l[i]
                i += 1
            else:
                a[p] = r[j]
                j += 1
            p += 1
        while(i < ls):
            a[p] = l[i]
            i += 1
            p += 1
        while(j < rs):
            a[p] = r[j]
            j += 1
            p += 1
    return a

# Driver code
T = 20
n = 1 << 15

tests = list(map(lambda _: list(range(n)), range(T)))

for i in range(T):
    tests[i] = gen_random_list(n)

# test = list(range(2000))

# svals = [1, 2, 3, 5, 7, 10, 15, 20, 25, 30, 40, 50]
svals = list(range(5, 21))

for cs in svals:
    s = cs
    keycomp = 0
    time_start = process_time()
    for i in range(T):
        hybrid_merge(copy(tests[i]))

    print(f"{cs}: {(process_time() - time_start) / T * 1000:.3f}ms, {keycomp / T:.2f} key comps")