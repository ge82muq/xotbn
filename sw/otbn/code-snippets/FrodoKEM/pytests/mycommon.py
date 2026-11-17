import os
import sys
import subprocess
import hashlib
import numpy as np

BRED = '\033[1;31m' # Bold Red
BGRN = '\033[1;32m'  # Bold Green
NC   = '\033[0m'    # No Color (Reset)

### --- XOTBN repo should be installed at users home dir --- ###

xotbn_dir = '~/xotbn/' 
xotbn_dir = os.path.expanduser(xotbn_dir)

FrodoKEM_dir = xotbn_dir + 'sw/otbn/code-snippets/FrodoKEM/'

memdump = FrodoKEM_dir + 'tmp-out/memdump'
parsed_memdump = FrodoKEM_dir + 'tmp-out/parsed_memdump'

### ------------------------------------------ ###

# define positions in variable generation for a variable var #

TOTAL_ATTR = 4

IDXVAR_NAME = 0
IDXVAR_SIZE = 1
IDXVAR_VALUE = 2
IDXVAR_DTYPE = 3

# generate only one main shake instance #
shake_ = hashlib.shake_128()

def sample_bitstr(bitstr):
    T_chi = [4643,13363,20579,25843,29227,31145,32103,32525,32689,32745,32762,32766,32767]
    matrix = list()
    for r in bitstr:
        lsb = r & 1
        t = r >> 1
        e = 0
        for val in T_chi:
            if t > val:
                e += 1
        e = pow(-1,lsb)*e
        matrix.append(e)
    return matrix

def sample_matrices(bitstr):
    bitstr_S_T = [int.from_bytes(bitstr[i:i+2],byteorder='little') for i in range(0,len(bitstr)//2,2)]

    bitstr_E = [int.from_bytes(bitstr[i:i+2],byteorder='little') for i in range(1280*8,len(bitstr),2)]

    S_T = sample_bitstr(bitstr_S_T)
    E = sample_bitstr(bitstr_E)
    return (S_T,E)


def gen_prndstr():
    shake_hash = hashlib.new(shake_.name)

    seedSE = b'\xe6\xbf\xcd\x84\xe4\x7b\xab\x41'+b'\xb8\x73\x7a\x4d\x2d\x61\xf9\x5f'+b'\x2b\x35\xef\x7d\x20\xc3\xd9\x63'+b'\xc1\xe3\xf2\x09\xd9\xac\xb7\x19'

    shake_hash.update(b'\x5f'+seedSE)

    d = 640*8*2*2

    bitstr = shake_hash.digest(d) # bytes
    return bitstr

def gen_matrixA(nrows):
    shake_hash = hashlib.new(shake_.name)

    seed_z = b'\xBA\x9D\xC5\xBA\x76\xA9\x8F\xE2\xCA\xBB\x3C\x27\xF8\xE6\x82\x45'
    shake_hash.update(seed_z)

    seedA = shake_hash.digest(16)

    d = 1280
    rowsA = list()
    for i in range(0,nrows):
        b = int.to_bytes(i,2,'little')
        shake_hash = hashlib.new(shake_.name)
        shake_hash.update(b+seedA)
        rowsA.append(shake_hash.digest(d))
    
    # create 16-bit entries

    rowsA = [[int.from_bytes(rowsA[row][i:i+2],byteorder='little')%pow(2,15) for i in range(0,len(rowsA[row]),2)] for row in range(0,nrows)]

    return rowsA

def multAS(nrows):
    rowsA = gen_matrixA(nrows)
    S_T,E = sample_matrices(gen_prndstr())
    # Transpose S_T #
    S = [S_T[i:i+640] for i in range(0,len(S_T),640)]

    B = list()
    for row in rowsA:
        for col in S:
            B.append(int(np.dot(np.array(row),np.array(col))%pow(2,15)))
    return B

def bytearr_to_hex(bytearr):
    return "".join([b.hex() for b in bytearr])

def int_to_hex(value,signed=False):
    return value.to_bytes(2,'little',signed=signed).hex()

def intarr_to_hex(intarr,signed):
    return "".join([int_to_hex(i,signed) for i in intarr])

def hex_to_signed(hexval, bits):
    # Convert hex string to integer
    value = int(hexval, 16)
    if value >= (1 << (bits - 1)):
        # subtract 2^bits to get the signed value
        value -= (1 << bits)
    return value

def hexstr_to_4hexarr(hexstr,little=True):
    if little:    
        return [hexstr[i:i+4] for i in range(0,len(hexstr),4)]
    else:
        return [hexstr[i+2:i+4]+hexstr[i:i+2] for i in range(0,len(hexstr),4)]

# splits hex string in fragments of size nhx = {8,16}
# returns a vector with fragments of size nhx. Each fragment has nhx hex values
# reverse byte-wise: "abcdef00" -> "00efcdab"
def split_hex(hexstr,words=True,reverse=True):
    if words:
        nhx = 8 # hex values per word
    else:
        nhx = 16 # hex values per quad
    fragments = [hexstr[i:i+nhx] for i in range(0,len(hexstr),nhx)]
    if reverse: # byte-wise
        byte_fragmented = [[f[i:i+2] for i in range(0,nhx,2)] for f in fragments]
        for i in range(len(byte_fragmented)):
            byte_fragmented[i].reverse()
            fragments[i] = "".join(byte_fragmented[i])
    return fragments

def create_test_target_op(t_A,n):
    output = FrodoKEM_dir + 'tests/test_target_op.s'

    with open(output, 'w') as out:
        out.write('#define xarg0 x10\n')
        out.write('.section .text.start\n')
        out.write('li xarg0, '+t_A+'\n')
        out.write('jal x1, target_op\n')
        out.write('ecall\n')

# creates test for KeyGen, Encaps, Decaps
def create_test_OP(op,t_A,n):
    output = FrodoKEM_dir + 'tests/test_' + op + '.s'

    with open(output, 'w') as out:
        out.write('#define xarg1 x11\n')
        out.write('#define xarg0 x10\n')
        out.write('.section .text.start\n')
        out.write('li xarg1, ' + n + '\n')
        out.write('li xarg0, ' + t_A + '\n')
        out.write('jal x1, ' + op + '\n')
        out.write('ecall\n')

def write_to_section_data(test, vars):
    os.makedirs(FrodoKEM_dir + 'data-auto',exist_ok=True)
    output = FrodoKEM_dir + 'data-auto/data_' + test + '.s'

    header = '.section .data\n'
    balign_label = '.balign 32\n'
    glb_label = '.global '

    with open(output, 'w') as out:
        out.write(header+'\n')
        for var in vars:
            var_name = var[IDXVAR_NAME]
            var_size_bytes = var[IDXVAR_SIZE]
            var_value = var[IDXVAR_VALUE]
            data_type = var[IDXVAR_DTYPE]
            out.write(balign_label)
            out.write(glb_label+var_name+'\n')
            out.write(var_name+':\n')
            if var_value:
                for val in var_value:
                    out.write(f"   .{data_type} 0x{val}\n")
                out.write('\n')
            else:
                out.write(f"   .zero {var_size_bytes}\n\n")    


def parse_mem_dump(vars):
    try:
        with open(memdump,'r') as file:
            dmemhdr = file.read(6)
            with open(parsed_memdump, 'w') as pd:
                for var in vars:
                    var_name = var[IDXVAR_NAME]
                    var_size_bytes = var[IDXVAR_SIZE]                 
                    pd.write(f"{var_name}:\n")
                    pd.write(file.read(var_size_bytes*2))
                    pd.write("\n")
                    # ignore post zeroes
                    rest = var_size_bytes%32
                    if rest:
                        ignore = file.read((32-rest)*2)

    except FileNotFoundError:
        print(f"{BRED}Error{NC}: The file {memdump} was not found.")
        sys.exit(1)
    except Exception as e:
        print(f"An {BRED}error{NC} occurred: {e}")
        sys.exit(1)  

def read_parsed_mem_dump_keygen(vars):
    ch_colon = ':'
    ch_brkln = '\n'
    try:
        with open(parsed_memdump, 'r') as file:
            for var in vars:
                var_name = var[IDXVAR_NAME]
                var_size_bytes = var[IDXVAR_SIZE]
                assert var_name == file.read(len(var_name))
                file.read(len(ch_colon+ch_brkln))
                # assign new value 
                var[IDXVAR_VALUE] = file.read(var_size_bytes*2)
                file.read(len(ch_brkln))
    except FileNotFoundError:
        print(f"{BRED}Error{NC}: The file {parsed_memdump} was not found.")
    except Exception as e:
        print(f"An {BRED}error{NC} occurred: {e}")


def read_parsed_mem_dump_encaps(vars, seclev):
    ch_colon = ':'
    ch_brkln = '\n'
    try:
        with open(parsed_memdump, 'r') as file:
            for var in vars:
                var_name = var[IDXVAR_NAME]
                var_size_bytes = var[IDXVAR_SIZE]
                assert var_name == file.read(len(var_name))
                file.read(len(ch_colon+ch_brkln))
                # assign new value 
                if var_name == "addr_free":
                    if seclev == "640":
                        len_cc = 9752
                        gap = 8
                        len_ss = 16
                        var[IDXVAR_VALUE] = file.read((len_cc+gap+len_ss)*2)
                    elif seclev == "976":
                        len_cc = 15792
                        gap = 16
                        len_ss = 24
                        var[IDXVAR_VALUE] = file.read((len_cc+gap+len_ss)*2)
                    elif seclev == "1344":
                        len_cc = 21696
                        gap = 0
                        len_ss = 32
                        var[IDXVAR_VALUE] = file.read((len_cc+gap+len_ss)*2)
                else:
                    var[IDXVAR_VALUE] = file.read(var_size_bytes*2)
                file.read(len(ch_brkln))
    except FileNotFoundError:
        print(f"{BRED}Error{NC}: The file {parsed_memdump} was not found.")
    except Exception as e:
        print(f"An {BRED}error{NC} occurred: {e}")

def read_parsed_mem_dump_ss(vars, seclev):
    ch_colon = ':'
    ch_brkln = '\n'
    try:
        with open(parsed_memdump, 'r') as file:
            for var in vars:
                var_name = var[IDXVAR_NAME]
                var_size_bytes = var[IDXVAR_SIZE]
                assert var_name == file.read(len(var_name))
                file.read(len(ch_colon+ch_brkln))
                # assign new value
                if var_name == "addr_free":
                    if seclev == "640":
                        var[IDXVAR_VALUE] = file.read(16*2)
                    elif seclev == "976":
                        var[IDXVAR_VALUE] = file.read(24*2)
                    elif seclev == "1344":
                        var[IDXVAR_VALUE] = file.read(32*2)
                else:
                    var[IDXVAR_VALUE] = file.read(var_size_bytes*2)
                file.read(len(ch_brkln))

    except FileNotFoundError:
        print(f"{BRED}Error{NC}: The file {parsed_memdump} was not found.")
    except Exception as e:
        print(f"An {BRED}error{NC} occurred: {e}")

def write_build_data_auto(test):
    ### create/update BUILD file ###
    data_out_dir = FrodoKEM_dir + 'data-auto/'
    data_out_build = data_out_dir + 'BUILD'
    try:
        with open(data_out_build,"x") as build_file:
            build_file.write('### This file is generated automatically ###')
            build_file.write('\nload("//rules:otbn.bzl", "otbn_binary")\n')
            build_file.write('\npackage(default_visibility = ["//visibility:public"])\n')
            build_file.write(f'\notbn_binary(name = "data_{test}", srcs = ["data_{test}.s",])\n')
    except FileExistsError:
        with open(data_out_build,"r+") as build_file:
            exists_test = False
            for line in build_file:
                if f"{test}.s" in line:
                    exists_test = True
                    break
            if not exists_test:
                build_file.write(f'\notbn_binary(name = "data_{test}", srcs = ["data_{test}.s",])\n')
    except FileNotFoundError:
        print(f"{BRED}Error{NC}: The file {data_out_build} was not found.")
        sys.exit(1)
    except Exception as e:
        print(f"An {BRED}error{NC} occurred: {e}")
        sys.exit(1)



def bazel_build(test,n):

    write_build_data_auto(test)

    print("starting BAZEL build ...")

    bazel_target_dir = "//sw/otbn/code-snippets/FrodoKEM/tests:"
    bazel = xotbn_dir + "./bazelisk.sh"
    arg1 = "build"
    arg2 = bazel_target_dir + "test_" + test
    arg3 = "--copt=-DFRODO_N=" + n 

    try:
        subprocess.run(['bash', bazel, arg1, arg2, arg3],cwd=xotbn_dir,check=True)
    except subprocess.CalledProcessError:
        sys.exit(1)

def pysim_otbn(test):
    print("\nstarting OTBN simulation ...")

    os.makedirs(FrodoKEM_dir + 'tmp-out',exist_ok=True)
    sim_standalone = xotbn_dir + 'hw/ip/otbn/dv/otbnsim/standalone.py'

    elf_path = xotbn_dir + 'bazel-bin/sw/otbn/code-snippets/FrodoKEM/tests/test_' + test + '.elf'

    sim_output = FrodoKEM_dir + 'tmp-out/out_' + test

    try:
        with open(sim_output, "w") as out_file:
            subprocess.run([
                "python", sim_standalone, 
                "-v", 
                "--dump-dmem", FrodoKEM_dir + "tmp-out/memdump",
                elf_path
            ], stdout=out_file, check=True)
    except FileNotFoundError:
        print(f"{BRED}Error{NC}: The file {sim_output} was not found.")
        sys.exit(1)
    except subprocess.CalledProcessError:
        sys.exit(1)

    print(f"{BGRN}finished{NC} OTBN simulation")

def input_var(name,hexstr,varsize,words=True,reverse=True,init=True):
    ass_var = name
    ass_var_size_bytes = varsize
    if init:
        var_value = split_hex(hexstr,words,reverse)
        if words:
            data_type = 'word'
        else:
            data_type = 'quad'
    else:
        var_value = None
        data_type = None
    var = list(range(TOTAL_ATTR))
    var[IDXVAR_NAME] = ass_var
    var[IDXVAR_SIZE] = ass_var_size_bytes
    var[IDXVAR_VALUE] = var_value
    var[IDXVAR_DTYPE] = data_type
    return var
    



