
#define FRODO_NBAR 8

## global defines - defined by top file ##
#define wones               w30
#define wmask_low_ffff      w29

#define wresult             w15

#define xFRODO_N            x30
#define idx_wresult         x24

#define xarg2               x12
#define xarg1               x11
#define xarg0               x10

#define wtmp1               w1
#define wtmp0               w0

## ------------------------------------ ##

#define wacc                w7
#define wcoeffs_matrix_S_   w6
#define wcoeff_exp          w5

## local defines ##
#define xaddr_matrix_out x9
#define xaddr_matrix_S_ x8
#define xaddr_matrix_B x7
#define xctr_Brows x6
#define xBOOL x5

## -------------- ##

.equ x2, t0
.equ w31, bn0

/*
 *
 * Description: multiplies S'B.
 *
 * Flags: Clobbers FG0
 * @param[in]  xarg0: ptr to matrix S
 * @param[in]  xarg1: ptr to matrix B
 * @param[out] xarg2: ptr to output matrix
 * clobbered registers: {},{}
 * clobbered registers subroutines: {},{}
 * 
 */

.section .text
.global mult_SB
mult_SB:

#if (FRODO_N == 640)
li xFRODO_N, 640
#elif (FRODO_N == 976)
li xFRODO_N, 976
#else
li xFRODO_N, 1344
#endif

add xaddr_matrix_S_, xarg0, x0
add xaddr_matrix_B, xarg1, x0
/* Clean output space */
add t0, xarg2, x0
bn.mov wresult, bn0
loopi 4, 1 # 128 bytes
    bn.sid idx_wresult, 0(t0++)

add xaddr_matrix_out, xarg2, x0


bn.mov wacc, bn0
li xBOOL, 0 # controls when we store computations

/** loop through S' rows **/
loopi FRODO_NBAR, 28

    li xctr_Brows, 0

    load_sampled_coeffs:

    bn.lid x0, 0(xaddr_matrix_S_++)
    bn.mov wcoeffs_matrix_S_, wtmp0

    /*** expand and multiply ***/
    loopi 8, 14 
        bn.and wtmp1, wcoeffs_matrix_S_, wmask_low_ffff # 0x0..0||s
        bn.rshi wcoeffs_matrix_S_, bn0, wcoeffs_matrix_S_ >> 16
        bn.rshi wcoeff_exp, wtmp1, bn0 >> 16
        loopi 7,1
            bn.rshi wcoeff_exp, wtmp1, wcoeff_exp >> 16 # s||s||..||s||0x0..0
        bn.and wtmp1, wcoeffs_matrix_S_, wmask_low_ffff # 0x0..0||s
        bn.rshi wcoeffs_matrix_S_, bn0, wcoeffs_matrix_S_ >> 16
        loopi 8,1
            bn.rshi wcoeff_exp, wtmp1, wcoeff_exp >> 16 # s1||s1||..||s1||s0||s0||...||s0
        bn.lid x0, 0(xaddr_matrix_B++)
        bn.mulv.16H wresult, wcoeff_exp, wtmp0
        bn.lid x0, 0(xaddr_matrix_out)
        bn.addvm.16H wresult, wresult, wtmp0 # adds result to previous values
        bn.sid idx_wresult, 0(xaddr_matrix_out)

    addi xctr_Brows, xctr_Brows, 16
    bne xFRODO_N, xctr_Brows, load_sampled_coeffs

    /*** Last required addition to finish row computation ***/
    bn.rshi wtmp0, bn0, wones >> 128 # mask lower half wlen
    bn.and wtmp1, wresult, wtmp0
    bn.rshi wtmp0, bn0, wresult >> 128
    bn.addvm.16H wresult, wtmp0, wtmp1
    bn.rshi wacc, wresult, wacc >> 128

    jal x1, fn_store_results

    slli t0, xFRODO_N, 4 # size B
    sub xaddr_matrix_B, xaddr_matrix_B, t0

ret

fn_store_results:
    /* we store only every 32B computed == 2 V' rows */
    beq x0, xBOOL, skip_store
    store: 
        bn.mov wresult, wacc
        bn.sid idx_wresult, 0(xaddr_matrix_out++)
        li xBOOL, 0 # reset
        ret
    skip_store:
        li xBOOL, 1 # set
        bn.mov wresult, bn0
        bn.sid idx_wresult, 0(xaddr_matrix_out)
        ret






 