from frodokem import FrodoKEM
import mycommon
import sys

### TEST non-ephemeral FrodoKEM Encaps ###

test = 'Encaps' 

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

### GENERATE TEST INPUTS ###
frodo = FrodoKEM(instance)

seed_s,seedSE,seed_z,pk,sk,pkh = frodo.kem_keygen()

urnd, salt, seedSE, k, ct, ss = frodo.kem_encaps(pk)


print("--- ciphertext ----")

print(ct.hex())

print("--- shared secret ----")

print(ss.hex())

mask_msb = ['0080' for _ in range(16)]

mask_byte = ['00ff' for _ in range(16)]

# transform T_chi into a parallelized distribution table for SIMD execution #

distTable = [T_chi[i//16].to_bytes(2,'little').hex() for i in range(16*len(T_chi))]

maskbits_Tchi = ['0100' for _ in range(16)]

### DEFINE MEMORY VARIABLES ### 

# [VAR_NAME,VAR_SIZE,VAR_VALUE,VAR_DTYPE] <- input_var(...)

vars = list()

# lengths in bytes = real length of variable according to FrodoKEM standard

LEN_PK = len_pk
vars.append(mycommon.input_var('pk',pk.hex(),LEN_PK,words=False))

LEN_URND = len_sec
vars.append(mycommon.input_var('urnd',urnd.hex(),LEN_URND))

LEN_SALT = len_salt 
vars.append(mycommon.input_var('salt',salt.hex(),LEN_SALT))

LEN_MASK_MSB = 32
vars.append(mycommon.input_var('mask_msb',"".join(mask_msb),LEN_MASK_MSB,words=False))

LEN_MASK_BYTE = 32
vars.append(mycommon.input_var('mask_byte',"".join(mask_byte),LEN_MASK_BYTE,words=False))

LEN_TCHI = len(T_chi)*32
vars.append(mycommon.input_var('distTable',"".join(distTable),LEN_TCHI,words=False))

LEN_MASKTCHI = 32
vars.append(mycommon.input_var('maskbits_Tchi',"".join(maskbits_Tchi),LEN_MASKTCHI,words=False))

DMEM = 128000 # bytes
FREE_DMEM = DMEM-(LEN_URND+LEN_SALT+LEN_MASK_MSB+LEN_MASK_BYTE+LEN_TCHI+LEN_MASKTCHI+LEN_PK)

vars.append(mycommon.input_var('addr_free',"",FREE_DMEM))

### POPULATE DATA SECTION IN ASSEMBLY FILE ###

mycommon.write_to_section_data(test,vars)

### BUILD AND SIMULATE ###

mycommon.bazel_build(test, str(FRODO_N))


mycommon.pysim_otbn(test)

### PARSE MEMORY DUMP ###

mycommon.parse_mem_dump(vars)

### ASSERT ###

mycommon.read_parsed_mem_dump_encaps(vars,frodo_sec)

if frodo_sec == "640":
    len_cc = 9752
    gap = 8
    len_ss = 16
    otbn_cc = vars[-1][mycommon.IDXVAR_VALUE][:len_cc*2]
    print("----------- computed ciphertext ----------")
    print(otbn_cc)
    assert otbn_cc == ct.hex()
    otbn_ss = vars[-1][mycommon.IDXVAR_VALUE][(len_cc+gap)*2:(len_cc+gap)*2+len_ss*2]
    print("----------- shared secret ----------")
    print(otbn_ss)
    assert otbn_ss == ss.hex()
elif frodo_sec == "976":
    len_cc = 15792
    gap = 16
    len_ss = 24
    otbn_cc = vars[-1][mycommon.IDXVAR_VALUE][:len_cc*2]
    print("----------- computed ciphertext ----------")
    print(otbn_cc)
    assert otbn_cc == ct.hex()

    otbn_ss = vars[-1][mycommon.IDXVAR_VALUE][(len_cc+gap)*2:(len_cc+gap)*2+len_ss*2]
    print("----------- shared secret ----------")
    print(otbn_ss)
    assert otbn_ss == ss.hex()

elif frodo_sec == "1344":
    len_cc = 21696
    gap = 0
    len_ss = 32
    otbn_cc = vars[-1][mycommon.IDXVAR_VALUE][:len_cc*2]
    print("----------- computed ciphertext ----------")
    print(otbn_cc)
    assert otbn_cc == ct.hex()

    otbn_ss = vars[-1][mycommon.IDXVAR_VALUE][(len_cc+gap)*2:(len_cc+gap)*2+len_ss*2]
    print("----------- shared secret ----------")
    print(otbn_ss)
    assert otbn_ss == ss.hex()

else: 
    print("security level must be n = {640,976,1344}")
    sys.exit()

BGRN = '\033[1;32m'  # Bold Green
NC   = '\033[0m'    # No Color (Reset)

print(f"TEST {test}: {BGRN}PASS{NC}")





