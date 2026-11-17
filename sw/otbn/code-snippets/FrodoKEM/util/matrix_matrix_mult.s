

#define CONST_8 8              

/* Register aliases */


#define idx_wresult         x24  

#define xnr_rows_matrix1    x19
#define xaddr_matrix2       x18
#define xaddr_matrix1       x17
#define xlen_row_matrix1    x16

#define xarg4               x14
#define xarg3               x13
#define xarg2               x12
#define xarg1               x11
#define xarg0               x10

#define xctr_rows           x9
#define xBOOL               x8

#define wresult w15
/* !! wacc: scalar products' accumulator: wacc is shared with vector matrix mult !! */
#define wacc    w5

.equ w31, bn0

/*
 * Description: matrix3 = matrix1 x matrix2
 * @param[in] xarg0: address matrix1
 * @param[in] xarg1: rows matrix1
 * @param[in] xarg2: cols matrix1
 * @param[in] xarg3: address matrix2
 * @param[in] xarg4: address output matrix3
 * Flags: Clobbers FG0
 *
 * clobbered registers: {x8,x9,x13,x18,x19,x23,x24,x29}, {w6}
 * clobbered registers subroutines: {x2-x4,x5-x7,x10-x12,x15},{w5,w6,w10,w15}
 */

.section .text
.global matrix_matrix_mult
matrix_matrix_mult:


add xaddr_matrix1, xarg0, x0
add xnr_rows_matrix1, xarg1, x0
slli xlen_row_matrix1, xarg2, 1 # cols*2 bytes
add xaddr_matrix2, xarg3, x0

li xctr_rows, 0
li xBOOL, 0 # controls when we store computations

bn.mov wacc, bn0 

next_row:

    add xarg0, xaddr_matrix1, x0
    add xarg1, xaddr_matrix2, x0
    add xarg2, xlen_row_matrix1, x0
    li xarg3, CONST_8 # matrix mult hardcoded to 8 cols for matrix2
    jal x1, vector_matrix_mult

    /* we store only every 32B computed */

    beq x0, xBOOL, skip_store
    
    store: 
        bn.mov wresult, wacc

        bn.sid idx_wresult, 0(xarg4++)
        
        li xBOOL, 0 # reset
    
        beq x0, x0, update_addr
    
    skip_store:

        li xBOOL, 1 # set

    update_addr:
        add  xaddr_matrix1, xaddr_matrix1, xlen_row_matrix1
        addi xctr_rows, xctr_rows, 1

        bne xnr_rows_matrix1, xctr_rows, next_row 

ret



