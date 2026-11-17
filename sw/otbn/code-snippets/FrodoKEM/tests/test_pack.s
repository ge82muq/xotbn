.equ w31, bn0

#define wones               w30
#define wmask_low_ffff      w29
#define wmask_high_ffff     w28

#define xFRODO_N          x30

#define idx_wresult         x24
#define xarg2           x12
#define xarg1           x11
#define xarg0           x10

.section .text.start
test:    

    /***************************** 
    * Setup:
    * Parameters, constants, masks 
    *****************************/
    li xFRODO_N, 1344

    bn.xor  bn0, bn0, bn0
    li idx_wresult, 15  

    /* Masks */
    bn.subi wones, bn0, 1            
    bn.or   wmask_low_ffff, bn0, wones >> 240   
    bn.or   wmask_high_ffff, bn0, wones << 240 

    li      xarg0, 21504
    la      xarg1, matrix
    la      xarg2, matrix
    jal     x1, pack

    ecall

