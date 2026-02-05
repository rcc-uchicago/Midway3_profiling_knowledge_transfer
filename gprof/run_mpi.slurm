#!/bin/bash
#SBATCH --job-name=gprof_mpi
#SBATCH --output=gprof_mpi_%j.out
#SBATCH --error=gprof_mpi_%j.err
#SBATCH --partition=caslake   # Midway3 caslake partition (Intel Xeon)
#SBATCH --nodes=1
#SBATCH --ntasks=4            # Number of MPI ranks
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH --mem=8G
#SBATCH --account=rcc-staff

#============================================================
# Slurm Job Script for MPI gprof Example on Midway3
#
# Partition options on Midway3:
#   - caslake  : Intel Cascade Lake (default, 198 nodes)
#   - amd      : AMD EPYC (40 nodes) - use AMD-optimized builds
#   - amd-hm   : AMD high-memory (1 node)
#   - bigmem   : Large memory nodes (2 nodes)
#============================================================

echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Running on node: $SLURM_NODELIST"
echo "Partition: $SLURM_JOB_PARTITION"
echo "Number of MPI ranks: $SLURM_NTASKS"
echo "Start time: $(date)"
echo "=========================================="

# Load necessary modules for Midway3
module load gcc/12.2.0            # GCC 12.2.0 on Midway3
module load openmpi/4.1.8         # OpenMPI 4.1.8 (default on Midway3)
# Alternative: module load gcc/12.2.0 && module load openmpi/5.0.2+gcc-12.2.0

# Set environment variables
export OMP_NUM_THREADS=1

# Compilation
echo ""
echo "=== Compiling MPI program with gprof flags ==="
echo "Compiler: $(gcc --version | head -1)"
echo "MPI: $(mpicc --version | head -1)"
mpicc -pg -O2 -o mpi_example mpi_example.c -lm

if [ $? -ne 0 ]; then
    echo "ERROR: Compilation failed"
    exit 1
fi

echo "Compilation successful"

# Remove any existing gmon.out files
echo ""
echo "=== Cleaning old profile data ==="
rm -f gmon.out gmon.out.rank*

# Run the MPI program
echo ""
echo "=== Running MPI program ==="
echo "Matrix size: 500 (default)"
echo "Number of ranks: $SLURM_NTASKS"
echo ""

srun ./mpi_example 500

# Generate profile reports for each rank
echo ""
echo "=== Analyzing profile data ==="

# For MPI profiling with gprof, we need to handle multiple gmon.out files
# Note: When running with multiple ranks, only the last rank's gmon.out
# will exist in the current directory. For comprehensive profiling:
# 1. Run with a single rank for accurate gprof results
# 2. Or instrument code to save per-rank gmon.out

if [ -f gmon.out ]; then
    echo "Found gmon.out (likely from last rank)"
    echo "Generating profile report..."
    gprof -b mpi_example gmon.out > gprof_mpi_report.txt

    echo ""
    echo "=========================================="
    echo "gprof report saved to: gprof_mpi_report.txt"
    echo "End time: $(date)"
    echo "=========================================="

    # Show top of the report
    echo ""
    echo "=== Top of Flat Profile ==="
    head -30 gprof_mpi_report.txt

    echo ""
    echo "Full report available in: gprof_mpi_report.txt"
else
    echo ""
    echo "ERROR: gmon.out was not created!"
    echo "Check that the program was compiled with -pg flag"
fi

# Recommendations for MPI profiling
echo ""
echo "=========================================="
echo "Recommendations for MPI profiling with gprof:"
echo "=========================================="
echo ""
echo "1. For accurate single-rank profiling:"
echo "   sbatch --export=ALL#SBATCH --ntasks=1 run_mpi.slurm"
echo "   # or modify ntasks above and resubmit"
echo "   gprof mpi_example gmon.out > profile_single_rank.txt"
echo ""
echo "2. For AMD partition, use GCC with AMD tuning flags:"
echo "   module load gcc/12.2.0"
echo "   mpicc -pg -O2 -march=x86-64 -mtune=znver2 -o mpi_example mpi_example.c -lm"
echo "   Note: AOCC (AMD Optimizing Compiler) is NOT available on Midway3"
echo ""
echo "3. For per-rank profiling, modify code to rename gmon.out:"
echo "   Add at end of mpi_example.c main():"
echo "   char newname[256];"
echo "   sprintf(newname, \"gmon.out.rank%d\", rank);"
echo "   rename(\"gmon.out\", newname);"
echo ""
echo "4. For MPI communication profiling, consider:"
echo "   - mpiP (MPI profiling)"
echo "   - Intel Trace Analyzer"
echo "   - HPCToolkit"
echo "=========================================="
