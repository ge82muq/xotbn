from frodokem import FrodoKEM
import mycommon
import sys

### TEST ###

FRODO_NBAR = 8

test = 'encode' 

frodo_sec = 'FrodoKEM-640-SHAKE' # <------ change

if frodo_sec == 'FrodoKEM-640-SHAKE':
    FRODO_N = 640
    len_sec = 128
elif frodo_sec == 'FrodoKEM-976-SHAKE':
    FRODO_N = 976
    len_sec = 196
elif frodo_sec == 'FrodoKEM-1344-SHAKE':
    FRODO_N = 1344
    len_sec = 256

B_bits = int(len_sec/(FRODO_NBAR*FRODO_NBAR))

### GENERATE TEST INPUTS ###

frodo = FrodoKEM(frodo_sec)

pk,sk = frodo.kem_keygen()

u_rnd, u_rnd_enc, ct, ss = frodo.kem_encaps(pk)

u_rnd_enc_hex = '' 
for row in u_rnd_enc:
    u_rnd_enc_hex += mycommon.intarr_to_hex(row,signed=False)

print("u:")
print(u_rnd)
print("u_enc:")
print(u_rnd_enc)
print("u_enc_hex:")
print(u_rnd_enc_hex)

### DEFINE MEMORY VARIABLES ### 

# [VAR_NAME,VAR_SIZE,VAR_VALUE,VAR_DTYPE] <- input_var(...)

vars = list()

vars.append(mycommon.input_var('u_rnd',u_rnd.hex(),32,words=True))

vars.append(mycommon.input_var('u_rnd_enc','',FRODO_NBAR*FRODO_NBAR*2,words=False))

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

otbn_out = vars[-1][mycommon.IDXVAR_VALUE]

print("otbn_u_enc:")
print(otbn_out)

assert u_rnd_enc_hex == otbn_out

BGRN = '\033[1;32m'  # Bold Green
NC   = '\033[0m'    # No Color (Reset)

print(f"TEST {test}: {BGRN}PASS{NC}")




