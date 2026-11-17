/* lengths in bytes */
#define LEN_CTR_SEED               18

## global defines - defined by top file ##
#define wseedA              w27
#define wctr_Agen           w26

# #define xFRODO_N            x30
#define xaddr_free          x21

#define xresult             x15
#define xarg2               x12
#define xarg1               x11
#define xarg0               x10

#define wtmp0               w0

## ------------------------------------ ##

## local defines ##
#define xaddr_wb            x8
#define xaddr_out           x7
#define xgen_rows           x6
#define xwlen_rowA          x5
## -------------- ##

.equ x2, t0
.equ w31, bn0

/*
 * Name:    genA
 *
 * Description: generates [xarg0] rows of the matrix A.
 *
 * Flags: Clobbers FG0
 *
 * @param[in]  xarg0: nr of rows to generate 
 * @param[out] xarg1: ptr to output buffer

 * clobbered registers: {x5-x8},{w26,w27}
 * clobbered registers subroutines: {},{}
 * 
 */

.section .text
.global genA
genA:
    add xgen_rows, xarg0, x0
    add xaddr_out, xarg1, x0

    #if (FRODO_N == 640)
    li xwlen_rowA, 40
    #elif (FRODO_N == 976)
    li xwlen_rowA, 61
    #else
    li xwlen_rowA, 84
    #endif

    # slli xarg0, xFRODO_N, 1 # n*2 bytes
    # jal x1, wlen_equivalent
    # add xwlen_rowA, xresult, x0

    loop xgen_rows, 17
        /* set b = counter || seed_A */
        bn.add wtmp0, bn0, wseedA << 16
        bn.or  wtmp0, wctr_Agen, wtmp0 

        add xaddr_wb, xaddr_free, x0
        bn.sid  x0,  0(xaddr_wb) 

        li      xarg0, LEN_CTR_SEED
        add     xarg1, xaddr_wb, x0
        li      xarg2, 0 # use SHAKE128
        jal     x1, ctx_shake

        /* Generates one full row */

        add     xarg0, xwlen_rowA, x0
        li      xarg1, 0
        add     xarg2, xaddr_out, x0
        jal     x1, squeeze_shake

        /* Modular reduction of all elements in generated row */
        loop xwlen_rowA, 3
            bn.lid       x0, 0(xaddr_out) 
            bn.addvm.16H wtmp0, bn0, wtmp0
            bn.sid       x0, 0(xaddr_out++)

        /* Update rows counter */
        bn.addi wctr_Agen, wctr_Agen, 1
        nop 
    
    ret

