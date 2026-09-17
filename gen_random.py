from random import randint

# largest integer possible in data set
x = 10**18

def gen_random_list(n):
    return list(map(lambda _: randint(1, x), range(n)))