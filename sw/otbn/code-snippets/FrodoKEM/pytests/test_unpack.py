from frodokem import FrodoKEM
import mycommon
import sys

### TEST ###

FRODO_N = 640
FRODO_NBAR = 8

test = 'unpack' 

### GENERATE TEST INPUTS ###

frodo = FrodoKEM("FrodoKEM-640-SHAKE")

B,b = frodo.kem_keygen()

B_hex = '' 
for row in B:
    B_hex += mycommon.intarr_to_hex(row,signed=False)

print(f"B (big):")
print([coeff.to_bytes(2,'big').hex() for coeff in B[0]])
print([coeff.to_bytes(2,'big').hex() for coeff in B[1]])
print("----------------------")
print([coeff.to_bytes(2,'big').hex() for coeff in B[2]])
print([coeff.to_bytes(2,'big').hex() for coeff in B[3]])
print("----------------------")
print("----------------------")
print([coeff.to_bytes(2,'big').hex() for coeff in B[28]])
print([coeff.to_bytes(2,'big').hex() for coeff in B[29]])
print("----------------------")
print([coeff.to_bytes(2,'big').hex() for coeff in B[30]])
print([coeff.to_bytes(2,'big').hex() for coeff in B[31]])
print("----------------------")


# print(f"b:")
# print(b.hex()[:64*2])


mask_msb = ['0080' for _ in range(16)]

mask_byte = ['00ff' for _ in range(16)]

### DEFINE MEMORY VARIABLES ### 

# [VAR_NAME,VAR_SIZE,VAR_VALUE,VAR_DTYPE] <- input_var(...)

vars = list()

LEN_MASK_MSB = 32
vars.append(mycommon.input_var('mask_msb',"".join(mask_msb),LEN_MASK_MSB,words=False))

LEN_MASK_BYTE = 32
vars.append(mycommon.input_var('mask_byte',"".join(mask_byte),LEN_MASK_BYTE,words=False))

LEN_MATRIX = 9600
vars.append(mycommon.input_var('packed_matrix',b.hex(),LEN_MATRIX,words=False))

LEN_MATRIX = FRODO_N*FRODO_NBAR*2 # size of unpacked matrix
vars.append(mycommon.input_var('unpacked_matrix','',LEN_MATRIX,words=False))

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

# print(f"Solution:")
# print(B_hex[:64])
# print("OTBN:")
# print(otbn_out[:64])
# print("---------------")
# print(f"Solution:")
# print(B_hex[64:128])
# print("OTBN:")
# print(otbn_out[64:128])
# print("---------------")
# print(f"Solution:")
# print(B_hex[128:192])
# print("OTBN:")
# print(otbn_out[128:192])
# print("---------------")


assert B_hex == otbn_out

BGRN = '\033[1;32m'  # Bold Green
NC   = '\033[0m'    # No Color (Reset)

print(f"TEST {test}: {BGRN}PASS{NC}")




