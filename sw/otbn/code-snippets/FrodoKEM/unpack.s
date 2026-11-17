/**
* The function 𝑃𝑎𝑐𝑘 transforms an 𝑛1 × 𝑛2 matrix C in ℤ𝑞 to a byte array. Concretely, it extracts the least
significant 𝐷 bits from each matrix coefficient, reading the matrix row-by-row from least to most
significant coefficient, and concatenates them to produce a bit-string
*/

## global defines - defined by top file ##

#define xresult             x15
#define xarg2               x12
#define xarg1               x11
#define xarg0               x10

#define wmask_low_ffff      w29
#define wmask_high_ffff     w28

#define idx_wresult         x24

#define wresult             w15
#define wtmp1               w1
#define wtmp0               w0

## ------------------------------------ ##

## local defines ##
#define xaddr_unpack       x18
#define xaddr_pack         x17

#define xaddr_mask_byte    x14
#define xctr_glo           x13

#define xaddr_mask_msb     x9
#define xctr               x8
#define xCONST_16          x7
#define idx_wcoeffs        x6
#define xone               x5
#define xctr_loads         x4

#define wmask_ffff      w13
#define wbuffer         w12
#define wmask_hex       w11
#define wmask_byte      w10

#define wswapped            w9
#define wmask_msb           w8
#define wmsb                w7
#define wcoeff              w6
#define wcoeffs             w5
#define wmask_one           w4
#define wmask_high_fffe     w3
#define wcoeff_left         w2

## -------------- ##

.equ w31, bn0

.equ x2, t0
.equ x3, t1

/*
 * Name:    UnPack
 *
 * Description: transforms a matrix into its byte-array representation leaving out the MSb (d=15) of each matrix coefficient.
 *
 */


/**
* @param[in]  xarg0: length of packed matrix - bytes
* @param[in]  xarg1: packed matrix address
* @param[out] xarg2: unpacked matrix address
* clobbered registers: {x4-x15,x17,18},{w2-w9}
* clobbered registers subroutines: {},{}
*
*/

.section .text
.global unpack
unpack:

add xaddr_unpack, xarg2, x0

la xaddr_mask_msb, mask_msb
bn.lid x0, 0(xaddr_mask_msb)
bn.mov wmask_msb, wtmp0

la xaddr_mask_byte, mask_byte
bn.lid x0, 0(xaddr_mask_byte)
bn.mov wmask_byte, wtmp0

#if (FRODO_N == 640)

unpacking_640_xFrodoN:

li xCONST_16, 16
li idx_wcoeffs, 5 # w5
addi xone, x0, 1

bn.shv.16H wmask_high_fffe, wmask_high_ffff << 1

li xctr, 0
li xctr_glo, 0
li xctr_loads, 0

bn.addi wmask_one, bn0, 1

bn.rshi wmask_one, wmask_one, bn0 >> 16

add xaddr_pack, xarg1, x0

la xaddr_mask_byte, mask_byte
bn.lid x0, 0(xaddr_mask_byte)
bn.mov wmask_byte, wtmp0

load_packed_wchunk:

    bn.lid idx_wcoeffs, 0(xaddr_pack++)

    addi xctr_loads, xctr_loads, 1

    /* swap entries for a "BIG ENDIAN" representation to ease data processing */
    bn.mov wtmp1, bn0
    loopi 16,4
        bn.or wtmp1, bn0, wtmp1 << 16
        bn.and wcoeff, wcoeffs, wmask_low_ffff
        bn.or wtmp1, wtmp1, wcoeff
        bn.or wcoeffs, bn0, wcoeffs >> 16

    /* Byte swapping */
    bn.and wcoeffs, wtmp1, wmask_byte # xx00xx00..
    bn.or wcoeffs, bn0, wcoeffs >> 8 # 00xx00xx..

    bn.or wmask_byte, bn0, wmask_byte >> 8 # 00ff00ff..
    bn.and wtmp0, wtmp1, wmask_byte # 00xx00xx..
    bn.or wtmp0, bn0, wtmp0 << 8 # xx00xx00..
    bn.or wcoeffs, wcoeffs, wtmp0

    bn.or wmask_byte, bn0, wmask_byte << 8 # ff00ff00..

    li t1, 15
    sub xctr_loads, xctr_loads, t1
    slli t0, xone, 31
    and t0, t0, xctr_loads
    beq x0, t0, check_zero_cond
    add xctr_loads, xctr_loads, t1
    check_zero_cond:
    bne x0, xctr_loads, check_one_cond
    add xctr_loads, xctr_loads, t1
    check_one_cond:
    beq xone, xctr_loads, expand_coeff_wise

    /* Append coeffs from buffer to loaded packed coeffs */
    sub xctr_loads, xctr_loads, xone
    loop xctr_loads, 6
        bn.and wtmp0, wcoeffs, wmask_low_ffff
        /* append wtmp0 to buffer */
        loop xctr_loads, 1
            bn.or wtmp0, bn0, wtmp0 << 16
        bn.or wbuffer, wbuffer, wtmp0
        bn.rshi wcoeffs, wbuffer, wcoeffs >> 16
        bn.or wbuffer, bn0, wbuffer >> 16
    add xctr_loads, xctr_loads, xone

    expand_coeff_wise:

        bn.and wcoeff, wcoeffs, wmask_high_fffe

        bn.shv.16H wcoeff, wcoeff >> 1

        bn.or wcoeff, bn0, wcoeff >> 240

        bn.rshi wresult, wcoeff, wresult >> 16

        bn.and wtmp0, wcoeffs, wmask_one

        bn.or wtmp0, bn0, wtmp0 >> 240

        /* shift out 16 bits and put back lost bit */

        bn.or wcoeffs, bn0, wcoeffs << 16

        bn.rshi wcoeffs, wtmp0, wcoeffs >> 1

        addi xctr, xctr, 1

        bne xCONST_16, xctr, expand_coeff_wise 

    /*--------------------------------------------*/ 

    li xctr, 0   

    bn.or wcoeffs, bn0, wcoeffs >> 240

    /* Append coeff left from expansion to buffer */

    sub xctr_loads, xctr_loads, xone
    beq x0, xctr_loads, skip_loop
    loop xctr_loads, 1
        bn.or wcoeffs, bn0, wcoeffs << 16
    skip_loop:
    bn.or wbuffer, wbuffer, wcoeffs
    add xctr_loads, xctr_loads, xone

    bn.sid idx_wresult, 0(xaddr_unpack++)

    bn.mov wresult, bn0


    li t1, 15
    bne t1, xctr_loads, next_wchunk

    /* Expand buffer */
    bn.or wbuffer, bn0, wbuffer << 16
    bn.mov wcoeffs, wbuffer
    bn.mov wbuffer, bn0

    expand_buffer:

        bn.and wcoeff, wcoeffs, wmask_high_fffe

        bn.shv.16H wcoeff, wcoeff >> 1

        bn.or wcoeff, bn0, wcoeff >> 240

        bn.rshi wresult, wcoeff, wresult >> 16

        bn.and wtmp0, wcoeffs, wmask_one

        bn.or wtmp0, bn0, wtmp0 >> 240

        /* shift out 16 bits and put back lost bit */

        bn.or wcoeffs, bn0, wcoeffs << 16

        bn.rshi wcoeffs, wtmp0, wcoeffs >> 1

        addi xctr, xctr, 1

        bne xCONST_16, xctr, expand_buffer 

    /*--------------------------------------------*/ 
    li xctr, 0
    li xctr_loads, 0

    bn.sid idx_wresult, 0(xaddr_unpack++)

    bn.mov wresult, bn0

    next_wchunk:
    addi xctr_glo, xctr_glo, 32 # ... 
    bne xarg0, xctr_glo, load_packed_wchunk

/*--------------------------------------------*/

ret

#else

unpacking_976_1344_xFrodoN:

    add xarg0, xarg0, x0
    jal x1, wlen_equivalent

    loop xresult, 11
        bn.lid x0, 0(xarg1++)
        bn.mov wcoeffs, wtmp0

        /* Byte swapping */
        bn.and wswapped, wcoeffs, wmask_byte # xx00xx00..
        bn.or wswapped, bn0, wswapped >> 8 # 00xx00xx..

        bn.or wmask_byte, bn0, wmask_byte >> 8 # 00ff00ff..
        bn.and wtmp0, wcoeffs, wmask_byte # 00xx00xx..
        bn.or wtmp0, bn0, wtmp0 << 8 # xx00xx00..
        bn.or wswapped, wswapped, wtmp0

        bn.or wmask_byte, bn0, wmask_byte << 8 # ff00ff00..

        bn.mov wresult, wswapped
        bn.sid idx_wresult, 0(xaddr_unpack++)

    nop

ret

#endif


    

