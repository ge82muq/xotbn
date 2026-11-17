
## global defines - defined by top file ## 

#define xarg3                x13
#define xarg2                x12
#define xarg1                x11
#define xarg0                x10

#define wresult              w15
#define warg0                w10


## ------------------------------------ ##

## local defines ## 

#define xptr_matrix          x7
#define xptr_vector          x6
#define xlen_vector          x5
/* !! wacc is shared with matrix matrix mult !! */
#define wacc                 w5

.equ w31, bn0

/*
 * Name:    vector_matrix_mult
 *
 * Description: Vector matrix multiplication with result entries truncated to 16-bit
 * Flags: Clobbers FG0
 *
 * @param[in]  xarg0: pointer to vector - 32 byte aligned
 * @param[in]  xarg1: pointer to first matrix column - 32 byte aligned
 * @param[in]  xarg2: length of vector - bytes
 * @param[in]  xarg3: nr of matrix columns: must be 8! no more and no less: otherwise wacc under/overflows!
 *
 * clobbered registers: {x5-x7,x10-x12}, {w5,w10,w15}
 * clobbered registers subroutines: {x2-x4,x10-x12,x15},{w0-w2,w5,w10,w15}
 */

.section .text
.global vector_matrix_mult
vector_matrix_mult:

add xptr_vector, xarg0, x0
add xptr_matrix, xarg1, x0
add xlen_vector, xarg2, x0

# xarg3 must be 8! no more and no less: otherwise wacc under/overflows!
loop xarg3, 6
    add   xarg0, xptr_vector, x0
    add   xarg1, xptr_matrix, x0
    add   xarg2, xlen_vector, x0
    jal   x1,  scalar_prod

    bn.rshi wacc, wresult, wacc >> 16 

    add   xptr_matrix, xptr_matrix, xlen_vector

bn.addvm.16H wacc, wacc, bn0 # pseudo-modular reduction


ret



