/* Register aliases */
.equ x2, t0

#define xarg2               x12
#define xarg1               x11
#define xarg0               x10

#define wtmp1               w1
#define wtmp0               w0
/*
 * Name: matrix matrix addition
 * - Matrices of the same dimensions with 16-bit entries
 * - Adds min 32 bytes together and performs a pseudo modular reduction modulo MOD
 * - Stores addition in M1
 * Description:  M1 = M1+M2
 * Flags: Clobbers FG0
 *
 * @param[in]  xarg0: pointer to first row of matrix M1 - 32 byte aligned
 * @param[in]  xarg1: pointer to first row of matrix M2 - 32 byte aligned
 * @param[in]  xarg2: nr of WLEN chunks to add together
 *
 * clobbered registers: {x2,x10-13}, {w0,w1}
 * clobbered registers subroutines: {},{}
 */

.section .text.start
.global matrix_matrix_add
matrix_matrix_add:

li t0, 1
loop xarg2, 5
    bn.lid x0, 0(xarg0)
    bn.lid t0, 0(xarg1++)

    bn.addvm.16H wtmp0, wtmp0, wtmp1
    
    bn.sid x0, 0(xarg0++)
    nop 

ret


