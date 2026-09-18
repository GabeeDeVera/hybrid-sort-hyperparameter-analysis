import pandas

def trisum(n):
    return (n * (n + 1)) >> 1

def get_com(l):
    vol = 0
    ysum = 0

    for (low, hi) in l:
        vol += hi - low + 1
        ysum += trisum(hi) - trisum(low - 1)

    return ysum / vol

data = pandas.read_csv("../data/performance_data.csv")

nvals = [10**i for i in range(3, 8)]

RATIO_THRESH = 0.01

opts = []

for n in nvals:
    df = data.query(f"n == {n}")

    mtime = min(df['time_ms'])

    closemin = df.query(f"abs(time_ms - {mtime}) / {mtime} <= {RATIO_THRESH}")

    opts.append((n, (min(closemin['s']), max(closemin['s']))))

print(opts)

print(get_com(list(map(lambda x: x[1], opts))))