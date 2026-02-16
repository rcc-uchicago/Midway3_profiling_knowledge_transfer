from random import uniform
from random import random

def estimate_pi(n):
    return 4 * sum(hits(point()) for _ in range(n)) / n


def hits(point):
    return abs(point) <= 1


def point():
    return complex(uniform(0, 1), uniform(0, 1))
    # return complex(random(), random())

n = 10_000_000
pi_approx = estimate_pi(n)
print(f"{n = :<10,} {pi_approx = :.6f}")