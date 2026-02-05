#!/bin/bash
#SBATCH --job-name=mandel
#SBATCH --output=mandelbrot_ser_%j.out
#SBATCH --error=mandelbrot_ser_%j.err
#SBATCH --account=rcc-staff
#SBATCH --time=06:00:00
#SBATCH --partition=caslake
##SBATCH --nodes=1
#SBATCH --ntasks-per-node=1 #48
#SBATCH --cpus-per-task=1

#module load python
#for n in {1..3}; do time python word_manifold.py english.txt 10 100 $n; done

time ./a.out
