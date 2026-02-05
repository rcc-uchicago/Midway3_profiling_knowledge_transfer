#!/bin/bash
#SBATCH --job-name=gprof_serial_amd
#SBATCH --output=gprof_serial_amd_%j.out
#SBATCH --error=gprof_serial_amd_%j.err
#SBATCH --partition=amd          # Midway3 AMD EPYC partition
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH --mem=4G
#SBATCH --account=rcc-staff

#============================================================
# Slurm Job Script for Serial gprof Example on Midway3 AMD
#
# AMD partition notes:
#   - AMD EPYC processors (40 nodes: midway3-0501 to midway3-0539, 0549)
#   - For gprof profiling, GCC with -pg is recommended
#   - Clang/LLVM is available but does NOT fully support -pg for gprof
#   - AOCC (AMD Optimizing C/C++ Compiler) is available on Midway3 amd partitions (aocc/3.1.0 and 4.1.0)
#
# Compiler options for AMD partition:
#   1. GCC with -pg (recommended for gprof)
#   2. Clang with -fprofile-instr-generate (uses LLVM profiler, not gprof)
#============================================================

echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Running on node: $SLURM_NODELIST"
echo "Partition: $SLURM_JOB_PARTITION (AMD EPYC)"
echo "Start time: $(date)"
echo "=========================================="

# Load necessary modules for Midway3 AMD partition
# Option 1: Use GCC (recommended for gprof profiling)
module load gcc/12.2.0
# Other available GCC versions: 10.2.0  13.2.0  7.4.0  4.9.0

# Option 2: Use Clang (NOT recommended for gprof - use LLVM profiler instead)
# module load clang/13.0.0
# Note: Clang does not support -pg flag. Use LLVM's profiling:
#   clang -fprofile-instr-generate -fcoverage-mapping program.c
#   LLVM_PROFDATA=program.profdata ./program
#   llvm-profdata merge default.profraw -o program.profdata
#   llvm-cov report program

# Set environment variables
export OMP_NUM_THREADS=1

# Show compiler and system info
echo ""
echo "=== System Information ==="
echo "Compiler: $(gcc --version | head -1)"
echo "Host: $(hostname)"
echo "CPU Info: $(lscpu | grep 'Model name' | head -1)"
echo "CPU cores: $(nproc)"
echo "Memory: $(free -h | grep Mem | awk '{print $2}')"

# Compilation
echo ""
echo "=== Compiling with gprof flags ==="
echo "Command: gcc -pg -O2 -o serial_example serial_example.c -lm"
gcc -pg -O2 -march=x86-64 -mtune=znver2 -o serial_example serial_example.c -lm

# Note: -march=x86-64 -mtune=znver2 provides generic AMD EPYC tuning
# For specific AMD optimizations, you could use:
#   -march=znver2 -mtune=znver2  (Zen 2 / EPYC 7002)
# However, -march=x86-64 is safer for portability across nodes

if [ $? -ne 0 ]; then
    echo "ERROR: Compilation failed"
    exit 1
fi

echo "Compilation successful"

# Remove any existing gmon.out
echo ""
echo "=== Cleaning old profile data ==="
rm -f gmon.out

# Run the program
echo ""
echo "=== Running program ==="
echo "Matrix size: 500 (default)"
echo ""

./serial_example 500

# Check if gmon.out was created
if [ ! -f gmon.out ]; then
    echo ""
    echo "ERROR: gmon.out was not created!"
    echo "Check that the program was compiled with -pg flag"
    exit 1
fi

# Generate profile report
echo ""
echo "=== Generating gprof report ==="
gprof -b serial_example gmon.out > gprof_serial_amd_report.txt

echo ""
echo "=========================================="
echo "gprof report saved to: gprof_serial_amd_report.txt"
echo "End time: $(date)"
echo "=========================================="

# Show top of the report
echo ""
echo "=== Top of Flat Profile ==="
head -30 gprof_serial_amd_report.txt

echo ""
echo "Full report available in: gprof_serial_amd_report.txt"
echo ""
echo "=== Performance Comparison Tips ==="
echo "To compare Intel vs AMD performance:"
echo "  - Run this script on amd partition (this script)"
echo "  - Run run_serial.slurm on caslake partition"
echo "  - Compare the gprof reports"
echo ""
echo "Note on compiler flags:"
echo "  - This script uses: gcc -pg -O2 -march=x86-64 -mtune=znver2"
echo "  - For caslake:        gcc -pg -O2 -march=x86-64 -mtune=skylake"
echo ""
echo "For more advanced profiling on AMD:"
echo "  - Use perf: perf record ./program && perf report"
echo "  - Use AMD uProf (if installed)"
