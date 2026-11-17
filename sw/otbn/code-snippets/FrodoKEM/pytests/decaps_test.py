from frodokem import FrodoKEM
import mycommon
import sys

### TEST non-ephemeral FrodoKEM Decaps ###

test = 'Decaps' 

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
    len_pk = FRODO_N*FRODO_NBAR*2-FRODO_N+len_A 
    len_c1 = 9600
    len_c2 = 120
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
    len_pk = FRODO_N*FRODO_NBAR*2+len_A 
    len_c1 = 15616
    len_c2 = 128
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
    len_pk = FRODO_N*FRODO_NBAR*2+len_A 
    len_c1 = 21504
    len_c2 = 128

### GENERATE TEST INPUTS ###
frodo = FrodoKEM(instance)

seed_s,seedSE,seed_z,pk,sk,pkh = frodo.kem_keygen()

urnd, salt, seedSE, k, ct, ss_encaps = frodo.kem_encaps(pk)

ss_decaps, V, Sprime, SprimeB, B, Eprimeprime, kprime = frodo.kem_decaps(sk,ct)

assert ss_encaps == ss_decaps

mask_msb = ['0080' for _ in range(16)]

mask_byte = ['00ff' for _ in range(16)]

# transform T_chi into a parallelized distribution table for SIMD execution #

distTable = [T_chi[i//16].to_bytes(2,'little').hex() for i in range(16*len(T_chi))]

maskbits_Tchi = ['0100' for _ in range(16)]

### DEFINE MEMORY VARIABLES ### 

# [VAR_NAME,VAR_SIZE,VAR_VALUE,VAR_DTYPE] <- input_var(...)

vars = list()

# lengths in bytes = real length of variable according to FrodoKEM standard

LEN_CT = len_c1+len_c2+len_salt
vars.append(mycommon.input_var('ciphertext',ct.hex(),LEN_CT,words=False))

LEN_SK = len(sk)
vars.append(mycommon.input_var('secret_key',sk.hex(),LEN_SK,words=False))

LEN_MASK_MSB = 32
vars.append(mycommon.input_var('mask_msb',"".join(mask_msb),LEN_MASK_MSB,words=False))

LEN_MASK_BYTE = 32
vars.append(mycommon.input_var('mask_byte',"".join(mask_byte),LEN_MASK_BYTE,words=False))

LEN_TCHI = len(T_chi)*32
vars.append(mycommon.input_var('distTable',"".join(distTable),LEN_TCHI,words=False))

LEN_MASKTCHI = 32
vars.append(mycommon.input_var('maskbits_Tchi',"".join(maskbits_Tchi),LEN_MASKTCHI,words=False))

DMEM = 128000 # bytes
FREE_DMEM = DMEM-(LEN_MASK_MSB+LEN_MASK_BYTE+LEN_TCHI+LEN_MASKTCHI+LEN_CT+LEN_SK)

vars.append(mycommon.input_var('addr_free',"",FREE_DMEM))

### POPULATE DATA SECTION IN ASSEMBLY FILE ###

mycommon.write_to_section_data(test,vars)

### BUILD AND SIMULATE ###

mycommon.bazel_build(test, str(FRODO_N))


mycommon.pysim_otbn(test)

### PARSE MEMORY DUMP ###

mycommon.parse_mem_dump(vars)

### ASSERT ###

mycommon.read_parsed_mem_dump_ss(vars,frodo_sec)

print("-------------- shared secret ------------------")
print(ss_decaps.hex())

print("--------- computed shared secret ------------------")

otbn_ss = vars[-1][mycommon.IDXVAR_VALUE]
print(otbn_ss)

assert otbn_ss == ss_decaps.hex()

BGRN = '\033[1;32m'  # Bold Green
NC   = '\033[0m'    # No Color (Reset)

print(f"TEST {test}: {BGRN}PASS{NC}")





