/*
* This is the high performance implementation for the target operation B=AS+E 
*
* @param[in]  xarg0: t_A parameter
*
*/

/***
* GPR AND WDR CONVENTION 
* {x0,x1}   : zero and link register
* {x2-x4}   : tmp
* {x5-x9}   : subroutines
* {x10-x14} : args subroutines
* {x15}     : result
* {x16-x19} : subroutines / main routine
* {x20-x31} : main routine
* {w0-w4}   : wtmp
* {w5-w9}   : subroutines
* {w10-w14} : wargs subroutines
* {w15}     : wresult
* {w16-w19} : subroutines
* {w20-w31} : main routine
*
***/

/* lengths in bytes */

#define LEN_PRNDSTR     20480
#define WLEN_PRNDSTR    640 
#define FRODO_N         640
#define LEN_ROWA        1280
#define LEN_MATRIX_S    10240

/* aliases registers */

.equ w31, bn0
#define wones               w30
#define wmask_low_ffff      w29
#define wmask_high_ffff     w28

#define wtmp0               w0

#define xctr_Arows          x31
#define xCONST_640          x30
#define xt_A                x29
#define xaddr_matrix_B      x28

#define xaddr_matrix_A      x26
#define xaddr_buf_sampled   x25
#define idx_wresult         x24  
#define xlen_rowA           x23

/* shake #define xctr_offset  x16 */

#define xarg2           x12
#define xarg1           x11
#define xarg0           x10

.equ x2, t0

.section .text
.global target_op
target_op:

    /***************************** 
    * Setup:
    * Parameters, constants, masks 
    *****************************/
    bn.xor  bn0, bn0, bn0

    li xCONST_640, FRODO_N  
    li xlen_rowA, LEN_ROWA
    li idx_wresult, 15

    /* Masks */
    bn.subi wones, bn0, 1            
    bn.or   wmask_low_ffff, bn0, wones >> 240   
    bn.or   wmask_high_ffff, bn0, wones << 240   

    /* set modulo FRODO_Q in WDR MOD = 2^15 */
    bn.addi wtmp0, bn0, 1
    loopi 15, 1
        bn.add wtmp0, wtmp0, wtmp0 
    bn.wsrw MOD, wtmp0

    /***************************/

    /* Control */
    li  xctr_Arows, 0
    add xt_A, xarg0, x0 

    /* 
    * Generation of pseudorandom bit string  
    */

    jal     x1, ctx_gen_prndstr

    li      xarg0, LEN_PRNDSTR
    li      xarg1, 0
    jal     x1, gen_prndstr 

    /* 
    * Sample error matrix S_T 
    */

    la      xarg0, buf_sampled
    li      xarg1, WLEN_PRNDSTR 
    la      xarg2, buf_sampled
    jal     x1, inverse_sampler

    /* Generate seed_A */

    jal     x1, gen_seedA

    /******* B = AS *******/
    la xaddr_matrix_B, matrix_B
    la xaddr_buf_sampled, buf_sampled

    multiply_on_the_fly:
        
        add xarg0, xt_A, x0    
        jal x1, genA

        la  xaddr_matrix_A, matrix_A
        jal x1, matrix_matrix_mult # A*S

        add xctr_Arows, xctr_Arows, xt_A
        bne xCONST_640, xctr_Arows, multiply_on_the_fly

    /******* B = B + E *******/
    la      xaddr_matrix_B, matrix_B
    add     xarg0, xaddr_matrix_B, x0

    li      t0, LEN_MATRIX_S
    la      xaddr_buf_sampled, buf_sampled
    add     xarg1, xaddr_buf_sampled, t0 # offset to matrix E

    li      xarg2, 320 # WLEN chunks to add
    jal     x1, matrix_matrix_add

ret

