#!/bin/bash

# Replace these 3 entries
PROJ_DIR=/gpfs/wolf/proj-shared/trn017/$USER
export JULIA_DEPOT_PATH=$PROJ_DIR/julia_depot
GS_DIR=$PROJ_DIR/GrayScott.jl

# remove existing generated Manifest.toml
rm -f $GS_DIR/Manifest.toml
rm -f $GS_DIR/LocalPreferences.toml

# good practice to avoid conflicts with existing default modules 
# needed to avoid seg fault with MPI
module purge

# load required modules
module load spectrum-mpi
# recent gcc needed
module load gcc/11.2.0 
# failure with 11.5.2
module load cuda/11.4.2 
module load adios2/2.8.1
module load julia/1.9.0

# Required to enable underlying ADIOS2 library from loaded module
# https://eschnett.github.io/ADIOS2.jl/dev/#Using-a-custom-or-system-provided-ADIOS2-library
export JULIA_ADIOS2_PATH=$OLCF_ADIOS2_ROOT

# Adds to LocalPreferences.toml to use underlying system prior to CUDA.jl v4.0.0
# PowerPC related bugs in CUDA.jl v4
# This is decrepated in CUDA.jl v4 
export JULIA_CUDA_USE_BINARYBUILDER=false

# For CUDA.jl > v4
# Adds to LocalPreferences.toml to use underlying system CUDA since CUDA.jl v4.0.0
# https://cuda.juliagpu.org/stable/installation/overview/#Using-a-local-CUDA
# julia --project=$GS_DIR -e 'using CUDA; CUDA.set_runtime_version!("local")'

# MPIPreferences to use spectrum-mpi
# https://juliaparallel.org/MPI.jl/latest/configuration/#using_system_mpi
julia --project=$GS_DIR -e 'using Pkg; Pkg.add("MPIPreferences")'
julia --project=$GS_DIR -e 'using MPIPreferences; MPIPreferences.use_system_binary(; library_names=["libmpi_ibm"], mpiexec="jsrun")'

# Instantiate the project by installing packages in Project.toml
julia --project=$GS_DIR -e 'using Pkg; Pkg.instantiate()'

# Adds a custom branch in case the development version is needed (for devs to test new features)
julia --project=$GS_DIR -e 'using Pkg; Pkg.add(url="https://github.com/eschnett/ADIOS2.jl.git", rev="main")'

# Build the new ADIOS2
julia --project=$GS_DIR -e 'using Pkg; Pkg.build()'
julia --project=$GS_DIR -e 'using Pkg; Pkg.precompile()'
