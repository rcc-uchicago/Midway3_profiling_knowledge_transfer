#!/bin/bash
#SBATCH --job-name=mandel
#SBATCH --output=mandelbrot_par_%j.out
#SBATCH --error=mandelbrot_par_%j.err
#SBATCH --account=rcc-staff
#SBATCH --time=06:00:00
#SBATCH --partition=caslake
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8 #48
##SBATCH --cpus-per-task=1

#module load python
#for n in {1..3}; do time python word_manifold.py english.txt 10 100 $n; done

#time ./a.out
# When running a large number of tasks simultaneously, it may be
# necessary to increase the user process limit.
ulimit -l unlimited
time mpirun -n 8 ./a.out
