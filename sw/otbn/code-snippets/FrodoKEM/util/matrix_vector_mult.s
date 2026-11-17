## global defines - defined by top file ## 

#define xarg3                x13
#define xarg2                x12
#define xarg1                x11
#define xarg0                x10

#define wresult              w15
#define warg0                w10


## ------------------------------------ ##

## local defines ## 

#define xptr_matrix          x9
#define xptr_vector          x8
#define xlen_vector          x7
#define xnr_elements_WDR     x6
#define xnr_matrix_rows      x5


#define wacc                 w5

## -------------- ##

.equ x2, t0
.equ w31, bn0

/*
 * Name:    matrix_vector_mult
 *
 * Description: matrix vector multiplication with result entries reduced modulo Frodo_Q
 * - Vector and matrix should have 16-bit entries. 
 * - Loading of elements: first entry stored in LSB of WDR
 * - LD(v) in WDR as = [v[15],...,v[0]] 
 * - LD(col(M)) in WDR as = [c[15],...,c[0]] 
 * Flags: Clobbers FG0
 *
 * @param[in]  xarg0: pointer to first matrix row - 32 byte aligned 
 * @param[in]  xarg1: pointer to vector - 32 byte aligned
 * @param[in]  xarg2: length of vector - bytes
 * @param[in]  xarg3: nr of rows matrix
 * @param[out] wresult: result vector stored in the lowest bytes of WREG. Total nr of elements stored in wresult = nr of rows matrix
 *
 * clobbered registers: {x2,x5-x8,x10-x13}, {w0,w5,w10,w15}
 * clobbered registers subroutines: {x2-x4,x10-x12,x15},{w0-w2,w10,w15,w29}
 */

/* Matrix-Vector Multiplication
    * i) MSB representation
    *
    * | -  r1   - | (*) | - v - |  = |<v,r1>,<v,r2>,<v,r3>| => WDR 
    * | -  r2   - |
    * | -  r3   - |
    *
    * ii) LSB representation
    *
    * WDR = |<v,r3>,<v,r2>,<v,r1>|  
*/

.section .text
.global matrix_vector_mult
matrix_vector_mult:

    bn.mov wacc, bn0

    # i) MSB representation

    add xptr_matrix, x0, xarg0
    add xptr_vector, x0, xarg1
    add xlen_vector, x0, xarg2
    add xnr_matrix_rows, x0, xarg3

    loop xnr_matrix_rows, 6
        add   xarg0, x0, xptr_matrix
        add   xarg1, x0, xptr_vector
        add   xarg2, x0, xlen_vector
        jal   x1,  scalar_prod

        bn.or wacc, wresult, wacc << 16
        add   xptr_matrix, xptr_matrix, xlen_vector

    # ii) LSB representation 

    li  xnr_elements_WDR, 16
    sub t0, xnr_elements_WDR, xnr_matrix_rows
    beq x0, t0, skip_shift_upward

    # shift elements to the upper part of WDR
    loop t0, 1
        bn.or wacc, bn0, wacc << 16
    
    skip_shift_upward:
    bn.mov warg0, wacc
    jal x1, swapper 

    ret



