/*
* High Performance Implementation for Key Generation 
*
* @param[in]  xarg0: t_A parameter
* @param[in]  xarg1: security level - n
*
*/

/***
* GPR AND WDR CONVENTION 
* {x0,x1}   : zero and link register
* {x2-x4}   : tmp
* {x5-x9}   : subroutines
* {x10-x14} : args subroutines
* {x15}     : result
* {x16-x19} : subroutines / main routine
* {x20-x31} : main routine
* {w0-w4}   : wtmp
* {w5-w9}   : subroutines
* {w10-w14} : wargs subroutines
* {w15}     : wresult
* {w16-w19} : subroutines
* {w20-w31} : main routine
*
* Subroutines should state clobbered registers. [w]Tmp,x0,x1,args,results,gl.masks may be omitted. Its usage should be assumed by higher routines. 
* It is the responsibility of a subroutine to update xaddr_free that points to the next free space in memory. This ptr should only point at the boundary between data and "infinite" free space. If not updated, data is considered irrelevant and may be overwritten. 
***/

/* lengths in bytes */

#define LEN_A    16
#define LEN_PK_640  9616
#define LEN_PK_976  15632
#define LEN_PK_1344 21520
#define LEN_SEC_640 16
#define LEN_SEC_976 24
#define LEN_SEC_1344 32

#define LEN_SALT_640 32
#define LEN_SALT_976 48
#define LEN_SALT_1344 64

#define LEN_SEEDSE_640 32
#define LEN_SEEDSE_976 48
#define LEN_SEEDSE_1344 64

#define FRODO_NBAR 8

/* aliases registers */

.equ w31, bn0
#define wones               w30
#define wmask_low_ffff      w29
#define wmask_high_ffff     w28
#define wseedA              w27
#define wctr_Agen           w26
#define wpkh                w25
#define wmask_len_sec       w24
#define wurnd               w23
#define wpkh_urnd           w22
#define wsalt               w21
#define wseedSE_0           w20
#define wseedSE_1           w19
#define wseedk              w18


#define wresult             w15

#define wtmp1               w1
#define wtmp0               w0

#define xctr_Arows          x31
#define xFRODO_N            x30
#define xt_A                x29
#define xaddr_matrix_B_     x28
#define xaddr_out_mult      x27
#define xaddr_matrix_A      x26
#define xaddr_buf_sampled   x25
#define idx_wresult         x24  
#define xaddr_matrix_V      x23
#define xaddr_pubkey        x22
#define xaddr_free          x21
#define xaddr_prndstr       x20

/* x16-x19 used by subroutines */

#define xresult         x15
#define xarg4           x14
#define xarg3           x13
#define xarg2           x12
#define xarg1           x11
#define xarg0           x10

.equ x2, t0
.equ x3, t1
.equ x4, t2

.section .text
.global Encaps
Encaps:

    bn.xor  bn0, bn0, bn0
    bn.mov wctr_Agen, bn0

    li idx_wresult, 15

    /* Masks */
    bn.subi wones, bn0, 1            
    bn.or   wmask_low_ffff, bn0, wones >> 240   
    bn.or   wmask_high_ffff, bn0, wones << 240  

    add xt_A, xarg0, x0 

    #if (FRODO_N == 640)
    li xFRODO_N, 640
    #elif (FRODO_N == 976)
    li xFRODO_N, 976
    #else
    li xFRODO_N, 1344
    #endif

    /* Since for security levels n={976,1344} the modulo is 2^16, no modulo reduction is needed since all entries are automatically truncated to 16-bit */
    bn.wsrw MOD, bn0

    li t0, 640
    bne t0, xFRODO_N, skip_modulo_setup
    /* set modulo FRODO_Q in WDR MOD = 2^15 */
    bn.addi wtmp0, bn0, 1
    loopi 15, 1
        bn.add wtmp0, wtmp0, wtmp0 
    bn.wsrw MOD, wtmp0

    skip_modulo_setup:
    /***************************/

    


    /*** Hash Public Key ***/
    /******** pkh **********/
    /***********************/

    la t0, pk
    bn.lid x0, 0(t0)
    bn.rshi wtmp1, bn0, wones >> 128
    bn.and wseedA, wtmp0, wtmp1

    jal x1, fn_len_pubkey
    add xarg0, xresult, x0
    la xarg1, pk 
    li xarg2, 1
    jal x1, ctx_shake

    la xaddr_free, addr_free

    jal x1, fn_len_sec
    add xarg0, xresult, x0
    jal x1, wlen_equivalent

    add xarg0, xresult, x0
    li xarg1, 0
    add xarg2, xaddr_free, x0
    jal x1, squeeze_shake

    li t0, 32
    sub xaddr_free, xaddr_free, t0
    bn.lid x0, 0(xaddr_free) # w0 = 0x0..0||pkh[:len_sec]
    bn.mov wpkh, wtmp0

    /*** Concatenate ****/
    /*** pkh||u||salt ***/
    /********************/

    jal x1, fn_len_sec
    li t0, 640
    bne t0, xFRODO_N, concat_976_pkh_u_salt

    /* n=640, len_sec=16, len_salt=32 */
    /**********************************/

    bn.rshi wmask_len_sec, bn0, wones >> 128
    bn.and wpkh, wpkh, wmask_len_sec
    
    la t0, urnd
    bn.lid x0, 0(t0) # 0x0..0||urnd[:16]
    bn.mov wurnd, wtmp0

    bn.rshi wpkh, wpkh, bn0 >> 128 # pkh[:16]||0x0..0
    bn.rshi wpkh_urnd, wurnd, wpkh >> 128 # urnd[:16]||pkh[:16]

    la t0, salt
    bn.lid x0, 0(t0) # salt[:32]
    bn.mov wsalt, wtmp0 

    bn.mov wresult, wpkh_urnd
    bn.sid idx_wresult, 0(xaddr_free++)
    bn.mov wresult, wsalt
    bn.sid idx_wresult, 0(xaddr_free++)

    li t0, 64
    sub xaddr_free, xaddr_free, t0

    jal x0, shake_seedSE_k

    concat_976_pkh_u_salt:

    li t0, 976
    bne t0, xFRODO_N, concat_1344_pkh_u_salt

    /* n=976, len_sec=24, len_salt=48 */
    /**********************************/

    bn.rshi wmask_len_sec, bn0, wones >> 64
    bn.and wpkh, wpkh, wmask_len_sec

    la t0, urnd
    bn.lid x0, 0(t0) # 0x0..0||urnd[:24]
    bn.mov wurnd, wtmp0

    bn.rshi wpkh, wpkh, bn0 >> 192 # pkh[:24]||0x0..0
    bn.rshi wpkh_urnd, wurnd, wpkh >> 64 # urnd[:8]||pkh[:24]
    bn.rshi wurnd, bn0, wurnd >> 64 # 0x0..0||urnd[8:24]

    bn.mov wresult, wpkh_urnd
    bn.sid idx_wresult, 0(xaddr_free++)

    la t0, salt
    bn.lid x0, 0(t0) # salt[:32] first 32 bytes
    bn.mov wsalt, wtmp0 

    bn.rshi wurnd, wurnd, bn0 >> 128 # urnd[8:24]||0x0..0
    bn.rshi wresult, wsalt, wurnd >> 128 # salt[:16]||urnd[8:24]
     
    bn.sid idx_wresult, 0(xaddr_free++) 

    bn.rshi wsalt, bn0, wsalt >> 128 # 0x0..0||salt[16:32]
    bn.rshi wsalt, wsalt, bn0 >> 128 # salt[16:32]||0x0..0

    la t0, salt
    addi t0, t0, 32
    bn.lid x0, 0(t0) # 0x0..0||salt[32:48]

    bn.rshi wsalt, wtmp0, wsalt >> 128 # salt[32:48]||salt[16:32]
    bn.mov wresult, wsalt
    bn.sid idx_wresult, 0(xaddr_free++)

    li t0, 96
    sub xaddr_free, xaddr_free, t0

    jal x0, shake_seedSE_k

    concat_1344_pkh_u_salt:

    /* n=1344, len_sec=32, len_salt=64 */
    /***********************************/

    bn.mov wresult, wpkh # pkh[:32]
    bn.sid idx_wresult, 0(xaddr_free++)

    la t0, urnd
    bn.lid x0, 0(t0) # urnd[:32]
    bn.mov wurnd, wtmp0
    bn.mov wresult, wurnd
    bn.sid idx_wresult, 0(xaddr_free++)

    la t0, salt
    bn.lid x0, 0(t0++) # salt[:32]
    bn.mov wsalt, wtmp0
    bn.mov wresult, wsalt
    bn.sid idx_wresult, 0(xaddr_free++)

    bn.lid x0, 0(t0++) # salt[32:64]
    bn.mov wsalt, wtmp0
    bn.mov wresult, wsalt
    bn.sid idx_wresult, 0(xaddr_free++)

    li t0, 128
    sub xaddr_free, xaddr_free, t0

    /*** Shake seedSE and k ****/
    /*** seedSE||k *************/
    /***************************/

    shake_seedSE_k:

    jal x1, fn_len_sec
    slli t1, xresult, 1 # len_pkh+len_urnd = 2*len_sec
    jal x1, fn_len_salt
    add xarg0, xresult, t1 # len_pkh+len_urnd+len_salt
    add xarg1, xaddr_free, x0
    li xarg2, 1
    jal x1, ctx_shake
    
    jal x1, fn_len_seedSE
    add t1, xresult, x0 # len_seedSE 

    jal x1, fn_len_sec
    add xarg0, xresult, t1 # len_seedSE+len_sec
    jal x1, wlen_equivalent
    add xarg0, xresult, x0
    li xarg1, 0
    add xarg2, xaddr_free, x0
    jal x1, squeeze_shake

    jal x1, fn_lid_seedSE_k

    /****** Concatenate ******/
    /****** 0x96||seedSE ******/

    li t0, 640
    bne t0, xFRODO_N, concat_976_0x96_seedSE

    bn.addi wtmp0, bn0, 0x96
    bn.or wtmp0, wtmp0, wseedSE_0 << 8
    bn.sid x0, 0(xaddr_free++)
    bn.rshi wtmp0, bn0, wseedSE_0 >> 248
    bn.sid x0, 0(xaddr_free++)

    li t0, 64
    sub xaddr_free, xaddr_free, t0

    jal x0, generate_prndstr

    concat_976_0x96_seedSE:
    li t0, 976
    bne t0, xFRODO_N, concat_1344_0x96_seedSE

    bn.addi wtmp0, bn0, 0x96
    bn.or wtmp0, wtmp0, wseedSE_0 << 8
    bn.sid x0, 0(xaddr_free++)
    bn.rshi wtmp0, wseedSE_1, wseedSE_0 >> 248
    bn.sid x0, 0(xaddr_free++)

    li t0, 64
    sub xaddr_free, xaddr_free, t0

    jal x0, generate_prndstr

    concat_1344_0x96_seedSE:

    bn.addi wtmp0, bn0, 0x96
    bn.or wtmp0, wtmp0, wseedSE_0 << 8
    bn.sid x0, 0(xaddr_free++)
    bn.rshi wtmp0, wseedSE_1, wseedSE_0 >> 248
    bn.sid x0, 0(xaddr_free++)
    bn.rshi wtmp0, bn0, wseedSE_1 >> 248
    bn.sid x0, 0(xaddr_free++)

    li t0, 96
    sub xaddr_free, xaddr_free, t0

    generate_prndstr:

    add xaddr_prndstr, xaddr_free, x0

    jal x1, fn_len_0x96_seedSE
    add xarg0, xresult, x0
    add xarg1, xaddr_free, x0
    li xarg2, 1
    jal x1, ctx_shake

    slli t0, xFRODO_N, 4 # 2*nbar*n = 16*n
    addi t0, t0, 64 # 2*nbar*n+nbar^2
    slli xarg0, t0, 1 # 2*(2*nbar*n+nbar^2) bytes
    jal x1, wlen_equivalent
    add xarg0, xresult, x0
    li xarg1, 0
    add xarg2, xaddr_free, x0
    jal x1, squeeze_shake

    /***** sample matrix S' and E' *****/
    add xaddr_buf_sampled, xaddr_prndstr, x0

    slli xarg0, xFRODO_N, 5 # 2*(2*nbar*n) = 32*n
    jal x1, wlen_equivalent

    add xarg1, xresult, x0
    add xarg0, xaddr_prndstr, x0
    add xarg2, xaddr_buf_sampled, x0
    jal x1, inverse_sampler




    /******* B' = S'A *******/
    add     xaddr_matrix_B_, xaddr_free, x0

    add     xaddr_out_mult, xaddr_matrix_B_, x0

    /* reserve space for B' */
    slli    t0, xFRODO_N, 4 # nbar*n*2 = 16*n
    add     xaddr_free, xaddr_free, t0

    add     xaddr_matrix_A, xaddr_free, x0

    jal x1, mult_SA

    /******* B' = S'A + E' *******/

    slli    xarg0, xFRODO_N, 4 # n*nbar*2 = n*8*2
    jal     x1, wlen_equivalent
    add     xarg2, xresult, x0

    add     xarg0, xaddr_matrix_B_, x0
    add     xarg1, xaddr_buf_sampled, x0 
    jal     x1, matrix_matrix_add


    /******* Pack(B') *******/
    slli xarg0, xFRODO_N, 4 # n*nbar*2 = n*8*2
    add xarg1, xaddr_matrix_B_, x0
    add xarg2, xaddr_matrix_B_, x0
    jal x1, pack

    /***** sample matrix E'' *****/
    add xaddr_buf_sampled, xaddr_prndstr, x0
    slli t0, xFRODO_N, 5 # 2*2*nbar*n
    add xaddr_buf_sampled, xaddr_buf_sampled, t0
    
    li xarg0, 128 # 2*nbar*nbar 
    jal x1, wlen_equivalent

    add xarg1, xresult, x0
    add xarg0, xaddr_buf_sampled, x0
    add xarg2, xaddr_buf_sampled, x0
    jal x1, inverse_sampler

    /***** B=Unpack(b) ****/

    jal x1, fn_len_pubkey
    add xarg0, xresult, x0
    jal x1, wlen_equivalent
    li t0, 1
    sub xresult, xresult, t0
    la t0, pk    
    bn.lid x0, 0(t0++)
    bn.mov wresult, wtmp0
    loop xresult, 5
        bn.lid x0, 0(t0++)
        bn.rshi wresult, wtmp0, wresult >> 128
        bn.sid idx_wresult, 0(xaddr_free++)
        bn.rshi wtmp0, bn0, wtmp0 >> 128
        bn.rshi wresult, wtmp0, bn0 >> 128
    slli t0, xresult, 5 # length packed matrix - bytes 
    add xarg0, t0, x0
    sub xarg1, xaddr_free, t0
    add xarg2, xaddr_free, x0
    jal x1, unpack

    /***** V = S'B + E'' ****/
    add xaddr_buf_sampled, xaddr_prndstr, x0
    add xarg0, xaddr_buf_sampled, x0
    add xarg1, xaddr_free, x0 # ptr matrix B

    /* update free mem after unpacking */
    slli t0, xFRODO_N, 4 # B size bytes
    add xaddr_free, xaddr_free, t0
    add xaddr_matrix_V, xaddr_free, x0
    /* ------------------------------- */
    add xarg2, xaddr_matrix_V, x0
    jal x1, mult_SB

    slli t0, xFRODO_N, 5 
    add xarg1, xaddr_prndstr, t0

    li xarg0, 128 # size of E''
    jal x1, wlen_equivalent

    add xarg2, xresult, x0
    add xarg0, xaddr_matrix_V, x0
    jal x1, matrix_matrix_add

    /* update free mem after addition */
    li t0, 128
    add xaddr_free, xaddr_matrix_V, t0

    /** Encode(u) **/
    jal x1, fn_len_sec
    add xarg0, xresult, x0
    la xarg1, urnd
    add xarg2, xaddr_free, x0
    jal x1, encode

    /**** C = V + Encode(u) ****/
    /* C reuses mem from V */
    li xarg0, 128 # size of V
    jal x1, wlen_equivalent  
    add xarg2, xresult, x0
    add xarg0, xaddr_matrix_V, x0
    add xarg1, xaddr_free, x0
    jal x1, matrix_matrix_add

    /**** Pack(C) ****/
    li xarg0, 128 # size of C
    add xarg1, xaddr_matrix_V, x0
    add xarg2, xaddr_matrix_V, x0
    jal x1, pack

    /****** SHAKE(c1||c2||salt||k) *******/
    /***** concatenate c1||c2||salt||k ***/

    /* We store c1||c2||salt||k at xaddr_matrix_B_ 
    * xaddr_matrix_B_ is therefore the addr of the ciphertext
    *
    */
    
    #if (FRODO_N == 640)
        li t0, 9600 # size packed B'
        add t0, xaddr_matrix_B_, t0
        add t1, xaddr_matrix_V, x0 # c2 is stored at xaddr_matrix_V
        loopi 3, 2
            bn.lid idx_wresult, 0(t1++)
            bn.sid idx_wresult, 0(t0++)
        bn.lid idx_wresult, 0(t1)
        bn.rshi wresult, wresult, bn0 >> 192 # delete upper 8 bytes
        la t1, salt
        bn.lid x0, 0(t1)
        bn.mov wsalt, wtmp0
        bn.rshi wresult, wsalt, wresult >> 64 # append 8 bytes of salt
        bn.sid idx_wresult, 0(t0++)
        bn.rshi wsalt, bn0, wsalt >> 64 # delete transfered bytes
        bn.rshi wsalt, wsalt, bn0 >> 192 # move wsalt upwards
        bn.rshi wresult, wseedk, wsalt >> 64 # append 8 bytes of k
        bn.sid idx_wresult, 0(t0++)
        bn.rshi wresult, bn0, wseedk >> 64 # delete transfered bytes
        bn.sid idx_wresult, 0(t0)
        /* SHAKE IT */
        li xarg0, 9768 # 9600+120+32+16
        add xarg1, xaddr_matrix_B_, x0
        li xarg2, 1
        jal x1, ctx_shake

        /* relocate ciphertext for printing and asserting */
        la t0, addr_free
        loopi 305, 2
            bn.lid x0, 0(xaddr_matrix_B_++)
            bn.sid x0, 0(t0++)
        /**************************************************/
        /* Place ss just after cc  */
        li t0, 9760
        la t1, addr_free
        add xaddr_free, t1, t0 

        li xarg0, 1
        li xarg1, 0
        add xarg2, xaddr_free, x0 # shared secret
        jal x1, squeeze_shake

    #elif (FRODO_N == 976)
        li t0, 15616 # size packed B'
        add t0, xaddr_matrix_B_, t0
        add t1, xaddr_matrix_V, x0 # c2 is stored at xaddr_matrix_V
        loopi 4, 2
            bn.lid idx_wresult, 0(t1++)
            bn.sid idx_wresult, 0(t0++)
        la t1, salt
        bn.lid idx_wresult, 0(t1++) # wsalt[:32]
        bn.sid idx_wresult, 0(t0++)
        bn.lid idx_wresult, 0(t1) # 0x0..0|wsalt[32:48]
        bn.rshi wresult, wresult, bn0 >> 128 # wsalt[32:48]|0x0..0
        bn.rshi wresult, wseedk, wresult >> 128 # wseedk[:16]|wsalt[32:48]
        bn.sid idx_wresult, 0(t0++)
        bn.rshi wresult, bn0, wseedk >> 128 # 0x0..0|wseedk[16:24]
        bn.sid idx_wresult, 0(t0++)

        /* SHAKE IT */
        li xarg0, 15816 # 15616+128+48+24
        add xarg1, xaddr_matrix_B_, x0
        li xarg2, 1
        jal x1, ctx_shake

        /* relocate ciphertext for printing and asserting */
        la t0, addr_free
        loopi 494, 2
            bn.lid x0, 0(xaddr_matrix_B_++)
            bn.sid x0, 0(t0++)
        /**************************************************/
        /* Place ss just after cc */
        li t0, 15808
        la t1, addr_free
        add xaddr_free, t1, t0

        li xarg0, 1
        li xarg1, 0
        add xarg2, xaddr_free, x0 # shared secret
        jal x1, squeeze_shake

    #else
        li t0, 21504 # size packed B'
        add t0, xaddr_matrix_B_, t0
        add t1, xaddr_matrix_V, x0
        loopi 4, 2
            bn.lid idx_wresult, 0(t1++)
            bn.sid idx_wresult, 0(t0++)
        la t1, salt
        loopi 2, 2
            bn.lid idx_wresult, 0(t1++)
            bn.sid idx_wresult, 0(t0++)
        bn.mov wresult, wseedk
        bn.sid idx_wresult, 0(t0)

        /* SHAKE IT */
        li xarg0, 21728 # 21504+128+64+32
        add xarg1, xaddr_matrix_B_, x0
        li xarg2, 1
        jal x1, ctx_shake

        /* relocate ciphertext for printing and asserting */
        la t0, addr_free
        loopi 678, 2
            bn.lid x0, 0(xaddr_matrix_B_++)
            bn.sid x0, 0(t0++)
        /**************************************************/
        /* Place ss just after cc */
        li t0, 21696
        la t1, addr_free
        add xaddr_free, t1, t0

        li xarg0, 1
        li xarg1, 0
        add xarg2, xaddr_free, x0 # shared secret
        jal x1, squeeze_shake

    #endif

ret



/************ help functions ************/

fn_len_pubkey:
    li t0, 640
    bne t0, xFRODO_N, seclev2_pk
    li xresult, LEN_PK_640
    ret
    seclev2_pk:
    li t0, 976
    bne t0, xFRODO_N, seclev3_pk
    li xresult, LEN_PK_976
    ret
    seclev3_pk:
    li xresult, LEN_PK_1344
    ret

fn_len_sec:
    li t0, 640
    bne t0, xFRODO_N, seclev2_lensec
    li xresult, LEN_SEC_640
    ret
    seclev2_lensec:
    li t0, 976
    bne t0, xFRODO_N, seclev3_lensec
    li xresult, LEN_SEC_976
    ret
    seclev3_lensec:
    li xresult, LEN_SEC_1344
    ret

fn_len_salt: 
    li t0, 640
    bne t0, xFRODO_N, seclev2_len_salt
    li xresult, LEN_SALT_640
    ret
    seclev2_len_salt:
    li t0, 976
    bne t0, xFRODO_N, seclev3_len_salt
    li xresult, LEN_SALT_976
    ret
    seclev3_len_salt:
    li xresult, LEN_SALT_1344
    ret

fn_len_seedSE: 
    li t0, 640
    bne t0, xFRODO_N, seclev2_len_seedSE
    li xresult, LEN_SEEDSE_640
    ret
    seclev2_len_seedSE:
    li t0, 976
    bne t0, xFRODO_N, seclev3_len_seedSE
    li xresult, LEN_SEEDSE_976
    ret
    seclev3_len_seedSE:
    li xresult, LEN_SEEDSE_1344
    ret

fn_lid_seedSE_k:
    li t0, 640
    bne t0, xFRODO_N, seclev2_lid_seedSE_k
    li t0, 64
    sub xaddr_free, xaddr_free, t0

    bn.lid x0, 0(xaddr_free++)
    bn.mov wseedSE_0, wtmp0
    bn.lid x0, 0(xaddr_free++)
    bn.mov wseedk, wtmp0
    bn.rshi wmask_len_sec, bn0, wones >> 128
    bn.and wseedk, wseedk, wmask_len_sec

    li t0, 64
    sub xaddr_free, xaddr_free, t0
    ret

    seclev2_lid_seedSE_k:
    li t0, 976
    bne t0, xFRODO_N, seclev3_lid_seedSE_k
    li t0, 96
    sub xaddr_free, xaddr_free, t0

    bn.lid x0, 0(xaddr_free++)
    bn.mov wseedSE_0, wtmp0 # wseedSE_0[:32]
    bn.lid x0, 0(xaddr_free++)
    bn.rshi wtmp1, bn0, wones >> 128
    bn.and wseedSE_1, wtmp0, wtmp1 # 0x0..0||wseedSE_1[32:48]
    bn.rshi wtmp1, wones, bn0 >> 128
    bn.and wseedk, wtmp0, wtmp1 # wseedk[:16]||0x0..0
    bn.lid x0, 0(xaddr_free++)
    bn.rshi wseedk, wtmp0, wseedk >> 64 # wseedk[:24]||0x0..0
    bn.rshi wseedk, bn0, wseedk >> 64 # 0x0..0||wseedk[:24]

    li t0, 96
    sub xaddr_free, xaddr_free, t0
    ret

    seclev3_lid_seedSE_k:
    li t0, 96
    sub xaddr_free, xaddr_free, t0

    bn.lid x0, 0(xaddr_free++)
    bn.mov wseedSE_0, wtmp0 # wseedSE_0[:32]
    bn.lid x0, 0(xaddr_free++)
    bn.mov wseedSE_1, wtmp0 # wseedSE_1[32:64]
    bn.lid x0, 0(xaddr_free++)
    bn.mov wseedk, wtmp0 # wseedk[:32]

    li t0, 96
    sub xaddr_free, xaddr_free, t0
    ret  

fn_len_0x96_seedSE:
    li t0, 640
    bne t0, xFRODO_N, seclev2_len_0x96_seedSE
    jal x1, fn_len_seedSE
    addi xresult, xresult, 1
    ret
    seclev2_len_0x96_seedSE:
    li t0, 976
    bne t0, xFRODO_N, seclev3_len_0x96_seedSE
    jal x1, fn_len_seedSE
    addi xresult, xresult, 1
    ret
    seclev3_len_0x96_seedSE:
    jal x1, fn_len_seedSE
    addi xresult, xresult, 1
    ret






