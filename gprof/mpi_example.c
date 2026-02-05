/*
 * MPI Matrix Computation Example for gprof Demonstration
 *
 * This program demonstrates profiling MPI codes with gprof.
 * Each rank computes a portion of a distributed matrix operation.
 *
 * IMPORTANT: For accurate gprof profiling with MPI:
 * 1. Rename gmon.out after each run (per rank)
 * 2. Profile with a single rank for accurate results
 * 3. Or analyze a representative rank (e.g., rank 0)
 *
 * Usage: srun -n4 ./mpi_example [matrix_size]
 * Default matrix size: 500
 *
 * Compilation: mpicc -pg -O2 -o mpi_example mpi_example.c -lm
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <mpi.h>

/* Function prototypes */
void compute_local_chunk(int rank, int size, int global_n, int* local_start, int* local_end);
double** allocate_matrix_local(int rows, int cols);
void free_matrix_local(double** matrix, int rows);
void initialize_matrix_local(double** matrix, int rows, int cols, double value);
void matrix_multiply_local(double** A, double** B, double** C, int rows, int n);
void matrix_add_local(double** A, double** B, double** C, int rows, int cols);
double compute_local_norm(double** A, int rows, int cols);
void busy_wait_compute(int iterations);

/*
 * Determine which rows this rank handles
 */
void compute_local_chunk(int rank, int size, int global_n, int* local_start, int* local_end)
{
    int rows_per_rank = global_n / size;
    int remainder = global_n % size;

    *local_start = rank * rows_per_rank + (rank < remainder ? rank : remainder);
    *local_end = *local_start + rows_per_rank + (rank < remainder ? 1 : 0);
}

/*
 * Allocate a local portion of a matrix
 */
double** allocate_matrix_local(int rows, int cols)
{
    double** matrix = (double**)malloc(rows * sizeof(double*));
    if (matrix == NULL) {
        fprintf(stderr, "Memory allocation failed\n");
        exit(1);
    }

    for (int i = 0; i < rows; i++) {
        matrix[i] = (double*)malloc(cols * sizeof(double));
        if (matrix[i] == NULL) {
            fprintf(stderr, "Memory allocation failed\n");
            exit(1);
        }
    }

    return matrix;
}

/*
 * Free a local matrix
 */
void free_matrix_local(double** matrix, int rows)
{
    for (int i = 0; i < rows; i++) {
        free(matrix[i]);
    }
    free(matrix);
}

/*
 * Initialize local matrix with a value
 */
void initialize_matrix_local(double** matrix, int rows, int cols, double value)
{
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            matrix[i][j] = value;
        }
    }
}

/*
 * Local matrix multiplication: C_local = A_local * B
 * - COMPUTE INTENSIVE operation (HOTSPOT)
 * - Each rank computes its portion of rows
 */
void matrix_multiply_local(double** A, double** B, double** C, int rows, int n)
{
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < n; j++) {
            C[i][j] = 0.0;
            for (int k = 0; k < n; k++) {
                C[i][j] += A[i][k] * B[k][j];
            }
        }
    }
}

/*
 * Local matrix addition: C = A + B
 * - MODERATE operation
 */
void matrix_add_local(double** A, double** B, double** C, int rows, int cols)
{
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            C[i][j] = A[i][j] + B[i][j];
        }
    }
}

/*
 * Compute local Frobenius norm contribution
 */
double compute_local_norm(double** A, int rows, int cols)
{
    double sum = 0.0;
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            sum += A[i][j] * A[i][j];
        }
    }
    return sum;
}

/*
 * Artificial computational work
 * - HOTSPOT demonstration
 */
void busy_wait_compute(int iterations)
{
    volatile double result = 0.0;
    for (int i = 0; i < iterations; i++) {
        for (int j = 0; j < 1000; j++) {
            result += i * j * 0.001;
        }
    }
}

/*
 * Main function
 */
int main(int argc, char* argv[])
{
    int rank, size;
    int global_n = 500;  /* Default global matrix size */
    int local_start, local_end, local_rows;
    double t_start, t_end;

    /* Initialize MPI */
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    /* Parse command line arguments */
    if (argc > 1) {
        global_n = atoi(argv[1]);
        if (global_n <= 0) {
            if (rank == 0) {
                fprintf(stderr, "Matrix size must be positive\n");
            }
            MPI_Finalize();
            return 1;
        }
    }

    /* Compute local chunk */
    compute_local_chunk(rank, size, global_n, &local_start, &local_end);
    local_rows = local_end - local_start;

    /* Print header from rank 0 */
    if (rank == 0) {
        printf("=== gprof MPI Example ===\n");
        printf("Global matrix size: %d x %d\n", global_n, global_n);
        printf("Number of MPI ranks: %d\n", size);
        printf("\nNote: For accurate gprof profiling with MPI:\n");
        printf("1. Rename gmon.out after each run (per rank)\n");
        printf("2. Profile with a single rank: srun -n1 ./mpi_example\n");
        printf("3. Or analyze a representative rank\n\n");
    }

    /* Allocate local matrices */
    double** A_local = allocate_matrix_local(local_rows, global_n);
    double** B = allocate_matrix_local(global_n, global_n);
    double** C_local = allocate_matrix_local(local_rows, global_n);
    double** D_local = allocate_matrix_local(local_rows, global_n);

    /* Initialize matrices */
    if (rank == 0) {
        printf("Initializing matrices...\n");
    }

    initialize_matrix_local(A_local, local_rows, global_n, 1.0);
    initialize_matrix_local(B, global_n, global_n, 2.0);
    initialize_matrix_local(C_local, local_rows, global_n, 0.0);
    initialize_matrix_local(D_local, local_rows, global_n, 0.0);

    /* Perform matrix multiplication (HOTSPOT) */
    if (rank == 0) {
        printf("Computing C = A * B (this is the HOTSPOT)...\n");
    }

    MPI_Barrier(MPI_COMM_WORLD);
    t_start = MPI_Wtime();

    matrix_multiply_local(A_local, B, C_local, local_rows, global_n);

    t_end = MPI_Wtime();

    if (rank == 0) {
        printf("Matrix multiplication time: %.4f seconds\n", t_end - t_start);
    }

    /* Perform matrix addition */
    if (rank == 0) {
        printf("Computing D = C + A...\n");
    }

    matrix_add_local(C_local, A_local, D_local, local_rows, global_n);

    /* Compute global norm */
    if (rank == 0) {
        printf("Computing global Frobenius norm...\n");
    }

    double local_norm = compute_local_norm(C_local, local_rows, global_n);
    double global_norm;

    MPI_Reduce(&local_norm, &global_norm, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);

    if (rank == 0) {
        global_norm = sqrt(global_norm);
        printf("||C||_F = %.4f\n", global_norm);
    }

    /* Call helper functions */
    if (rank == 0) {
        printf("\nCalling helper functions multiple times...\n");
    }

    MPI_Barrier(MPI_COMM_WORLD);

    for (int i = 0; i < 10; i++) {
        busy_wait_compute(10000);
    }

    /* Clean up */
    free_matrix_local(A_local, local_rows);
    free_matrix_local(B, global_n);
    free_matrix_local(C_local, local_rows);
    free_matrix_local(D_local, local_rows);

    /* Print completion message */
    if (rank == 0) {
        printf("\n=== Profiling complete ===\n");
        printf("\nTo analyze gprof output for this rank:\n");
        printf("  mv gmon.out gmon.out.rank0\n");
        printf("  gprof mpi_example gmon.out.rank0 > profile_rank0.txt\n");
        printf("\nFor single-rank profiling (recommended):\n");
        printf("  srun -n1 ./mpi_example\n");
        printf("  gprof mpi_example gmon.out > profile.txt\n");
    }

    MPI_Finalize();
    return 0;
}
