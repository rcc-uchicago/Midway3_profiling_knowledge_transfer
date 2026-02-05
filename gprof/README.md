# gprof Profiling Tutorial for HPC

Complete materials for a 30-minute introductory presentation on profiling CPU/MPI codes with gprof on HPC clusters using Slurm.

**Configured for: Midway3 at University of Chicago RCC**

## Overview

This tutorial covers:
- What is profiling and why it's important
- Introduction to gprof (GNU Profiler)
- Step-by-step workflow for profiling serial and MPI codes
- Analyzing and interpreting gprof output
- Hands-on exercises

## Files Included

| File | Description |
|------|-------------|
| `presentation.md` | Presentation slides in markdown format |
| `serial_example.c` | Serial CPU code example for profiling |
| `mpi_example.c` | MPI code example for profiling |
| `run_serial.slurm` | Slurm job script for **caslake** partition |
| `run_serial_amd.slurm` | Slurm job script for **amd** partition |
| `run_mpi.slurm` | Slurm job script for MPI on **caslake** partition |
| `exercise.md` | Hands-on exercise worksheet |
| `README.md` | This file - setup and instructions |

---

## Midway3 Configuration

### Available Partitions

| Partition | Description | Nodes | Best For |
|-----------|-------------|-------|----------|
| `caslake` | Intel Cascade Lake (default) | 198 | General CPU workloads |
| `amd` | AMD EPYC | 40 | CPU-intensive workloads |
| `amd-hm` | AMD high-memory | 1 | Large memory jobs |
| `bigmem` | Large memory nodes | 2 | Memory-intensive codes |
| `gpu` | GPU nodes | 11 | GPU acceleration |

### Available Modules (Midway3)

```bash
# GCC versions
module avail gcc
# gcc/4.9.0  gcc/7.4.0  gcc/10.2.0(default)  gcc/12.2.0  gcc/13.2.0

# OpenMPI versions
module avail openmpi
# openmpi/4.1.8(default)  openmpi/5.0.2  openmpi/5.0.2+gcc-12.2.0

# Clang/LLVM (available but does NOT support -pg for gprof)
module load clang/13.0.0
# Note: Clang uses LLVM's own profiling tools, not gprof
```

### Compiler Recommendations

| Partition | Recommended for gprof | Alternative | Notes |
|-----------|---------------------|-------------|-------|
| `caslake` | GCC 12.2.0 with `-pg` | Intel ICC | GCC works well |
| `amd` | GCC 12.2.0 with `-pg` | Clang/LLVM* | Clang does NOT support `-pg` |

*Clang/LLVM is available on Midway3 but uses a different profiling system (LLVM profiler).
For gprof specifically, use GCC on both caslake and amd partitions.

---

## Prerequisites

### System Requirements
- Midway3 cluster at UChicago RCC
- Slurm workload manager
- Environment Module System
- GCC compiler with gprof support
- OpenMPI library (for MPI example)

### Required Modules

```bash
# For caslake partition (Intel)
module load gcc/12.2.0
module load openmpi/4.1.8

# For amd partition (AMD EPYC)
module load gcc/12.2.0
# Note: AOCC (AMD Optimizing Compiler) is available on Midway3 (aocc/3.1.0 and aocc/4.1.0)
# You can use it on AMD nodes
```

---

## Quick Start: Serial Code

### Option 1: Caslake Partition (Intel Xeon)

```bash
# Compile
module load gcc/12.2.0
gcc -pg -O2 -o serial_example serial_example.c -lm

# Run via Slurm
sbatch run_serial.slurm

# Check output
cat gprof_serial_*.out
cat gprof_serial_report.txt
```

### Option 2: AMD Partition (AMD EPYC)

```bash
# Compile with GCC
module load gcc/12.2.0
gcc -pg -O2 -o serial_example serial_example.c -lm

# Run via Slurm
sbatch run_serial_amd.slurm

# Check output
cat gprof_serial_amd_*.out
cat gprof_serial_amd_report.txt
```

### Run Interactively (for testing)

```bash
# Allocate a node
salloc -N1 --ntasks=1 --partition=caslake --time=00:10:00

# Load modules
module load gcc/12.2.0

# Compile and run
gcc -pg -O2 -o serial_example serial_example.c -lm
rm -f gmon.out
./serial_example 500

# Analyze
gprof -b serial_example gmon.out | less
```

---

## Quick Start: MPI Code

### Compile and Run on Caslake

```bash
# Compile
module load gcc/12.2.0 openmpi/4.1.8
mpicc -pg -O2 -o mpi_example mpi_example.c -lm

# Run via Slurm (single rank recommended for gprof)
sbatch run_mpi.slurm

# Or run with single rank via salloc
salloc -N1 --ntasks=1 --partition=caslake --time=00:10:00
srun -n1 ./mpi_example 500
gprof mpi_example gmon.out > profile_mpi.txt
```

### For AMD Partition

```bash
# Use GCC with AMD tuning flags
module load gcc/12.2.0
mpicc -pg -O2 -march=x86-64 -mtune=znver2 -o mpi_example mpi_example.c -lm

# Modify run_mpi.slurm: change partition to "amd"
# Then submit
sbatch run_mpi.slurm
```

**Note:** AOCC (AMD Optimizing C/C++ Compiler) is available on Midway3 (aocc/3.1.0 and aocc/4.1.0) on AMD nodes.

---

## gprof Workflow Summary

```
1. Compile with -pg flag
   gcc -pg -O2 -o program program.c

2. Run program to generate gmon.out
   ./program [args]

3. Analyze with gprof
   gprof program gmon.out > report.txt

4. Read the report
   less report.txt
```

---

## Understanding gprof Output

### Flat Profile Section

Shows the time spent in each function:

```
Flat profile:

Each sample counts as 0.01 seconds.
  %   cumulative   self              self     total
 time   seconds   seconds    calls  Ts/call  Ts/call  name
 45.32      2.45     2.45   100000     0.00     0.00  compute_heavy
 30.15      4.08     1.63    10000     0.00     0.00  matrix_multiply
```

**Key columns:**
- `% time` - Percentage of total execution time
- `self seconds` - Time in this function only
- `calls` - Number of times called
- `name` - Function name

### Call Graph Section

Shows caller/callee relationships:

```
index % time    self  children    calls  name
      45.32    2.45     0.00  100000/100000      compute_heavy
```

**Key information:**
- Which functions call this function
- Which functions are called by this function
- Time including children (total time)

---

## Tips and Best Practices

### Do's
- Use `-O2` or `-O3` optimization for realistic profiling
- Run with representative input sizes
- Run multiple times to check consistency
- Profile single-threaded for accurate results
- Use appropriate partition for your workload

### Don'ts
- Don't profile multi-threaded codes with gprof (use perf instead)
- Don't profile very short runs (< 0.1 seconds)
- Don't forget `-pg` on both compile AND link
- Don't profile with `-O0` (unoptimized) for production insights

### Midway3 Specific Tips
- Use `caslake` for most workloads (default, good availability)
- Use `amd` for CPU-intensive codes (may show different performance characteristics)
- Use `amd-hm` or `bigmem` for memory-intensive profiling
- For AMD partition: Use GCC with `-mtune=znver2` for AMD EPYC optimization
- For caslake partition: Use GCC with `-mtune=skylake` for Cascade Lake optimization
- Clang is available but does NOT support `-pg` flag (use LLVM profiler instead)

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| No `gmon.out` file | Recompile with `-pg` on both compile and link |
| Empty profile | Run longer; program too fast for samples |
| Confusing results | Use optimization (`-O2`) |
| Segmentation fault | May be unrelated; test without `-pg` |
| MPI: only one gmon.out | Normal; rename per-rank or use single-rank |
| Job pending | Check partition status: `sinfo -p caslake` |
| Module not found | Use `module spider gcc` to find available versions |

---

## Advanced: Converting Presentation to Slides

The `presentation.md` file can be converted to slides using:

### Option 1: Pandoc (Reveal.js)
```bash
module load pandoc  # if available on Midway3
pandoc -t revealjs -s presentation.md -o presentation.html
```

### Option 2: Pandoc (PDF)
```bash
pandoc presentation.md -o presentation.pdf
```

### Option 3: Present directly with terminal tools
```bash
# Using less for basic viewing
less presentation.md

# Or use cat with paging
cat presentation.md | less
```

---

## Comparing Caslake vs AMD Performance

To compare performance between Intel and AMD nodes:

```bash
# Run on caslake
sbatch run_serial.slurm
# Results in: gprof_serial_report.txt

# Run on amd
sbatch run_serial_amd.slurm
# Results in: gprof_serial_amd_report.txt

# Compare the flat profiles
diff gprof_serial_report.txt gprof_serial_amd_report.txt
```

---

## Additional Resources

### Documentation
- `man gprof` - gprof manual page
- `info gprof` - Detailed gprof documentation
- [GCC Profiling Options](https://gcc.gnu.org/onlinedocs/gcc/Debugging-Options.html)
- [RCC User Guide - Partitions](https://docs.rcc.uchicago.edu/partitions/)
- [RCC User Guide - Software](https://docs.rcc.uchicago.edu/software/)

### Alternative Profiling Tools
- `perf` - Linux profiling with hardware counters
- `Intel VTune` - Advanced CPU profiling
- `HPCToolkit` - HPC profiling toolkit
- `mpiP` - MPI profiling
- `scalasca` - Scalable performance analysis

### On Midway3
Check available profiling tools:
```bash
module avail profiler
module avail vtune
module avail perftools
```

---

## Presentation Tips (for Presenters)

### 30-Minute Timeline

| Time | Content |
|------|---------|
| 0-5 min | Introduction: What/Why profiling |
| 5-10 min | gprof overview and workflow |
| 10-15 min | Serial code walkthrough + compilation demo |
| 15-20 min | Output analysis + interpretation |
| 20-25 min | MPI considerations + hands-on start |
| 25-30 min | Q&A + next steps |

### Demo Preparation

Before the presentation:
1. Compile both examples on Midway3
2. Run serial example on caslake to confirm it works
3. Prepare sample output for display if live demo fails
4. Check partition availability: `sinfo -p caslake,amd`
5. Have backup plain-text versions of key diagrams

### Live Demo Commands

```bash
# Terminal 1: Watch job status
watch -n 5 squeue -u $USER

# Terminal 2: Submit and monitor
sbatch run_serial.slurm
tail -f gprof_serial_*.out

# Terminal 3: Show results when ready
cat gprof_serial_report.txt | head -50
```

---

## License

These materials are provided for educational purposes. Feel free to modify and adapt for your HPC training needs.

---

## Contact

**Parmanand Sinha, Ph.D**
Computational Scientist, RCC

For questions or feedback about these materials:
- **RCC Help**: help@rcc.uchicago.edu
- **RCC Documentation**: https://docs.rcc.uchicago.edu/

---

## Sources

- [Partitions - RCC User Guide](https://docs.rcc.uchicago.edu/partitions/)
- [Calculations of Service Units - Research Computing Center](https://rcc.uchicago.edu/accounts-allocations/calculations-service-units)
- [Software packages and compilers - RCC User Guide](https://docs.rcc.uchicago.edu/software/)
- [Ecosystems - RCC User Guide](https://docs.rcc.uchicago.edu/101/ecosystems/)
