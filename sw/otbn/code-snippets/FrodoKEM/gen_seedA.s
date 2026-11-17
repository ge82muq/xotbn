#define LEN_A 16

/* Register aliases */
.equ x2, t0
.equ w31, bn0

#define xaddr_free          x21


#define xresult         x15

#define xarg2           x12
#define xarg1           x11
#define xarg0           x10

#define xaddr_seed_A    x5

#define wones           w30
#define wseedA          w27

#define wmask_lowhalf   w5

#define wtmp0           w0

/*
 * Description: generatates seed_A from input seed_z by extracting pseudorandomness from SHAKE.
 *
 * clobbered registers: {x5,x21},{w5,w27}
 * clobbered registers subroutines: {x16,x21},{}

 */

.section .text
.global gen_seedA
gen_seedA:

    li      xarg0, LEN_A
    la      xarg1, seed_z
    li      xarg2, 1 # seedA uses SHAKE256
    jal     x1, ctx_shake

    add     xaddr_seed_A, xaddr_free, x0

    li      xarg0, 1 
    li      xarg1, 0
    add     xarg2, xaddr_seed_A, x0
    jal     x1,  squeeze_shake  

    /* save seedA locally */
    bn.lid x0, 0(xaddr_seed_A)
    # only the lowest 16 bytes are valid
    bn.rshi wmask_lowhalf, bn0, wones >> 128
    bn.and  wseedA, wtmp0, wmask_lowhalf

    /* free data */
    li t0, 32
    sub xaddr_free, xaddr_free, t0

    ret


