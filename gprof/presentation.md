---
marp: true
theme: gaia
paginate: true
backgroundColor: #fff
header: 'gprof Profiling Tutorial for HPC'
footer: 'Midway3 @ UChicago RCC'
---

<!-- _class: lead -->

# Profiling HPC Codes with gprof
## An Introduction for CPU and MPI Applications

**Parmanand Sinha, Ph.D**
Computational Scientist, RCC

**University of Chicago**
Midway3 Cluster

---

## Outline

1. What is Profiling?
2. Why Profile Your Code?
3. Introduction to gprof
4. gprof Workflow
5. Serial Code Example
6. MPI Code Example
7. Analyzing gprof Output
8. Tips and Best Practices
9. Hands-on Exercise

---

## What is Profiling?

**Profiling** is a form of dynamic program analysis that measures:

- The frequency and duration of function calls
- CPU time spent in different parts of your code
- Call relationships between functions

### Types of Profiling

| Type | Description | Tools |
|------|-------------|-------|
| CPU Profiling | Time spent in functions | gprof, perf |
| Memory Profiling | Memory allocation/leaks | valgrind |
| I/O Profiling | Disk/network I/O | ioprof, strace |

---

## Why Profile Your Code?

1. **Identify Performance Bottlenecks**
   - Find where your code spends most of its time
   - The 80/20 rule: 80% of time in 20% of code

2. **Optimize Smartly**
   - Focus optimization efforts where they matter
   - Don't waste time optimizing fast functions

3. **Detect Unexpected Behavior**
   - Functions called more often than expected
   - Inefficient algorithms or data structures

4. **Compare Implementations**
   - Measure impact of code changes
   - A/B test different approaches

---

## Introduction to gprof

**gprof** (GNU Profiler) is a classic profiling tool included with GCC.

### Key Features
- Built into GCC/GNU compilers
- Profiles function-level execution time
- Shows call graph and caller/callee relationships
- Works with C, C++, Fortran
- Lightweight overhead

### Limitations
- Sampling-based profiling (statistical)
- Shows wall-clock time, not CPU cycles
- Cannot profile multi-threaded code accurately
- Requires special compilation flags

---

## gprof on HPC Systems

### Requirements
- GCC compiler with gprof support
- `-pg` flag during compilation and linking
- Single-threaded execution (for accurate results)

### When to Use gprof
- Serial CPU-bound applications
- Understanding function call patterns
- Quick performance assessment

### When NOT to Use gprof
- Multi-threaded codes (use `perf`)
- GPU codes (use NVIDIA profiler)
- Detailed micro-benchmarking (use `perf`)

---

## gprof Workflow

The typical workflow involves four steps:

1. **Compile** your code with `-pg`
2. **Run** your program to generate data
3. **Analyze** the output (`gmon.out`)
4. **Optimize** based on findings

```
┌─────────────┐       ┌─────────────┐
│ 1. Compile  │       │ 2. Run      │
│   with -pg  │──────>│   program   │
└──────┬──────┘       └──────┬──────┘
       │                     │
       v                     v
┌─────────────┐       ┌─────────────┐
│ 4. Optimize │<──────│ 3. Analyze  │
│   hotspots  │       │  gmon.out   │
└─────────────┘       └─────────────┘
```

---

## Step 1: Compilation

### Compile with Profiling Flags

```bash
# Serial code
gcc -pg -O2 -o myprogram myprogram.c

# MPI code (also needs -pg for linker)
mpicc -pg -O2 -o myprogram myprogram.c
```

### Key Points
- **`-pg`** flag must be used for **both** compilation and linking
- Optimization level (`-O2`, `-O3`) should be used to profile realistic performance
- The `-pg` flag instruments the code with profiling calls

---

## Step 2: Execution

### Run Your Program

On Midway3, submit using Slurm:

```bash
# Serial code
sbatch run_serial.slurm

# MPI code
sbatch run_mpi.slurm
```

### What Happens During Execution
- Each function entry/exit is recorded
- Sampling interrupt occurs (typically every 0.01s)
- Profile data is written to `gmon.out` upon successful exit

**Note for MPI:**
- Each rank produces its own `gmon.out` (may overwrite if sharing a directory)
- Proper setup requires separate directories or renaming

---

## Step 3: Analysis

### Generate Profile Report

```bash
# Basic flat profile
gprof myprogram gmon.out > profile.txt

# Detailed options
gprof -b myprogram gmon.out     # Brief output
gprof -p myprogram gmon.out     # Flat profile only
gprof -q myprogram gmon.out     # Call graph only
```

### For MPI Analysis
Analyze each rank separately:
```bash
gprof myprogram gmon.out.rank0 > profile_rank0.txt
```

---

## Understanding gprof Output: Flat Profile

Shows how much time was spent in each function.

```
  %   cumulative   self              self     total
 time   seconds   seconds    calls  Ts/call  Ts/call  name
 45.32      2.45     2.45   100000     0.00     0.00  compute_heavy
 30.15      4.08     1.63    10000     0.00     0.00  matrix_multiply
 15.20      4.90     0.82     1000     0.00     0.00  initialize_data
  9.33      5.40     0.50       10     0.05     5.40  main
```

**Key columns:**
- `% time`: Percentage of total time in this function
- `self`: Time spent in function itself (not children)
- `calls`: Number of times function was called

---

## Understanding gprof Output: Call Graph

Shows the caller-callee relationships.

```
index % time    self  children    calls       name
                0.50    4.90      10/10          main [1]
[1]    100.0    0.50    4.90      10         main [1]
                2.45    0.00  100000/100000      compute_heavy [2]
                1.63    0.00   10000/10000      matrix_multiply [3]
```

**Key information:**
- **Parent**: Functions calling this function
- **Child**: Functions called by this function
- **Total time**: Includes time spent in children

---

## Serial Code Example

### Matrix Computation with Hotspots

The provided `serial_example.c` computes:
1. Matrix initialization (Lightweight)
2. Matrix multiplication (Compute-intensive, $O(n^3)$)
3. Matrix addition (Moderate, $O(n^2)$)

This structure demonstrates clear performance differences between functions, making it ideal for learning how to identify hotspots.

---

## MPI Code Example

### Distributed Matrix Computation

Key considerations for MPI profiling with gprof:

1. **Single-rank execution**
   - Often sufficient for finding computational hotspots
2. **Analyze representative rank**
   - E.g., Rank 0 usually coordinates and computes
3. **Compare profiles**
   - Check for load imbalance by comparing Rank 0 vs Rank N

---

## MPI Profiling Workflow

1. **Compile with mpicc**:
   ```bash
   mpicc -pg -O2 -o mpi_example mpi_example.c
   ```

2. **Run with mpirun/srun**:
   - Ensure `gmon.out` isn't overwritten by multiple ranks
   - Often handled by running 1 rank or using specific flags/scripts to separate outputs

3. **Analyze specific rank**:
   ```bash
   gprof mpi_example gmon.out > analysis.txt
   ```

---

## Tips and Best Practices

### 1. Compile with Optimization
- **Good:** `gcc -pg -O2 ...` (Profile realistic performance)
- **Bad:** `gcc -pg -O0 ...` (Unoptimized code skews results)

### 2. Run with Representative Data
- Use realistic input sizes
- Run long enough for meaningful samples (> 1 second)

### 3. Clean Profile Data
- Remove old `gmon.out` before running: `rm -f gmon.out`

### 4. Multiple Runs
- Run multiple times to ensure consistency

---

## Common Pitfalls

| Problem | Cause | Solution |
|---------|-------|----------|
| **No gmon.out** | Forgot `-pg` flag | Recompile with `-pg` |
| **Empty profile** | Run too short | Run longer / reduce sampling |
| **Confusing data** | Multi-threaded | Profile single-threaded |
| **MPI issues** | Overwritten output | Rename per-rank files |
| **Slow execution** | `-pg` overhead | Accept it or use `perf` |

---

## Hands-on Exercise

### Objective
Profile a matrix computation code, identify the hotspot, and optimize it.

### Steps
1. **Compile** the serial example with gprof
   ```bash
   gcc -pg -O2 -o serial_example serial_example.c -lm
   ```
2. **Run** it via Slurm
   ```bash
   sbatch run_serial.slurm
   ```
3. **Analyze** the output
   ```bash
   gprof serial_example gmon.out > report.txt
   ```
4. **Answer** questions in `exercise.md`

---

## Summary

1. **gprof** is a simple, effective profiler for serial codes
2. **Compilation** requires `-pg` flag for both compile and link
3. **Execution** generates `gmon.out` for analysis
4. **Analysis** identifies hotspots for optimization
5. **MPI** requires careful handling of output files

### Next Steps
- Try the hands-on examples
- Profile your own codes
- Explore advanced tools (`perf`, `VTune`)

---

<!-- _class: lead -->

# Questions?

**Parmanand Sinha, Ph.D**
Computational Scientist, RCC

**Additional Resources:**
- `man gprof`
- GCC Documentation

