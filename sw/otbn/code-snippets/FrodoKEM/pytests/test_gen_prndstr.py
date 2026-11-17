import hashlib
import mycommon
import sys

### TEST ###

FRODO_N = 640
FRODO_NTILDE = 8

test = 'gen_prndstr'

ELEMENTS_STR = FRODO_N*FRODO_NTILDE*2
LENSTR = 1280 # bytes # <-------------- MODIFY FOR DESIRED TEST

### GENERATE TEST INPUTS ###

seedSE = b'\xe6\xbf\xcd\x84\xe4\x7b\xab\x41' + b'\xb8\x73\x7a\x4d\x2d\x61\xf9\x5f' + b'\x2b\x35\xef\x7d\x20\xc3\xd9\x63' + b'\xc1\xe3\xf2\x09\xd9\xac\xb7\x19'

### EXPECTED OUTPUT ###

def compute_expout():

    shake_hash = hashlib.shake_128()
    shake_hash.update(b'\x5f'+seedSE)
    pytest_prndstr = shake_hash.digest(LENSTR)

    return pytest_prndstr.hex()


### DEFINE MEMORY VARIABLES ### 

IDXVAR_NAME = 0
IDXVAR_SIZE = 1
IDXVAR_VALUE = 2
IDXVAR_DTYPE = 3

ass_var = 'seed_SE'
ass_var_size_bytes = 32
var_value = mycommon.split_hex(seedSE.hex())
data_type = 'word'
var_seed_SE = [ass_var,ass_var_size_bytes,var_value,data_type]

ass_var = 'kmac_input'
ass_var_size_bytes = 33
var_value = None
data_type = None
var_kmac_input = [ass_var,ass_var_size_bytes,var_value,data_type]

ass_var = 'kmac_output'
ass_var_size_bytes = LENSTR
var_value = None
data_type = None
var_kmac_output = [ass_var,ass_var_size_bytes,var_value,data_type]

vars = [var_seed_SE,var_kmac_input,var_kmac_output]

IDX_SEED_SE = 0
IDX_KMAC_INPUT = 1
IDX_KMAC_OUTPUT = 2

### POPULATE DATA SECTION IN ASSEMBLY FILE ###

mycommon.write_to_section_data(test,vars)

### BUILD AND SIMULATE ###

mycommon.bazel_build(test)

mycommon.pysim_otbn(test)

### PARSE MEMORY DUMP ###

mycommon.parse_mem_dump(vars)

### ASSERT ###

mycommon.read_parsed_mem_dump(vars)

otbn_out = vars[IDX_KMAC_OUTPUT][IDXVAR_VALUE]

solution = compute_expout()

assert solution == otbn_out

BGRN = '\033[1;32m'  # Bold Green
NC   = '\033[0m'    # No Color (Reset)

print(f"TEST {test}: {BGRN}PASS{NC}")





