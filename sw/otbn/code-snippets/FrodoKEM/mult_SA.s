
#define FRODO_NBAR 8

## global defines - defined by top file ##
#define wones               w30
#define wmask_low_ffff      w29
#define wseedA              w27
#define wctr_Agen           w26

#define wresult             w15

#define xctr_Arows          x31
#define xFRODO_N            x30
#define xt_A                x29
#define xaddr_out_mult      x27
#define xaddr_matrix_A      x26
#define xaddr_buf_sampled   x25
#define idx_wresult         x24
#define xctr_Brows          x23
#define xaddr_free          x21

#define xresult             x15
#define xarg2               x12
#define xarg1               x11
#define xarg0               x10

#define wtmp1               w1
#define wtmp0               w0

## ------------------------------------ ##

#define wcoeffs_matrix_S_   w6
#define wcoeff_exp          w5

## local defines ##
# clobbered x6,x7,x8
## -------------- ##

.equ x2, t0
.equ x3, t1
.equ x4, t2
.equ w31, bn0

/*
 *
 * Description: multiplies S'A.
 *
 * Flags: Clobbers FG0
 *
 * @param[in]  xarg0:  
 * @param[out] xarg1: 

 * clobbered registers: {},{}
 * clobbered registers subroutines: {},{}
 * 
 */

.section .text
.global mult_SA
mult_SA:
/* Code for compatibility */
#if (FRODO_N == 640)
li xFRODO_N, 640
#elif (FRODO_N == 976)
li xFRODO_N, 976
#else
li xFRODO_N, 1344
#endif
li xctr_Brows, 0
/* Code for compatibility */

next_Brow:

    bn.mov wctr_Agen, bn0

    li xctr_Arows, 0

    gen_Ablock:

    add xarg0, xctr_Arows, x0
    jal x1, fn_check_if_multiple

    bne x0, xresult, skip_coeff_loading
    
    bn.lid x0, 0(xaddr_buf_sampled++)
    bn.mov wcoeffs_matrix_S_, wtmp0

    skip_coeff_loading:

    add xarg0, xt_A, x0
    add xarg1, xaddr_matrix_A, x0    
    jal x1, genA

    add x6, xaddr_matrix_A, x0
    li x8, 0 # ctr for rows of A multiplied
                    
    expand_and_multiply: # !! xt_A max = 16 and 16 shall be divisible by xt_A !!
        bn.and wtmp1, wcoeffs_matrix_S_, wmask_low_ffff # 0x0..0||s
        bn.rshi wcoeffs_matrix_S_, bn0, wcoeffs_matrix_S_ >> 16
        bn.rshi wcoeff_exp, wtmp1, bn0 >> 16
        loopi 15,1
            bn.rshi wcoeff_exp, wtmp1, wcoeff_exp >> 16 # s||s||..||s
        /* 
        * Multiply coeff against all coeffs in the current A row.
        * Store result in B.
        */
        slli x7, xFRODO_N, 1 # len rowA bytes
        srli x7, x7, 5 # len rowA in wlen chunks
        loop x7, 5
            bn.lid x0, 0(x6++)
            bn.mulv.16H wresult, wtmp0, wcoeff_exp # s||s||..||s * a16||a15||...||a1
            bn.lid x0, 0(xaddr_out_mult)
            bn.addvm.16H wresult, wresult, wtmp0 # adds result to previous values
            bn.sid idx_wresult, 0(xaddr_out_mult++)
        addi x8, x8, 1 
        slli t0, x7, 5 # len rowB bytes
        sub xaddr_out_mult, xaddr_out_mult, t0 # reset storage ptr to the beginning of the current B row 
        bne xt_A, x8, expand_and_multiply
    /* free used space from A: required for new genA call */
    add xaddr_free, xaddr_matrix_A, x0
    
    add xctr_Arows, xctr_Arows, xt_A # total rows

    bne xFRODO_N, xctr_Arows, gen_Ablock

    addi xctr_Brows, xctr_Brows, 1

    slli t0, x7, 5 # len rowB bytes
    add xaddr_out_mult, xaddr_out_mult, t0

    li t0, FRODO_NBAR

    bne t0, xctr_Brows, next_Brow

ret

/*
* xarg0: value to check if multiple of 16
*/
fn_check_if_multiple:
    li t0, 16 
    li t1, 1
    slli t1, t1, 31 # msb_mask
    beq x0, xarg0, it_is_multiple
    reduce:
        sub xarg0, xarg0, t0
        beq x0, xarg0, it_is_multiple
        and t2, xarg0, t1
        beq x0, t2, reduce # checks sign bit
    it_is_not_multiple:
    li xresult, 1
    ret
    it_is_multiple:
    li xresult, 0
    ret
