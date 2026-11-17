from frodokem import FrodoKEM
import mycommon
import sys

### TEST ###

FRODO_N = 1344
FRODO_NBAR = 8

test = 'pack' 

### GENERATE TEST INPUTS ###

frodo = FrodoKEM("FrodoKEM-1344-SHAKE")

B,b = frodo.kem_keygen()

mask_msb = ['0080' for _ in range(16)]

mask_byte = ['00ff' for _ in range(16)]

### DEFINE MEMORY VARIABLES ### 

# [VAR_NAME,VAR_SIZE,VAR_VALUE,VAR_DTYPE] <- input_var(...)

vars = list()

LEN_MASK_MSB = 32
vars.append(mycommon.input_var('mask_msb',"".join(mask_msb),LEN_MASK_MSB,words=False))

LEN_MASK_BYTE = 32
vars.append(mycommon.input_var('mask_byte',"".join(mask_byte),LEN_MASK_BYTE,words=False))

matrix_hex = ''
for row in B:
    matrix_hex += mycommon.intarr_to_hex(row,signed=False)

# print(f"b = {b.hex()[:64]}")
# print(f"b = {b.hex()[64:128]}")

LEN_MATRIX = FRODO_N*FRODO_NBAR*2
vars.append(mycommon.input_var('matrix',matrix_hex,LEN_MATRIX,words=False))

### POPULATE DATA SECTION IN ASSEMBLY FILE ###

mycommon.write_to_section_data(test,vars)

# sys.exit() # debugging

### BUILD AND SIMULATE ###

mycommon.bazel_build(test)

mycommon.pysim_otbn(test)

### PARSE MEMORY DUMP ###

mycommon.parse_mem_dump(vars)

### ASSERT ###

mycommon.read_parsed_mem_dump(vars)

idx_matrixB = -1 # according to vars.append
otbn_out = vars[idx_matrixB][mycommon.IDXVAR_VALUE]

print(f"Solution:")
print(b.hex()[:64*16])
print("---------------")
print("OTBN:")
print(otbn_out[:64*16])

assert b.hex() == otbn_out[:len(b.hex())]

BGRN = '\033[1;32m'  # Bold Green
NC   = '\033[0m'    # No Color (Reset)

print(f"TEST {test}: {BGRN}PASS{NC}")




