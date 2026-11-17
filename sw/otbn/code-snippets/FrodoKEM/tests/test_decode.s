#define LEN_SEC 16

.equ w31, bn0

#define idx_wresult     x24
#define xarg1           x11
#define xarg0           x10

.section .text.start
test:    

    /***************************** 
    * Setup:
    * Parameters, constants, masks 
    *****************************/
    bn.xor  bn0, bn0, bn0

    li idx_wresult, 15  

    li      xarg0, LEN_SEC
    la      xarg1, u_rnd_enc
    jal     x1, decode

    ecall

