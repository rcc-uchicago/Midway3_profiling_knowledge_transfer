This folder contains the steps to build an MPI code with OpenMPI and use Intel VTune to profile the application

1) Compile the MPI code with OpenMPI and GNU gcc, using -g for debugging info and -O2 optimization
```
module load openmpi/4.1.2+gcc-10.2.0
mpicxx -g -O2 -lm -o test_mpi mandelbrot-mpi_final_v2.cc
```

2) Request an interactive job
```
sinteractive  --ntasks-per-node=8
```

3) On the compute node, load the same OpenMPI module
```
module load openmpi/4.1.2+gcc-10.2.0

# not to load the oneapi module to avoid conflict with the MPI module (openmpi)
VTUNE='/software/intel/oneapi_hpc_2024.2/vtune/latest/bin64/vtune'

ulimit -l unlimited

mpirun -np 4 $VTUNE -collect hotspots -r output_dir_n4 ./test_mpi
mpirun -np 8 $VTUNE -collect hotspots -r output_dir_n8 ./test_mpi
```

4) On the login node, or on the compute node, visualize the profiling output
```
/software/intel/oneapi_hpc_2024.2/vtune/latest/bin64/vtune-gui output_dir_n4/
```

