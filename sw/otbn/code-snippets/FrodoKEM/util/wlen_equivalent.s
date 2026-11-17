
#define xresult x15
#define xarg0   x10

.equ x2, t0


/**
* Description: returns the number of WLEN chunks needed to represent [xarg0] bytes
*
* @param[in]  xarg0: nr of bytes
* @param[out] xresult: nr of WLEN chunks 
* clobbered registers: {x2,x10,x15}
*/
.section .text
.global wlen_equivalent
wlen_equivalent:
    srli xresult, xarg0, 5 # reads nr of WLEN chunks
    andi t0, xarg0, 0x1F # reads lowest non-32B multiple bytes
    beq  x0, t0, msglen_is_32B_multiple

    /* adds one extra WLEN chunk if not 32B multiple and guarantees at least one WLEN chunk */
    addi xresult, xresult, 1 

    msglen_is_32B_multiple:
    nop 

    ret



