# !C:\Users\protondecay314\venv\sc1003-project\Scripts\Activate.ps1

import matplotlib.pyplot as plt

from matplotlib import cm
from matplotlib.ticker import LinearLocator

from math import log, log2, ceil
from functools import lru_cache

@lru_cache(maxsize=128)
def t(n, s):
    return n - 1 + t(n >> 1, s) + t(((n + 1) >> 1), s) if n > s else ((n * (n - 1)) >> 1)

@lru_cache(maxsize=128)
def tcont(n, s):
    return n - 1.0 + tcont(n * 0.5, s) * 2.0 if n > s else ((n * (n - 1.0)) * 0.5)

def avg(a):
    return sum(a) / len(a)

def ss(a):
    return sum(map(lambda x: x**2, a))

def r_squared(data, pred):
    data_mean = avg(data)
    ss_tot = ss(list(map(lambda x: x - data_mean, data)))

    ss_resid = ss(list(map(lambda x: x[1] - x[0], zip(data, pred))))

    return 1.0 - ss_resid / ss_tot

n = 10000000

x = [s for s in range(1, n + 101)]
y = [t(n, s) for s in range(1, n + 101)]
yf = [tcont(n, s) for s in range(1, n + 101)]

# Upper bound
yapprox = [n * log2(n / s) - n / s + 1.0 + n * (s - 1.0) * 0.5 for s in range(1, n + 101)]
yapprox2a = [n * (log2(n / s) + log2(3.0) - 1.0) - n / s * 1.5 + 1.0 + n * (s / 3.0 - 0.5) for s in range(1, n + 101)]
yapprox2d = [n * (ceil(log2(n / s))) - 2.0 ** ceil(log2(n / s)) + 1.0 + n * (s / (2.0 * (2.0 ** (ceil(log2(n / s)) - log2(n / s)))) - 0.5) for s in range(1, n + 101)]
# yapprox2b = [n * (log2(n / s) + 0.5) - n / s * (2.0 ** 0.5) + 1.0 + n * (s / (2.0 * (2.0 ** 0.5)) - 0.5) for s in range(1, n + 101)]
# yapprox2c = [n * (log2(n / s) + 0.5) - n / s * 1.5 + 1.0 + n * (s * 0.375 - 0.5) for s in range(1, n + 101)]

# Upper bound
yapprox3 = [n * (log2(n / s) + 1.0) - n / s * 2.0 + 1.0 + n * (s - 2.0) * 0.25 for s in range(1, n + 101)]

print(r_squared(y, yapprox2a))
print(r_squared(y, yapprox2d))

"""
n(s - 2) / (4)

n(s - 2) / (4)

n / 2^k * (n / 2^k - 1) / 2

n * (n - 2^k) / 2^(k + 1)

n(s - 2) / (4)
"""
# print(y)

plt.title(f"Worst-case Key Comparisons Over Different Insertion Sort Thresholds ($n=10^7$)")
plt.grid(visible=True)
plt.xlim(min(x), max(x))
plt.ylim(0, (max(y) * 11) // 10)
plt.xlabel("Insertion Sort Threshold ($s$)")
plt.ylabel("Worst-case Number of Key Comparisons")
plt.plot(x, y, linewidth=1.5)
# plt.plot(x, yf)
plt.plot(x, yapprox, linestyle="dashed", linewidth=0.75)
plt.plot(x, yapprox2a, linestyle="dashed", linewidth=0.75)
# plt.plot(x, yapprox2b, linestyle="dotted", linewidth=0.75)
# plt.plot(x, yapprox2c, linestyle="dotted", linewidth=0.75)
plt.plot(x, yapprox2d, linestyle="dashed", linewidth=0.75)
plt.plot(x, yapprox3, linestyle="dashed", linewidth=0.75)
plt.legend(["$T(n,s)$", '$T_{upper}(n, s)$', '$f_1(n, s)$', '$f_2(n, s)$', '$T_{lower}(n, s)$'])
plt.show()