/* Register aliases */

#define wmask_low_ffff      w29

#define wresult             w15
#define warg0               w10

#define wtmp3               w3
#define wtmp2               w2
#define wtmp1               w1
#define wtmp0               w0

#define xnr_Scols            x30

#define xaddr_matrix_B       x27

#define xone                 x25
#define idx_wresult          x24

#define xctr                 x17

#define xarg2                x12
#define xarg1                x11
#define xarg0                x10


#define xaddr_start_matrix_B    x9
#define xCONST_64               x8
#define xouter_loop_it          x7
#define xaddr_start_tmp         x6
#define xaddr_tmp               x5

.equ w31, bn0


/*
 * Description: transposes rows stored contiguously in DMEM to columns. 
 *
 * @param[in]  xarg0: t_A parameter
 * @param[in]  xarg1: ptr to rows to be transposed
 * @param[in]  xarg2: ptr to temporal storage for intermediate results
 * clobbered registers: {x5-x9,x10,x17,x24,x25,x27,x30,x31},{w0-w3,w10,w15,w29}
 * clobbered registers subroutines: {x2,x3}, {w0,w5,w10,w15,w28}
 */
.section .text
.global rows2cols
rows2cols:
    /* init results register */
    bn.mov wresult, bn0
    /* flow control */
    li  xCONST_64, 64  
    li  xctr, 0   

    add xaddr_start_matrix_B, x0, xarg1
    add xaddr_start_tmp, x0, xarg2
    
    add xaddr_matrix_B, x0, xaddr_start_matrix_B
    add xaddr_tmp, x0, xaddr_start_tmp

    srli xouter_loop_it, xarg0, 1  # loops t_A/2 times

    loop xouter_loop_it, 22
        loopi 2, 17
            itColS:
                # 1.
                bn.lid  x0, 0(xaddr_matrix_B++)
                bn.lid  xone, 0(xaddr_matrix_B++)
                # 2.
                bn.and  wtmp2, wtmp0, wmask_low_ffff
                bn.and  wtmp3, wtmp1, wmask_low_ffff
                # 3.1
                bn.or   wtmp2, bn0, wtmp2 << 16
                bn.or   wtmp2, wtmp2, wtmp3
                # 3.2
                bn.or   wresult, bn0, wresult << 32
                bn.or   wresult, wresult, wtmp2
                # 4.
                bn.rshi  wtmp0, bn0, wtmp0 >> 16
                bn.rshi  wtmp1, bn0, wtmp1 >> 16
                
                /* restore address */
                sub xaddr_matrix_B, xaddr_matrix_B, xCONST_64

                bn.sid   x0, 0(xaddr_matrix_B++)
                bn.sid   xone, 0(xaddr_matrix_B++)

                addi xctr, xctr, 2

                bne xnr_Scols, xctr, itColS

            add xctr, x0, x0  # reset ctr
            add xaddr_matrix_B, x0, xaddr_start_matrix_B
        
        /* swap bytes in result register */
        bn.mov warg0, wresult
        jal x1, swapper

        /* Use matrix A dmem space as tmp storage */
        bn.sid idx_wresult, 0(xaddr_tmp++)
        bn.mov wresult, bn0

    /* Put back rows to matrix B */
    add xaddr_matrix_B, x0, xaddr_start_matrix_B
    add xaddr_tmp, x0, xaddr_start_tmp 
    loop xouter_loop_it, 2
        bn.lid x0, 0(xaddr_tmp++)
        bn.sid x0, 0(xaddr_matrix_B++)

    ret


