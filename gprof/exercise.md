# gprof Hands-on Exercise

## Objective

In this exercise, you will:
1. Compile a program with gprof instrumentation
2. Run it via Slurm on an HPC cluster
3. Analyze the profiling output
4. Identify performance hotspots
5. Answer analysis questions

---

## Exercise 1: Serial Code Profiling

### Step 1: Compile the Program

First, let's compile the serial example with gprof flags:

```bash
module load gcc/12.2.0  

# Compile with profiling enabled
gcc -pg -O2 -o serial_example serial_example.c -lm
```

**Question 1:** What does the `-pg` flag do?

### Step 2: Submit the Job

Submit the serial job to Slurm:

```bash
sbatch run_serial.slurm
```

Monitor your job:

```bash
squeue -u $USER
```

### Step 3: Check the Output

Once the job completes, check the output:

```bash
# View job output
cat gprof_serial_*.out

# View the profiling report
cat gprof_serial_report.txt
```

---

## Exercise 2: Analyzing gprof Output

### Flat Profile Analysis

Look at the "Flat profile" section in your report. Answer these questions:

**Question 2:** Which function consumes the most percentage of time?

```
Look for the function with the highest % time value
```

**Question 3:** How many times was `matrix_multiply` called?

```
Look at the 'calls' column for matrix_multiply
```

**Question 4:** Which function has the most calls? Is this expected?

```
Hint: Look for functions with high call counts but low time per call
```

**Question 5:** What is the "self time" vs "total time" for the main function?

```
- self time: Time spent in main() itself
- total time: Time including all functions called by main()
```

### Call Graph Analysis

Look at the "Call graph" section:

**Question 6:** Which function does `main()` call the most frequently?

**Question 7:** Which child function of `main()` consumes the most time?

---

## Exercise 3: Optimization Challenge

### Current State

Based on your profiling, identify:

1. **Primary hotspot:** The function using the most CPU time
2. **Secondary hotspots:** Other significant time consumers
3. **Quick wins:** Any functions called frequently but quick to execute

### Question 8: Optimization Strategy

If you could optimize ONE function to improve overall performance, which would it be and why?

```
Consider:
- Which function has the highest self time?
- What is the function's algorithmic complexity?
- Is it practical to optimize?
```

---

## Exercise 4: Comparing Different Matrix Sizes

Let's see how profiling changes with different problem sizes:

### Step 1: Modify and Re-run

Edit `run_serial.slurm` to change the matrix size:

```bash
# Change this line in the script:
./serial_example 500  # Try 250, 500, 1000
```

Or compile and run different sizes:

```bash
# Small matrix
./serial_example 250
mv gmon.out gmon.out.250
gprof serial_example gmon.out.250 > profile_250.txt

# Large matrix
./serial_example 1000
mv gmon.out gmon.out.1000
gprof serial_example gmon.out.1000 > profile_1000.txt
```

### Question 9: Scaling Behavior

Compare the percentage of time spent in `matrix_multiply` for different matrix sizes.

Does the percentage increase, decrease, or stay the same? Why?

```
Hint: Consider O(n^3) vs O(n^2) operations
```

---

## Exercise 5: MPI Profiling (Optional/Advanced)

### Step 1: Compile MPI Example

```bash
module load gcc/12.2.0 openmpi/4.1.5  # Adjust versions

mpicc -pg -O2 -o mpi_example mpi_example.c -lm
```

### Step 2: Run with Single Rank

For accurate gprof profiling, run with a single MPI rank:

```bash
srun -n1 ./mpi_example 500
gprof mpi_example gmon.out > profile_mpi_single.txt
```

**Question 10:** How does the MPI single-rank profile compare to the serial profile?

### Step 3: Run with Multiple Ranks

```bash
sbatch run_mpi.slurm
```

**Question 11:** What challenges do you encounter when profiling MPI codes with gprof?

---

## Exercise 6: Modifying the Code

### Task: Add a New Function

Add a new function to `serial_example.c`:

```c
void slow_function(int n) {
    /* Add some computation here */
    volatile double sum = 0;
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < 10000; j++) {
            sum += sqrt(i * j);
        }
    }
}
```

Call it from `main()` and profile again.

**Question 12:** Where does `slow_function` appear in the profile?

---

## Bonus Questions

1. **What happens if you compile with `-O0` instead of `-O2`?**
   - Try it and compare the profiles

2. **Can gprof detect I/O bottlenecks?**
   - What if the program spends time waiting for file I/O?

3. **What is the minimum runtime needed for meaningful gprof data?**
   - Try running with very small matrices

4. **How would you profile a multi-threaded OpenMP code?**
   - Hint: gprof is not recommended for this. Why?

---

## Summary Checklist

By the end of this exercise, you should be able to:

- [ ] Compile code with gprof instrumentation (`-pg` flag)
- [ ] Submit profiling jobs via Slurm
- [ ] Interpret flat profile output
- [ ] Interpret call graph output
- [ ] Identify performance hotspots
- [ ] Compare profiles across different inputs
- [ ] Understand limitations of gprof (especially for MPI)

---

## Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| No `gmon.out` file | Ensure `-pg` was used for BOTH compile and link |
| Empty profile | Run longer; program may be too fast |
| Confusing results | Make sure using `-O2` optimization |
| MPI profiling issues | Use single rank or per-rank gmon.out files |

---

## Further Reading

- `man gprof` - Full gprof manual
- `info gprof` - Detailed gprof documentation
- GCC Profiling: https://gcc.gnu.org/onlinedocs/gcc/Debugging-Options.html

---

## Solutions (for instructors)

### Solution 1
The `-pg` flag adds profiling instrumentation to the code.

### Solution 2-7
Answers depend on actual profile output. Generally:
- `matrix_multiply` should be the primary hotspot
- `busy_wait_function` should also appear
- `lightweight_function` may have many calls but low time

### Solution 8
Optimize `matrix_multiply` (O(n^3) complexity dominates).

### Solution 9
As matrix size increases, `matrix_multiply` percentage should increase
because it's O(n^3) while other operations are O(n^2).

### Solution 10-11
MPI profiling with gprof is challenging due to:
- Overwritten gmon.out files
- Need to profile per-rank
- gprof not designed for parallel execution

### Solution 12
`slow_function` should appear with its self time and call count
proportional to how many times it was called.
