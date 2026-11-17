
#define xarg2               x12
#define xarg1               x11
#define xarg0               x10

#define xnr_wlen_chunks     x8
#define xlen_tiles          x7
#define xptr_tile2          x6
#define xptr_tile1          x5

#define wresult             w15
#define warg0               w10

#define wtmp2                w2
#define wtmp1                w1
#define wtmp0                w0

.equ x2, t0

.equ w31, bn0

/*
 *
 * Description: 
 * - element-wise mutliplication between two tiles. The length of the tiles must be a multiple of 32 
 * Flags: Clobbers FG0
 *
 * @param[in]  xarg0: pointer to tile t1 - 32 byte aligned
 * @param[in]  xarg1: pointer to tile t2 - 32 byte aligned
 * @param[in]  xarg2: length of tiles - bytes
 * @param[out]  wresult: WDR with the element-wise multiplication between the elements of the tiles 
 *
 * clobbered registers: {x2,x5-x8,x10-x12}, {w0-w2,w10,w15}
 */

 .section .text
 .global tile_mult
 tile_mult:

    bn.mov wresult, bn0 # init result WREG

    add xptr_tile1, x0, xarg0
    add xptr_tile2, x0, xarg1
    add xlen_tiles, x0, xarg2

    # nr of WLEN chunks. 
    srli xnr_wlen_chunks, xlen_tiles, 5

    # xnr_wlen_chunks >= 1 !
    beq x0, xnr_wlen_chunks, end

    li t0, 1
    loop xnr_wlen_chunks, 4
        bn.lid x0, 0(xptr_tile1++)
        bn.lid t0, 0(xptr_tile2++)
        bn.mulv.16H wtmp2, wtmp0, wtmp1
        bn.addv.16H wresult, wresult, wtmp2
    
 end:
    nop
    ret
    