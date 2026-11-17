import hashlib
import mycommon
import sys

### TEST ###

FRODO_N = 640
FRODO_NTILDE = 8

test = 'inverse_sampler'

# set nr of 2-byte elements to sample #
X = 64 # <-------------------------------------- MODIFY FOR DESIRED TEST

### GENERATE TEST INPUTS ###

# we generate first the whole pseudorandom string and later extract only the bytes necessary for testing #

ELEMENTS_PRNDSTR = FRODO_N*FRODO_NTILDE*2
LEN_PRNDSTR = ELEMENTS_PRNDSTR*2 # bytes

seedSE = b'\xe6\xbf\xcd\x84\xe4\x7b\xab\x41' + b'\xb8\x73\x7a\x4d\x2d\x61\xf9\x5f' + b'\x2b\x35\xef\x7d\x20\xc3\xd9\x63' + b'\xc1\xe3\xf2\x09\xd9\xac\xb7\x19'

shake_hash = hashlib.shake_128()
shake_hash.update(b'\x5f'+seedSE)
prndstr = shake_hash.digest(LEN_PRNDSTR)

T_chi = [4643,13363,20579,25843,29227,31145,32103,32525,32689,32745,32762,32766,32767]

# transform T_chi into a parallelized distribution table for SIMD execution #

distTable = [T_chi[i//16].to_bytes(2,'little').hex() for i in range(16*len(T_chi))]

maskbits_Tchi = ['0100' for _ in range(16)]

### EXPECTED OUTPUT ###

def inv_sampling(intstr):
    sampledstr = list()
    for r in intstr:
        lsb = r & 1
        t = r >> 1
        e = 0
        for val in T_chi:
            if t > val:
                e += 1
        e = pow(-1,lsb)*e
        sampledstr.append(e)
    return sampledstr

def sample_str(bitstr):
    inputstr = [int.from_bytes(bitstr[i:i+2],byteorder='little') for i in range(0,len(bitstr),2)]

    return inv_sampling(inputstr)

def sample_matrices_S_E():

    inputstr_S_T = [int.from_bytes(prndstr[i:i+2],byteorder='little') for i in range(0,len(prndstr)//2,2)]

    inputstr_E = [int.from_bytes(prndstr[i:i+2],byteorder='little') for i in range(LEN_PRNDSTR//2,len(prndstr),2)]
             
    ### S_T ###

    S_T = inv_sampling(inputstr_S_T)

    ### E ###

    E = inv_sampling(inputstr_E)

    return (S_T,E)


### DEFINE MEMORY VARIABLES ### 

vars = list()

vars.append(mycommon.input_var('prndstr',prndstr[:X*2].hex(),X*2))


vars.append(mycommon.input_var('distTable',"".join(distTable),len(T_chi)*32,words=False))


vars.append(mycommon.input_var('maskbits_Tchi',"".join(maskbits_Tchi),32,words=False))


vars.append(mycommon.input_var('sampled_out','',X*2,init=False))

IDX_PRNDSTR = 0
IDX_DISTTABLE = 1
IDX_MASKBITS_TCHI = 2
IDX_SAMPLED_OUT = 3

### POPULATE DATA SECTION IN ASSEMBLY FILE ###

mycommon.write_to_section_data(test,vars)

### BUILD AND SIMULATE ###

mycommon.bazel_build(test)

# sys.exit() # <------ for debugging

mycommon.pysim_otbn(test)

### PARSE MEMORY DUMP ###

mycommon.parse_mem_dump(vars)

### ASSERT ###

mycommon.read_parsed_mem_dump(vars)

solution = mycommon.intarr_to_hex(sample_str(prndstr[:X*2]),signed=True)

print(solution)

otbn_out = vars[IDX_SAMPLED_OUT][mycommon.IDXVAR_VALUE]

print(otbn_out)

assert solution == otbn_out

BGRN = '\033[1;32m'  # Bold Green
NC   = '\033[0m'    # No Color (Reset)

print(f"TEST {test}: {BGRN}PASS{NC}")





