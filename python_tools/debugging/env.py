import os
import socket

def get_slurm_ntasks_per_node():
    ntasks_per_node = os.getenv('SLURM_NTASKS_PER_NODE')
    
    if ntasks_per_node:
        print(f"SLURM tasks per node: {ntasks_per_node}")
    else:
        print("SLURM_NTASKS_PER_NODE is not set.")



def get_slurm_cpus_per_task():
    cpus_per_task = os.getenv('SLURM_CPUS_PER_TASK')

    if cpus_per_task:
        print(f"SLURM_CPUS_PER_TASK: {cpus_per_task}")
    else:
        print("SLURM_CPUS_PER_TASK is not set.")

get_slurm_ntasks_per_node()
get_slurm_cpus_per_task()

current_directory = os.getcwd()
hostname = socket.gethostname()
print(f"{current_directory =}")
print(f"{hostname =}")