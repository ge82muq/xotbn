from frodokem import FrodoKEM
import mycommon
import sys

### TEST non-ephemeral FrodoKEM KeyGen ###
test = 'KeyGen' 

# 1. t_A must be even. 
# 2. t_A must divide exactly n=640,976,1344.
t_A = sys.argv[1]
# security level n = {640,976,1344}
frodo_sec = sys.argv[2]
mycommon.create_test_OP(test,t_A,frodo_sec)

if int(frodo_sec) == 640:
    instance = 'FrodoKEM-640-SHAKE'
    FRODO_N = 640
    D = 15
    len_sec = 16
    len_SE = 32
    len_salt = 32
    T_chi = [4643,13363,20579,25843,29227,31145,32103,32525,32689,32745,32762,32766,32767]
    FRODO_NBAR = 8
    len_A = 16 
elif int(frodo_sec) == 976:
    instance = 'FrodoKEM-976-SHAKE'
    FRODO_N = 976
    D = 16
    len_sec = 24
    len_SE = 48
    len_salt = 48
    T_chi = [5638,15915,23689,28571,31116,32217,32613,32731,32760,32766,32767]
    FRODO_NBAR = 8
    len_A = 16 
elif int(frodo_sec) == 1344:
    instance = 'FrodoKEM-1344-SHAKE'
    FRODO_N = 1344
    D = 16
    len_sec = 32
    len_SE = 64
    len_salt = 64
    T_chi = [9142,23462,30338,32361,32725,32765,32767]
    FRODO_NBAR = 8
    len_A = 16 


### GENERATE TEST INPUTS ###

frodo = FrodoKEM(instance)

seed_s,seedSE,seed_z,pk,sk,pkh = frodo.kem_keygen()

mask_msb = ['0080' for _ in range(16)]

mask_byte = ['00ff' for _ in range(16)]

# transform T_chi into a parallelized distribution table for SIMD execution #
distTable = [T_chi[i//16].to_bytes(2,'little').hex() for i in range(16*len(T_chi))]

maskbits_Tchi = ['0100' for _ in range(16)]

### DEFINE MEMORY VARIABLES ### 

# [VAR_NAME,VAR_SIZE,VAR_VALUE,VAR_DTYPE] <- input_var(...)

vars = list()

# lengths in bytes = real length of variable according to FrodoKEM standard

LEN_SEEDS = len_sec # length for parsing correctly memory dump.
vars.append(mycommon.input_var('seed_s',seed_s.hex(),LEN_SEEDS))

LEN_SEEDZ = len_A # constant
vars.append(mycommon.input_var('seed_z',seed_z.hex(),LEN_SEEDZ))

LEN_SEEDSE = len_SE
vars.append(mycommon.input_var('seed_SE',seedSE.hex(),LEN_SEEDSE))

LEN_MASK_MSB = 32
vars.append(mycommon.input_var('mask_msb',"".join(mask_msb),LEN_MASK_MSB,words=False))

LEN_MASK_BYTE = 32
vars.append(mycommon.input_var('mask_byte',"".join(mask_byte),LEN_MASK_BYTE,words=False))

LEN_TCHI = len(T_chi)*32
vars.append(mycommon.input_var('distTable',"".join(distTable),LEN_TCHI,words=False))

LEN_MASKTCHI = 32
vars.append(mycommon.input_var('maskbits_Tchi',"".join(maskbits_Tchi),LEN_MASKTCHI,words=False))

LEN_PKH = len_sec
vars.append(mycommon.input_var('pkh',"",LEN_PKH))

DMEM = 128000 # bytes
FREE_DMEM = DMEM-(LEN_SEEDS+LEN_SEEDZ+LEN_SEEDSE+LEN_MASK_MSB+LEN_MASK_BYTE+LEN_TCHI+LEN_MASKTCHI+LEN_PKH)

vars.append(mycommon.input_var('addr_free',"",FREE_DMEM))

### POPULATE DATA SECTION IN ASSEMBLY FILE ###

mycommon.write_to_section_data(test,vars)

### BUILD AND SIMULATE ###

mycommon.bazel_build(test, str(FRODO_N))

# sys.exit() # debugging

mycommon.pysim_otbn(test)

### PARSE MEMORY DUMP ###

mycommon.parse_mem_dump(vars)

### ASSERT ###

mycommon.read_parsed_mem_dump_keygen(vars)

# Ahex = ""
# for row in A[:2]:
#     Ahex += mycommon.intarr_to_hex(row,signed=False)
# print(Ahex)
# AS_hex = ""
# for row in AS[:16]:
#     AS_hex += mycommon.intarr_to_hex(row,signed=False)

# print(AS_hex)

# B_hex = ""
# for row in B:
#     B_hex += mycommon.intarr_to_hex(row,signed=False)

# print(B_hex)


# sys.exit()


otbn_pkh = vars[-2][mycommon.IDXVAR_VALUE]

#print(pk.hex())
print("----------- pkh ----------")
print(pkh.hex())
print("----- computed pkh --------")
print(otbn_pkh)

assert otbn_pkh == pkh.hex()

BGRN = '\033[1;32m'  # Bold Green
NC   = '\033[0m'    # No Color (Reset)

print(f"TEST {test}: {BGRN}PASS{NC}")





