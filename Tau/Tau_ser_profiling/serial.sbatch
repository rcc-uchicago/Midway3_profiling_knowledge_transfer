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
module load tau/2.31
rm a.out *.o tau_cxx.sh 
cp $TAU_HOME/bin/tau_cxx.sh .
export CC=tau_cc.sh CXX=tau_cxx.sh F90=tau_f90.sh
export TAU_MAKEFILE=/software/tau-2.31-el8-x86_64/lib/Makefile.tau-mpi-pdt-openmp rm *.o
tau_cxx.sh mandelbrot-serial.cc


time ./a.out
