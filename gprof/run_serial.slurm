#!/bin/bash
#SBATCH --job-name=gprof_serial
#SBATCH --output=gprof_serial_%j.out
#SBATCH --error=gprof_serial_%j.err
#SBATCH --partition=caslake   # Midway3 caslake partition (Intel Cascade Lake)
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH --mem=4G
#SBATCH --account=rcc-staff

#============================================================
# Slurm Job Script for Serial gprof Example on Midway3
#
# Caslake partition details:
#   - Intel Cascade Lake processors (198 nodes)
#   - Nodes: midway3-0001 to midway3-0002, 0008-0019, 0022-0038,
#            0047-0156, 0159-0199, 0201-0216
#   - For gprof profiling, GCC with -pg is recommended
#
# Partition options on Midway3:
#   - caslake  : Intel Cascade Lake (default, 198 nodes)
#   - amd      : AMD EPYC (40 nodes)
#   - amd-hm   : AMD high-memory (1 node)
#   - bigmem   : Large memory nodes (2 nodes)
#   - gpu      : GPU nodes (11 nodes)
#============================================================

echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Running on node: $SLURM_NODELIST"
echo "Partition: $SLURM_JOB_PARTITION (Intel Cascade Lake)"
echo "Start time: $(date)"
echo "=========================================="

# Load necessary modules for Midway3
module load gcc/12.2.0
# Other available GCC versions: 10.2.0  13.2.0  7.4.0  4.9.0

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
echo "Command: gcc -pg -O2 -march=x86-64 -mtune=skylake -o serial_example serial_example.c -lm"
gcc -pg -O2 -march=x86-64 -mtune=skylake -o serial_example serial_example.c -lm

# Note: -march=x86-64 -mtune=skylake provides Intel tuning
# Cascade Lake is based on Skylake microarchitecture
# For specific optimizations, you could use:
#   -march=skylake -mtune=skylake  (Skylake / Cascade Lake)
# However, -march=x86-64 is safer for portability

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
gprof -b serial_example gmon.out > gprof_serial_report.txt

echo ""
echo "=========================================="
echo "gprof report saved to: gprof_serial_report.txt"
echo "End time: $(date)"
echo "=========================================="

# Show top of the report
echo ""
echo "=== Top of Flat Profile ==="
head -30 gprof_serial_report.txt

echo ""
echo "Full report available in: gprof_serial_report.txt"
