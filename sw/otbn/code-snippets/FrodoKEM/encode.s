
## global defines - defined by top file ##

#define idx_wresult         x24
#define xarg2               x12
#define xarg1               x11
#define xarg0               x10

#define wresult             w15
#define wtmp0               w0

## ------------------------------------ ##

## local defines ##
#define xCONST4         x9
#define xu_rnd_enc      x8
#define xD              x7
#define xB              x6
#define xCONST16        x5

#define wk_int          w8
#define wmask_B         w7
#define wone_bit        w6
#define wu_rnd          w5
## -------------- ##

.equ w31, bn0

.equ x2, t0

/*
 * Name:    Encode
 *
 * Description: Encodes bit string into matrix
 *
 */


/**
* @param[in]  xarg0: length of bit string - bytes
* @param[in]  xarg1: address bit string 
* @param[out] xarg2: address output matrix
* clobbered registers: {x5-x8,x10,x11,x24},{w5-w8,w15}
* clobbered registers subroutines: {},{}
*
*/

.section .text
.global encode
encode:
li xCONST4, 4
li xCONST16, 16

bne xCONST16, xarg0, set_high_seclev
li xD, 15
jal x0, skip_high_seclev
set_high_seclev:
li xD, 16

skip_high_seclev:
srli xB, xarg0, 3

bn.lid x0, 0(xarg1)
bn.mov wu_rnd, wtmp0

add xu_rnd_enc, xarg2, x0

bn.addi wone_bit, bn0, 1

bn.mov wmask_B, bn0

loop xB, 2
    bn.or wmask_B, wmask_B, wone_bit
    bn.shv.16H wone_bit, wone_bit << 1

loopi 4, 11 # bit string is encoded into a 8*8 matrix with 2-byte entries = 128 bytes. => 4 bn.stores
    bn.mov wresult, bn0
    loopi 16, 8 # we can put at most 16 encoded bits per WDR
        bn.and wk_int, wu_rnd, wmask_B
        beq xCONST4, xB, shift_less
        bn.shv.16H wk_int, wk_int << 13
        shift_in:
        bn.rshi wresult, wk_int, wresult >> 16
        discard_bits:
        li t0, 2
        bne t0, xB, seclev2
        bn.rshi wu_rnd, bn0, wu_rnd >> 2
        do_nop:
        nop
    bn.sid idx_wresult, 0(xu_rnd_enc++)

ret

shift_less:
    bn.shv.16H wk_int, wk_int << 12
    jal x0, shift_in

seclev2:
    addi t0, t0, 1
    bne t0, xB, seclev3
    bn.rshi wu_rnd, bn0, wu_rnd >> 3
    jal x0, do_nop
    seclev3:
        addi t0, t0, 1
        bne t0, xB, do_nop
        bn.rshi wu_rnd, bn0, wu_rnd >> 4
        jal x0, do_nop
    


    

