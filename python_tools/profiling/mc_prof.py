# Use pyinstrument to profile the estimate_pi function
from pyinstrument import Profiler

with Profiler(interval=0.1) as profiler:
    estimate_pi(n=10_000_000)


profiler.print()

profiler.open_in_browser()
