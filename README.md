
# Implementing FrodoKEM on OpenTitan's OTBN

In the following, we will give a description on how to re-run our tests and reproduce the results. 

## Getting started
Clone the xotbn repository at your home directory ~. The python tests require the project to be cloned at home ~ under the name xotbn. Our tests run successfully with python versions 3.8 and 3.10. Python wheels fail to build with python version 3.12.1. Other python versions have not been tested. We recommend *pyenv* for managing multiple python versions on your system. 

We will now set up the environment. The next step is to install the RISCV32 toolchain on your system. 

```
# Install GNU's compiler for the RISCV32 architecture as OTBN's ISA is partially based on the RISCV32 instruction set. 
# You can use a precompiled binary and extract it to e.g. /tools/riscv and add the location of the binary to your PATH on your .bashrc. 
export PATH=$PATH:/tools/riscv/bin

```
Make sure you have the right Python version activated before following the next steps.

```
# Installing Python dependencies in a virtual environment.
python -m venv .venv
source .venv/bin/activate
pip install -r python-requirements.txt
pip install -r python-extra-requirements.txt
```
Before building code successfully with Bazel, it is required to make one manual modification to resolve
an issue with the dependencies of the OpenTitan repositories. Look for Bazel's hash of the project. This is found in `~/.cache/bazel/_bazel_<USER>/<HASH>`. If it has not been generated try building some target with Bazel and then do `./bazelisk.sh info`. This will show the hash used by Bazel.

After that, copy the two files `aux/bazel.py` and `aux/wheel.py` from this repository to
`~/.cache/bazel/_bazel_<USER>/<HASH>/external/rules_python/python/pip_install/extract_wheels/lib`. 

Now, you are all set up to run the tests as described below. Our code is found in `sw/otbn/code-snippets/FrodoKEM`.


## Running the tests
Our implementation is tested against the python implementation of FrodoKEM `pytests/frodokem.py` taken from FrodoKEM's GitHub [repository](https://github.com/Microsoft/PQCrypto-LWEKE). It provides random input seeds for every run of KeyGen, Encaps and Decaps.

In order to test the implementations of KeyGen, Encaps and Decaps go to `sw/otbn/code-snippets/FrodoKEM`, and run the following command:
```
python pytests/{keygen,encaps,decaps}_test.py PARAM_t PARAM_n
```
`PARAM_n` refers to the security level n=640,976,1344. `PARAM_t` refers to the number of $A$ rows ($t_A$) that should be generated on demand. Our results are reproducible for `PARAM_t=[2,4,8,16]` for KeyGen-{640,976,1344}, Encaps-{640,976,1344} and Decaps-640; `PARAM_t=[2,4,8]` for Decaps-976; and `PARAM_t=[2,4]` for Decaps-1344. 

## Output
Our python tests generate the data section of our source files automatically in the folder `data-auto` and the output of the python simulation in `tmp-out`. The total number of cycles can be read from `tmp-out/out_{KeyGen,Encaps,Decaps}`.



