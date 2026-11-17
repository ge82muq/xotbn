
## global defines - defined by top file ##
#define xarg0               x10

#define wresult             w15

## ------------------------------------ ##

.equ w31, bn0

/*
 * Name:    Decode
 *
 * Description: Decodes encoded bit string in 16 (n=640), 24 (n=976) or 32 (n=1344) bytes.
 *
 */


/**
* @param[in]  xarg0: address of encoded bit string 
* @param[out] wresult: wlen register with decoded matrix
* clobbered registers: {x10},{w0,w5,w6,w15}
* clobbered registers subroutines: {},{}
*
*/

.section .text
.global decode
decode:

#if (FRODO_N == 640)
# D = 15
# B = 2
#define MASK_B 2
# D-B = 13
#define SHIFT_BITS 13 
bn.addi w5, bn0, 1
# loop (D-B-1) times to compute pow(2, D-B-1)
loopi 12, 1
    bn.add w5, w5, w5

#elif (FRODO_N == 976)
# D = 16
# B = 3
#define MASK_B 3
# D-B = 13
#define SHIFT_BITS 13 
bn.addi w5, bn0, 1
# loop (D-B-1) times to compute pow(2, D-B-1)
loopi 12, 1
    bn.add w5, w5, w5

#else
# D = 16
# B = 4
#define MASK_B 4
# D-B = 12
#define SHIFT_BITS 12 
bn.addi w5, bn0, 1
# loop (D-B-1) times to compute pow(2, D-B-1)
loopi 11, 1
    bn.add w5, w5, w5

#endif

# parallelize pow(2, D-B-1)
bn.mov w6, bn0
loopi 16, 1
    bn.rshi w6, w5, w6 >> 16

bn.mov wresult, bn0
loopi 4, 7 # Encoded(bit string) is always a (8*8) matrix with 2 bytes @entry = 128 bytes
    bn.lid x0, 0(xarg0++)
    bn.addv.16H w0, w0, w6
    bn.shv.16H w0, w0 >> SHIFT_BITS
    loopi 16, 2
        bn.rshi wresult, w0, wresult >> MASK_B
        bn.rshi w0, bn0, w0 >> 16
    nop    

#if (FRODO_N == 640)
bn.rshi wresult, bn0, wresult >> 128
#elif (FRODO_N == 976)
bn.rshi wresult, bn0, wresult >> 64
#else
nop
#endif
    

ret







    


    

