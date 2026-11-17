/**
* The function 𝑃𝑎𝑐𝑘 transforms an 𝑛1 × 𝑛2 matrix C in ℤ𝑞 to a byte array. Concretely, it extracts the least
significant 𝐷 bits from each matrix coefficient, reading the matrix row-by-row from least to most
significant coefficient, and concatenates them to produce a bit-string
*/



## global defines - defined by top file ##

#define xFRODO_N          x30


#define idx_wresult         x24

#define xresult             x15

#define xarg2               x12
#define xarg1               x11
#define xarg0               x10

#define wmask_low_ffff      w29
#define wmask_high_ffff     w28
#define wresult             w15
#define wtmp1               w1
#define wtmp0               w0

## ------------------------------------ ##

## local defines ##
#define xaddr_pack          x17


#define xaddr_mask_byte     x14
#define xglo_ctr            x13

#define xaddr_mask_msb      x9
#define xctr                x8
#define xCONST_16           x7
#define idx_wcoeffs         x6
#define xsto_ctr            x5

#define wmask_hex           w11
#define wmask_byte          w10
#define wswapped            w9
#define wmask_msb           w8
#define wmsb                w7
#define wcoeff              w6
#define wcoeffs             w5

## -------------- ##

.equ w31, bn0

.equ x2, t0
.equ x3, a1
.equ x4, a2

/*
 * Name:    Pack
 *
 * Description: transforms a matrix into its byte-array representation leaving out the MSb (d=15) of each matrix coefficient.
 *
 */


/**
* @param[in]  xarg0: length of matrix - bytes
* @param[in]  xarg1: matrix address
* @param[out]  xarg2: packed matrix address
*
* clobbered registers: {x5-x14,x17},{w5-w11}
* clobbered registers subroutines: {},{}
*
*/

.section .text
.global pack
pack:
    bn.mov wresult, bn0
    
    la xaddr_mask_msb, mask_msb
    bn.lid x0, 0(xaddr_mask_msb)
    bn.mov wmask_msb, wtmp0

    la xaddr_mask_byte, mask_byte
    bn.lid x0, 0(xaddr_mask_byte)
    bn.mov wmask_byte, wtmp0

    li t0, 640
    bne t0, xFRODO_N, packing_976_1344_xFrodoN

packing_640_xFrodoN:

    li t0, 128
    bne t0, xarg0, big_pack
    li a1, 4
    li a2, 4
    jal x0, calculate_compressed_size
    big_pack:
    li a1, 15
    li a2, 16

    calculate_compressed_size:
    srli t0, xarg0, 1 # nr of coefficients {n*nbar, nbar*nbar} = nr of bits we wanna get rid of
    srli t0, t0, 3 # total in bytes 

    sub xarg0, xarg0, t0 # size of compressed matrix

    
    li xCONST_16, 16
    li idx_wcoeffs, 5 # w5

    add xaddr_pack, xarg2, x0

    li xglo_ctr, 0
    li xsto_ctr, 0
/* Loads 32 bytes of uncompressed coeffs */
load_wchunk:
    li xctr, 0

    bn.lid idx_wcoeffs, 0(xarg1)

    bn.shv.16H wcoeffs, wcoeffs << 1

    /* swap entries for a "BIG ENDIAN" representation */
    bn.mov wtmp1, bn0
    loopi 16,4
        bn.or wtmp1, bn0, wtmp1 << 16
        bn.and wcoeff, wcoeffs, wmask_low_ffff
        bn.or wtmp1, wtmp1, wcoeff
        bn.or wcoeffs, bn0, wcoeffs >> 16
    bn.mov wcoeffs, wtmp1
/* Compresses the 16 coeffs inside WDR */
compress:
    bn.or wresult, bn0, wresult << 16

    bn.and wmsb, wmask_msb, wcoeffs
    /* the next two ops are equiv. to wdr << 1 */
    bn.shv.16H wmsb, wmsb >> 7 
    bn.or wmsb, bn0, wmsb << 8

    bn.or wcoeffs, wcoeffs, wmsb

    /* save coeff */
    bn.and wcoeff, wcoeffs, wmask_high_ffff
    bn.or wcoeff, bn0, wcoeff >> 240
    bn.or wresult, wresult, wcoeff

    /* remove coeff */
    bn.or wcoeffs, bn0, wcoeffs << 16 
    bn.shv.16H wcoeffs, wcoeffs << 1

    addi xctr, xctr, 1
    bne xCONST_16, xctr, compress
/* ----------------------------------- */
    li xctr, 0 # reset

    /* Byte swapping */
    bn.and wswapped, wresult, wmask_byte # xx00xx00..
    bn.or wswapped, bn0, wswapped >> 8 # 00xx00xx..

    bn.or wmask_byte, bn0, wmask_byte >> 8 # 00ff00ff..
    bn.and wtmp0, wresult, wmask_byte # 00xx00xx..
    bn.or wtmp0, bn0, wtmp0 << 8 # xx00xx00..
    bn.or wswapped, wswapped, wtmp0

    bn.or wmask_byte, bn0, wmask_byte << 8 # ff00ff00..

    /* Coeffs swapping */
    bn.mov wresult, bn0
    loopi 16,4
        bn.or wresult, bn0, wresult << 16
        bn.and wcoeff, wswapped, wmask_low_ffff
        bn.or wresult, wresult, wcoeff
        bn.or wswapped, bn0, wswapped >> 16

    bn.sid idx_wresult, 0(xarg1++)
    addi xsto_ctr, xsto_ctr, 1
    bne a2, xsto_ctr, load_wchunk # <--- HARD CODED! DOES NOT APPLY FOR PACK(C). THERE WE ONLY HAVE TO COMPRESS 4 WDR AND PACKED MATRIX HAS 120 BYTES WHICH IS NOT DIVISIBLE BY 32
/* ----------------------------------- */
    /* Until this point we have compressed 16 WDRs = 16*32 = 512 bytes.
    * But DMEM has x16-bit voids from the last coeff of each compressed WDR.
    * Now, we will compress the data previously stored in DMEM to fill those voids.
    */
    li xsto_ctr, 0 # reset
    li t0, 4
    bne t0, a1, sub_big
    li t0, 128 # 32*4 = 128 bytes
    sub xarg1, xarg1, t0  
    jal x0, update_last_coeff
    sub_big:
    li t0, 512 # 32*16 = 512 bytes
    sub xarg1, xarg1, t0

update_last_coeff:
    bn.lid idx_wcoeffs, 0(xarg1++)
    bn.lid x0, 0(xarg1)
    addi xsto_ctr, xsto_ctr, 1
    addi xglo_ctr, xglo_ctr, 32

    loop xsto_ctr, 6
        bn.and wcoeff, wtmp0, wmask_low_ffff
        bn.or wcoeff, bn0, wcoeff << 240
        bn.or wcoeffs, wcoeffs, wcoeff
        bn.or wtmp0, bn0, wtmp0 >> 16
        bn.and wtmp1, wcoeffs, wmask_low_ffff
        bn.or wcoeffs, bn0, wcoeffs >> 16
    /* places back last lost coeff */
    bn.or wcoeffs, bn0, wcoeffs << 16
    bn.or wcoeffs, wcoeffs, wtmp1

    bn.mov wresult, wcoeffs

    bn.sid idx_wresult, 0(xaddr_pack++)

    bne a1, xsto_ctr, update_last_coeff
/* ----------------------------------- */
    addi xarg1, xarg1, 32

    li xsto_ctr, 0 # reset
    li t0, 4
    bne t0, a1, bne_big
    li t0, 128 # 32*4 = 128 bytes
    bne t0, xglo_ctr, load_wchunk
    jal x0, finished
    bne_big:
    bne xarg0, xglo_ctr, load_wchunk # <--- DOES NOT APPLY FOR PACK(C). PACKED MATRIX HAS 120 BYTES WHICH IS NOT DIVISIBLE BY 32
/* ----------------------------------- */
    finished:
    nop

ret

packing_976_1344_xFrodoN:

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
        bn.sid idx_wresult, 0(xarg2++)

    nop

ret


    

