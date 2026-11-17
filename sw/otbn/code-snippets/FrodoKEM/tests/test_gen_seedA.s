.equ w31, bn0

#define wones               w30

.section .text.start
test:
    /* Constants */

    bn.xor  bn0, bn0, bn0 

    /* Masks */

    bn.subi wones, bn0, 1              
    
    jal x1, gen_seedA
    ecall
    
