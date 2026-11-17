.equ w31, bn0

#define  xarg0  x10

.section .text.start
test:
    /* Constants */

    bn.xor  bn0, bn0, bn0    

    jal     x1, ctx_gen_prndstr

    li      xarg0, 1280 # <----------- MODIFY FOR DESIRED TEST
    jal     x1, gen_prndstr

    ecall