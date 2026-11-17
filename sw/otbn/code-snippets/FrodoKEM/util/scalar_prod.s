#define xresult             x15

#define xarg2               x12
#define xarg1               x11
#define xarg0               x10

#define wresult             w15
#define warg0               w10

#define wtmp2                w2
#define wtmp1                w1
#define wtmp0                w0

.equ x2, t0
.equ x3, t1
.equ x4, t2

.equ w31, bn0

/*
 * Name:    scalar_prod
 *
 * Description: 
 * - modular scalar product between two large vectors splitted in [multiple > 1] WDLEN chunks  
 * - vector entries are 16-bit large 
 * Flags: Clobbers FG0
 *
 * @param[in]  xarg0: pointer to vector v1 - 32 byte aligned
 * @param[in]  xarg1: pointer to vector v2 - 32 byte aligned
 * @param[in]  xarg2: length of vectors - bytes
 * @param[out]  wresult: result stored in the lowest 16 bit of WREG
 *
 * clobbered registers: {x2-x4,x10-x12,x15}, {w0-w2,w10,w15}
 * clobbered registers subroutines: {x2,x10,x15},{w0,w10,w15,w29}
 */

.section .text
.global scalar_prod
scalar_prod:

    bn.mov wresult, bn0 # init result WREG

    add t1, x0, xarg0
    add t2, x0, xarg1

    add xarg0, x0, xarg2
    jal x1, wlen_equivalent

    # xresult == nr of wlen chunks
    li t0, 1
    loop xresult, 4
        bn.lid x0, 0(t1++)
        bn.lid t0, 0(t2++)
        bn.mulv.16H wtmp2, wtmp0, wtmp1
        bn.addv.16H wresult, wresult, wtmp2
        
    bn.mov warg0, wresult
    jal x1, internal_vadd

    ret






