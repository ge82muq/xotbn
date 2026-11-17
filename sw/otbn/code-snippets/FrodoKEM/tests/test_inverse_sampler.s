.equ w31, bn0

#define wones           w30

#define idx_wresult     x24

#define xarg2           x12
#define xarg1           x11
#define xarg0           x10

.section .text.start
test:    
    /* Constants */

    bn.xor  bn0, bn0, bn0

    li      idx_wresult, 15     

    /* Masks */

    bn.subi wones, bn0, 1            


    la      xarg0, prndstr
    li      xarg1, 4 # nr WLEN chunks # <--------------- MODIFY FOR DESIRED TEST
    la      xarg2, sampled_out
    jal     x1, inverse_sampler

    ecall

