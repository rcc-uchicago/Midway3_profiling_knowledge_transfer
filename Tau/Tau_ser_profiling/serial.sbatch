#!/bin/bash
#SBATCH --job-name=mandel
#SBATCH --output=mandelbrot_ser_%j.out
#SBATCH --error=mandelbrot_ser_%j.err
#SBATCH --account=rcc-staff
#SBATCH --time=01:00:00
#SBATCH --partition=caslake
##SBATCH --nodes=1
#SBATCH --ntasks-per-node=1 #48
#SBATCH --cpus-per-task=1

module load tau/2.31
rm a.out *.o tau_cxx.sh 
cp $TAU_HOME/bin/tau_cxx.sh .
export CC=tau_cc.sh CXX=tau_cxx.sh F90=tau_f90.sh
export TAU_MAKEFILE=/software/tau-2.31-el8-x86_64/lib/Makefile.tau-mpi-pdt-openmp 
tau_cxx.sh -std=c++98 mandelbrot-serial-v2.cc

time ./a.out
