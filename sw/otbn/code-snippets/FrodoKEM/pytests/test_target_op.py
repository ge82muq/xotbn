from frodokem import FrodoKEM
import mycommon
import sys

### TEST ###

FRODO_N = 640
FRODO_NBAR = 8

test = 'target_op' 

# 1. t_A must be even. 
# 2. t_A must divide exactly n=640.
t_A = sys.argv[1]

### nr of A rows for testing purposes: ignored in this implementation because is reasonably fast ###
n = sys.argv[2]

mycommon.create_test_target_op(t_A,n)

### GENERATE TEST INPUTS ###

frodo = FrodoKEM("FrodoKEM-640-SHAKE")

seed_z, seedSE, B = frodo.kem_keygen()

T_chi = [4643,13363,20579,25843,29227,31145,32103,32525,32689,32745,32762,32766,32767]

# transform T_chi into a parallelized distribution table for SIMD execution #

distTable = [T_chi[i//16].to_bytes(2,'little').hex() for i in range(16*len(T_chi))]

maskbits_Tchi = ['0100' for _ in range(16)]

### DEFINE MEMORY VARIABLES ### 

# [VAR_NAME,VAR_SIZE,VAR_VALUE,VAR_DTYPE] <- input_var(...)

vars = list()

# lengths in bytes
LEN_SEEDZ = 16 # length for parsing correctly memory dump. In DMEM we have 32B alignment.
vars.append(mycommon.input_var('seed_z',seed_z.hex(),LEN_SEEDZ))

LEN_SEEDSE = 32
vars.append(mycommon.input_var('seed_SE',seedSE.hex(),LEN_SEEDSE))

LEN_TCHI = len(T_chi)*32
vars.append(mycommon.input_var('distTable',"".join(distTable),LEN_TCHI,words=False))

LEN_MASKTCHI = 32
vars.append(mycommon.input_var('maskbits_Tchi',"".join(maskbits_Tchi),LEN_MASKTCHI,words=False))

LEN_SEEDA = 16 # length for parsing correctly memory dump. In DMEM we have 32B alignment.
vars.append(mycommon.input_var('seed_A','',LEN_SEEDA,init=False))

LEN_CTR_AGEN = 32
vars.append(mycommon.input_var('ctr_Agen','',LEN_CTR_AGEN,init=False))

LEN_KMAC_INPUT = 64
vars.append(mycommon.input_var('kmac_input','',LEN_KMAC_INPUT,init=False))

LEN_PRNDSTR = 20480
vars.append(mycommon.input_var('buf_sampled','',LEN_PRNDSTR,init=False))

LEN_MATRIX_B = FRODO_N*FRODO_NBAR*2
vars.append(mycommon.input_var('matrix_B','',LEN_MATRIX_B,init=False))

LEN_ROWA = FRODO_N*2 # bytes
vars.append(mycommon.input_var('matrix_A','',int(t_A)*LEN_ROWA,init=False))

### POPULATE DATA SECTION IN ASSEMBLY FILE ###

mycommon.write_to_section_data(test,vars)

### BUILD AND SIMULATE ###

mycommon.bazel_build(test)

# sys.exit() # debugging

mycommon.pysim_otbn(test)

### PARSE MEMORY DUMP ###

mycommon.parse_mem_dump(vars)

### ASSERT ###

mycommon.read_parsed_mem_dump(vars)

solution = ''
for row in B:
    solution += mycommon.intarr_to_hex(row,signed=False)

idx_matrixB = -2 # according to vars.append
otbn_out = vars[idx_matrixB][mycommon.IDXVAR_VALUE]

print("otbn_out:")
print(otbn_out)
print("solution:")
print(solution[:len(otbn_out)])

assert solution[:len(otbn_out)] == otbn_out

BGRN = '\033[1;32m'  # Bold Green
NC   = '\033[0m'    # No Color (Reset)

print(f"TEST {test}: {BGRN}PASS{NC}")





