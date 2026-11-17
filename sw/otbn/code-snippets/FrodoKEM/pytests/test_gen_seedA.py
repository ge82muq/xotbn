import hashlib
import mycommon
import subprocess
import sys
import os

### TEST ###

test = 'gen_seedA'

### GENERATE TEST INPUTS ###

seed_z = b'\xBA\x9D\xC5\xBA\x76\xA9\x8F\xE2\xCA\xBB\x3C\x27\xF8\xE6\x82\x45'

### EXPECTED OUTPUT ###

def compute_expout():
    shake_hash = hashlib.shake_128()

    shake_hash.update(seed_z)

    pytest_seedA = shake_hash.digest(16)

    return pytest_seedA.hex()

### DEFINE MEMORY VARIABLES ### 

vars = list()

vars.append(mycommon.input_var('seed_z',seed_z.hex(),16))

vars.append(mycommon.input_var('seed_A','',16,init=False))

vars.append(mycommon.input_var('kmac_input','',32,init=False))

vars.append(mycommon.input_var('kmac_output','',32,init=False))


IDX_SEED_Z = 0
IDX_SEED_A = 1
IDX_KMAC_INPUT = 2
IDX_KMAC_OUTPUT = 3

### POPULATE DATA SECTION IN ASSEMBLY FILE ###

mycommon.write_to_section_data(test,vars)

### BUILD AND SIMULATE ###

mycommon.bazel_build(test)

mycommon.pysim_otbn(test)

### PARSE MEMORY DUMP ###

mycommon.parse_mem_dump(vars)


### ASSERT ###

mycommon.read_parsed_mem_dump(vars)

otbn_out = vars[IDX_SEED_A][mycommon.IDXVAR_VALUE]

print(otbn_out)

pytest_seedA = compute_expout()

print(pytest_seedA)

assert pytest_seedA == otbn_out

BGRN = '\033[1;32m'  # Bold Green
NC   = '\033[0m'    # No Color (Reset)

print(f"TEST {test}: {BGRN}PASS{NC}")





