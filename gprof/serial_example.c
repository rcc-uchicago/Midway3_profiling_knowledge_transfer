/*
 * Serial Matrix Computation Example for gprof Demonstration
 *
 * This program performs various matrix operations to demonstrate
 * profiling with gprof. It includes functions with different
 * computational intensities to create clear "hotspots" in the profile.
 *
 * Usage: ./serial_example [matrix_size]
 * Default matrix size: 500
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* Function prototypes */
double** allocate_matrix(int n);
void free_matrix(double** matrix, int n);
void initialize_matrix(double** matrix, int n, double value);
void matrix_multiply(double** A, double** B, double** C, int n);
void matrix_add(double** A, double** B, double** C, int n);
void matrix_transpose(double** A, double** AT, int n);
double compute_frobenius_norm(double** A, int n);
void print_matrix(double** matrix, int n, const char* name);
void busy_wait_function(int iterations);
void lightweight_function(int iterations);

/*
 * Allocate a n x n matrix
 */
double** allocate_matrix(int n)
{
    double** matrix = (double**)malloc(n * sizeof(double*));
    if (matrix == NULL) {
        fprintf(stderr, "Memory allocation failed\n");
        exit(1);
    }

    for (int i = 0; i < n; i++) {
        matrix[i] = (double*)malloc(n * sizeof(double));
        if (matrix[i] == NULL) {
            fprintf(stderr, "Memory allocation failed\n");
            exit(1);
        }
    }

    return matrix;
}

/*
 * Free a matrix
 */
void free_matrix(double** matrix, int n)
{
    for (int i = 0; i < n; i++) {
        free(matrix[i]);
    }
    free(matrix);
}

/*
 * Initialize matrix with a value
 * - LIGHTWEIGHT operation
 */
void initialize_matrix(double** matrix, int n, double value)
{
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            matrix[i][j] = value;
        }
    }
}

/*
 * Matrix multiplication: C = A * B
 * - COMPUTE INTENSIVE operation (O(n^3))
 * - This should appear as a HOTSPOT in the profile
 */
void matrix_multiply(double** A, double** B, double** C, int n)
{
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            C[i][j] = 0.0;
            for (int k = 0; k < n; k++) {
                C[i][j] += A[i][k] * B[k][j];
            }
        }
    }
}

/*
 * Matrix addition: C = A + B
 * - MODERATE operation (O(n^2))
 */
void matrix_add(double** A, double** B, double** C, int n)
{
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            C[i][j] = A[i][j] + B[i][j];
        }
    }
}

/*
 * Matrix transpose
 * - MODERATE operation (O(n^2))
 */
void matrix_transpose(double** A, double** AT, int n)
{
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            AT[i][j] = A[j][i];
        }
    }
}

/*
 * Compute Frobenius norm of a matrix
 * - LIGHTWEIGHT operation
 */
double compute_frobenius_norm(double** A, int n)
{
    double sum = 0.0;
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            sum += A[i][j] * A[i][j];
        }
    }
    return sqrt(sum);
}

/*
 * Print matrix (only for small matrices)
 * - I/O intensive, not compute intensive
 */
void print_matrix(double** matrix, int n, const char* name)
{
    if (n > 10) {
        printf("%s: [%d x %d matrix - too large to display]\n", name, n, n);
        return;
    }

    printf("%s:\n", name);
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            printf("%8.4f ", matrix[i][j]);
        }
        printf("\n");
    }
}

/*
 * A function with artificial computational work
 * - This demonstrates another HOTSPOT pattern
 */
void busy_wait_function(int iterations)
{
    volatile double result = 0.0;
    for (int i = 0; i < iterations; i++) {
        for (int j = 0; j < 1000; j++) {
            result += i * j * 0.001;
        }
    }
}

/*
 * A lightweight function called many times
 * - This demonstrates function call overhead
 */
void lightweight_function(int iterations)
{
    int sum = 0;
    for (int i = 0; i < iterations; i++) {
        sum += i;
    }
}

/*
 * Main function
 */
int main(int argc, char* argv[])
{
    int n = 500;  /* Default matrix size */

    /* Parse command line arguments */
    if (argc > 1) {
        n = atoi(argv[1]);
        if (n <= 0) {
            fprintf(stderr, "Matrix size must be positive\n");
            return 1;
        }
    }

    printf("=== gprof Serial Example ===\n");
    printf("Matrix size: %d x %d\n", n, n);
    printf("This will take a few seconds to generate profile data...\n\n");

    /* Allocate matrices */
    double** A = allocate_matrix(n);
    double** B = allocate_matrix(n);
    double** C = allocate_matrix(n);
    double** D = allocate_matrix(n);
    double** AT = allocate_matrix(n);

    /* Initialize matrices */
    printf("Initializing matrices...\n");
    initialize_matrix(A, n, 1.0);
    initialize_matrix(B, n, 2.0);
    initialize_matrix(C, n, 0.0);
    initialize_matrix(D, n, 0.0);
    initialize_matrix(AT, n, 0.0);

    /* Perform matrix operations */
    printf("Computing C = A * B (this is the HOTSPOT)...\n");
    matrix_multiply(A, B, C, n);

    printf("Computing D = C + A...\n");
    matrix_add(C, A, D, n);

    printf("Computing transpose of A...\n");
    matrix_transpose(A, AT, n);

    /* Compute norms */
    printf("Computing Frobenius norms...\n");
    double norm_C = compute_frobenius_norm(C, n);
    double norm_D = compute_frobenius_norm(D, n);
    printf("||C||_F = %.4f\n", norm_C);
    printf("||D||_F = %.4f\n", norm_D);

    /* Call helper functions multiple times */
    printf("\nCalling helper functions multiple times...\n");
    for (int i = 0; i < 100; i++) {
        lightweight_function(1000);
    }

    for (int i = 0; i < 10; i++) {
        busy_wait_function(10000);
    }

    /* Print small matrices */
    if (n <= 10) {
        print_matrix(A, n, "A");
        print_matrix(C, n, "C = A * B");
    }

    /* Clean up */
    free_matrix(A, n);
    free_matrix(B, n);
    free_matrix(C, n);
    free_matrix(D, n);
    free_matrix(AT, n);

    printf("\n=== Profiling complete ===\n");
    printf("Analyze with: gprof serial_example gmon.out\n");

    return 0;
}
