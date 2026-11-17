#define wones                w30

#define wresult              w15

#define wmaskbits_Tchi       w8
#define wprndstr_sh          w7
#define wval_distTable       w6
#define wprndstr             w5

#define wtmp1                w1
#define wtmp0                w0

#define xFRODO_N          x30

#define idx_wresult          x24

#define xarg2                x12
#define xarg1                x11
#define xarg0                x10

#define xlen_Tchi            x9
#define idx_wmaskbits_Tchi   x8
#define idx_wprndstr         x7
#define idx_wval_distTable   x6
#define xaddr_distTable      x5

.equ x2, t0

/*
 * Name:    inverse_sampler
 *
 * Description: matrix sampling from FrodoKEM´s error distribution.
 *
 * Flags: Clobbers FG0
 *
 * @param[in]  xarg0: pointer to prnd string
 * @param[in]  xarg1: nr of WDLEN chunks to extract from prnd string
 * @param[in]  xarg2: pointer to sampled matrix
 * clobbered registers: {x5-x9},{w5-w8}
 *
 */



.section .text
.global inverse_sampler
inverse_sampler:
/* Code for compatibility */
#if (FRODO_N == 640)
li xFRODO_N, 640
#elif (FRODO_N == 976)
li xFRODO_N, 976
#else
li xFRODO_N, 1344
#endif
/* Code for compatibility */

    li t0, 640
    bne t0, xFRODO_N, seclev2
    li xlen_Tchi, 13
    jal x0, load_maskbits
    seclev2:
    li t0, 976
    bne t0, xFRODO_N, seclev3
    li xlen_Tchi, 11
    jal x0, load_maskbits
    seclev3:
    li xlen_Tchi, 7

    load_maskbits:

    la      t0, maskbits_Tchi            
    li      idx_wmaskbits_Tchi, 8
    bn.lid  idx_wmaskbits_Tchi, 0(t0)
    
    li idx_wval_distTable, 6
    li idx_wprndstr, 5

    loop xarg1, 15

        bn.lid      idx_wprndstr, 0(xarg0++)    
        bn.shv.16H  wprndstr_sh, wprndstr >> 1  
        
        bn.xor wresult,wresult,wresult   # e <= 0

        la xaddr_distTable, distTable

        loop xlen_Tchi, 4

            /* e++ if (prnd >> 1) > Tx[i], else e=e+0 */

            bn.lid       idx_wval_distTable, 0(xaddr_distTable++) # wdr <= [Tx[i]||Tx[i]]...||Tx[i]]
            bn.subv.16H  wtmp0,  wval_distTable,  wprndstr_sh
            bn.shv.16H   wtmp0,  wtmp0 >> 15 # read sign bit
            bn.addv.16H  wresult, wresult, wtmp0 
        
            
        bn.and  wtmp0, wprndstr, wmaskbits_Tchi # lsb = prnd & mask

        /* flip sign of e (Two Complement) only when prnd[lsb] == 1  */

        bn.mulv.16H  wtmp1,  wtmp0,  wones
        bn.xor       wresult, wresult, wtmp1
        bn.addv.16H  wresult, wresult, wtmp0

        bn.sid  idx_wresult, 0(xarg2++)
        nop   
    ret

