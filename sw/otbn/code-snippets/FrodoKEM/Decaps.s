/*
* High Performance Implementation for Decaps 
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

#define LEN_SEEDA 16
#define FRODO_N_BAR 8
#define LEN_SQ_NBAR 128
#define WLEN_SQ_NBAR 4
#define NEG_GENA 1
#define GENA 0 

.equ w31, bn0
#define wones               w30
#define wmask_low_ffff      w29
#define wmask_high_ffff     w28
#define wseedA              w27
#define wctr_Agen           w26
#define wkbar               w24
#define wu_                 w23
#define wsalt_1             w22
#define wsalt_0             w21
#define wseed_s             w20
#define wk_                 w18

#define wresult             w15

#define xt_A            x29

#define idx_wresult     x24

#define xaddr_free      x21

#define xresult         x15
#define xarg4           x14
#define xarg3           x13
#define xarg2           x12
#define xarg1           x11
#define xarg0           x10

.equ x2, t0
.equ x3, t1
.equ x4, t2

#if (FRODO_N == 640)

#define LEN_SEED_PRNDSTR 33
#define LEN_DIG_SEEDSE_K 48
#define WLEN_DIG_SEEDSE_K 2
#define LEN_SALT 32
#define LEN_SEC 16
#define LEN_SEEDSE 32
#define LEN_C1 9600
#define WLEN_C1 300 
#define LEN_C2 120
#define LEN_B_ 10240
#define LEN_B_C 10368
#define WLEN_B_C 324
#define LEN_b 9600
#define LEN_B__ 10240
#define LEN_S_ 10240
#define LEN_SK 19888
#define LEN_PKH 16
#define LEN_PK 9616
#define LEN_CT 9752
#define LEN_PKH_U_SALT 64
#define WLEN_PRNDSTR 644
#define LEN_PRNDSTR 20608
#define LEN_MATRIX_S 10240
#define LEN_MATRIX_S_ 10240
#define WLEN_MATRIX_S_ 320
#define WLEN_MATRIX_E_ 320

#elif (FRODO_N == 976)

#define LEN_SEED_PRNDSTR 49
#define LEN_DIG_SEEDSE_K 72
#define WLEN_DIG_SEEDSE_K 3
#define LEN_SALT 48
#define LEN_SEC 24
#define LEN_SEEDSE 48
#define LEN_C1 15616
#define WLEN_C1 488
#define LEN_C2 128
#define LEN_B_ 15616
#define LEN_B_C 15744
#define WLEN_B_C 492
#define LEN_b 15616
#define WLEN_b 488
#define LEN_B__ 15616
#define LEN_S_ 15616
#define LEN_SK 31296
#define LEN_PK 15632
#define LEN_PKH 24
#define LEN_CT 15792 
#define LEN_PKH_U_SALT 96
#define WLEN_PRNDSTR 980
#define LEN_PRNDSTR 31360
#define LEN_MATRIX_S 15616
#define WLEN_MATRIX_S 488
#define LEN_MATRIX_S_ 15616
#define WLEN_MATRIX_S_ 488
#define WLEN_MATRIX_E_ 488

#else

#define LEN_SEED_PRNDSTR 65
#define LEN_DIG_SEEDSE_K 96
#define WLEN_DIG_SEEDSE_K 3
#define LEN_SALT 64
#define LEN_SEC 32
#define LEN_SEEDSE 64
#define LEN_C1 21504
#define WLEN_C1 672
#define LEN_C2 128
#define LEN_B_ 21504
#define WLEN_B_ 672
#define LEN_B_C 21632
#define WLEN_B_C 676
#define LEN_b 21504
#define WLEN_b 672
#define LEN_B__ 21504
#define LEN_S_ 21504
#define LEN_SK 43088
#define LEN_PK 21520
#define LEN_PKH 32
#define LEN_CT 21696 
#define LEN_PKH_U_SALT 128
#define WLEN_PRNDSTR 1348
#define LEN_PRNDSTR 43136
#define LEN_MATRIX_S 21504
#define WLEN_MATRIX_S 672
#define WLEN_MATRIX_B__ 672
#define LEN_MATRIX_S_ 21504
#define WLEN_MATRIX_S_ 672
#define WLEN_MATRIX_E_ 672

#endif

.section .text
.global Decaps
Decaps:

add xt_A, xarg0, x0

bn.xor  bn0, bn0, bn0
li idx_wresult, 15

#if (FRODO_N == 640)
/* set modulo FRODO_Q in WDR MOD = 2^15 */
bn.addi w0, bn0, 1
loopi 15, 1
    bn.add w0, w0, w0 
bn.wsrw MOD, w0
#else
bn.wsrw MOD, bn0
#endif

/* Masks */
bn.subi wones, bn0, 1            
bn.or   wmask_low_ffff, bn0, wones >> 240   
bn.or   wmask_high_ffff, bn0, wones << 240

/* Load ptr to free memory */
la xaddr_free, addr_free


/*********************************************************/
/**************** B' = Unpack(c1) ************************/
/*********************************************************/


li xarg0, LEN_C1
la xarg1, ciphertext
add xarg2, xaddr_free, x0
jal x1, unpack

add x20, xaddr_free, x0 # save ptr to start of B'

/* Update ptr to free memory */
li t0, LEN_B_
add xaddr_free, xaddr_free, t0

/*********************************************************/
/************************ M = B'S ************************/
/*********************************************************/

#if (FRODO_N==640)

add xarg0, x20, x0 # ptr to B'
li xarg1, FRODO_N_BAR # rows B'
li xarg2, FRODO_N # cols B'
li t0, LEN_SEC
li t1, LEN_PK
add t0, t0, t1
la t1, secret_key
add xarg3, t0, t1 # ptr to S_T
add xarg4, xaddr_free, x0
jal x1, matrix_matrix_mult

add x22, xaddr_free, x0 # save ptr to start of B'S

/* Update ptr to free memory */
addi xaddr_free, xaddr_free, LEN_SQ_NBAR

#elif (FRODO_N==976)

#### relocate secret matrix S_T since len(s|seedA|b) is not 32-byte aligned ####

la t0, secret_key
li t1, 15648 # floor((lensec+lenpk)/32)*32
add t0, t0, t1 # points at DMEM=[low..high]=[pk[-8:]|S[:24]]

add x22, xaddr_free, x0 # save ptr to start of relocated S

bn.lid x0, 0(t0++) # S[:24]|pk[-8:]
bn.rshi w0, bn0, w0 >> 64 # 0x0..|S[:24]
bn.rshi wresult, w0, bn0 >> 192 # S[:24]|0x0..
loopi WLEN_MATRIX_S, 5
    bn.lid x0, 0(t0++) # S[32:56]|S[24:32]
    bn.rshi wresult, w0, wresult >> 64 # S[:32]
    bn.sid idx_wresult, 0(xaddr_free++)
    bn.rshi w0, bn0, w0 >> 64 # 0x0..|S[32:56]
    bn.rshi wresult, w0, bn0 >> 192 # S[32:56]|0x0..

add xarg0, x20, x0 # ptr to B'
li xarg1, FRODO_N_BAR # rows B'
li xarg2, FRODO_N # cols B'
add xarg3, x22, x0 # ptr to S_T
add xarg4, xaddr_free, x0
jal x1, matrix_matrix_mult

add x23, xaddr_free, x0 # save ptr to multiplication result B'S

### free space of relocated S ###
add xaddr_free, x22, x0 

### relocate B'S to freed memory ###
add x22, xaddr_free, x0 # save ptr to relocated multiplication result B'S
loopi WLEN_SQ_NBAR, 2
    bn.lid x0, 0(x23++)
    bn.sid x0, 0(xaddr_free++)

#else

#### relocate secret matrix S_T since len(s|seedA|b) is not 32-byte aligned ####

li t0, LEN_SEC
li t1, LEN_PK
add t0, t0, t1
li t1, 16
sub t0, t0, t1 
la t1, secret_key
add t0, t0, t1 # ptr to DMEM=[low..high]=[pk[-16:]|S[:16]]

add x22, xaddr_free, x0 # ptr to relocated S_T

bn.lid x0, 0(t0++) # S[:16]|pk[-16:]
bn.mov wresult, w0
loopi WLEN_MATRIX_S, 4
    bn.lid x0, 0(t0++) # S[32:48]|S[16:32]
    bn.rshi wresult, w0, wresult >> 128
    bn.sid idx_wresult, 0(xaddr_free++)
    bn.mov wresult, w0

add xarg0, x20, x0 # ptr to B'
li xarg1, FRODO_N_BAR
li xarg2, FRODO_N
add xarg3, x22, x0 # ptr to relocated S_T
add xarg4, xaddr_free, x0
jal x1, matrix_matrix_mult

add x23, xaddr_free, x0 # save ptr to multiplication result B'S

### free space of relocated S ###
add xaddr_free, x22, x0 

### relocate B'S to freed memory ###
add x22, xaddr_free, x0 # save ptr to relocated multiplication result B'S
loopi WLEN_SQ_NBAR, 2
    bn.lid x0, 0(x23++)
    bn.sid x0, 0(xaddr_free++)

#endif

/*********************************************************/
/*********************** neg(B'S) ************************/
/*********************************************************/


add t0, x22, x0 # ptr to B'S
bn.shv.16H w1, wones >> 15
loopi WLEN_SQ_NBAR, 4 
    bn.lid x0, 0(t0)
    bn.xor wresult, w0, wones # invert bits
    bn.addvm.16H wresult, wresult, w1 # add one to each tile
    bn.sid idx_wresult, 0(t0++) 


/*********************************************************/
/***************** C = Unpack(c2) ************************/
/*********************************************************/


li xarg0, LEN_C1 
la t0, ciphertext
li t1, LEN_C1
add xarg1, t0, t1
add xarg2, xaddr_free, x0 
jal x1, unpack 


add x23, xaddr_free, x0 # save ptr to start of C

/*********************************************/
/*********************************************/
/*********************************************/

addi t0, xaddr_free, 128
bn.mov w0, bn0
loopi 100, 1
    bn.sid x0, 0(t0++)

/*********************************************/
/*********************************************/


/*********************************************************/
/***************** Addition M = C-B'S ********************/
/*********************************************************/

add t0, x22, x0
add t1, x23, x0
loopi WLEN_SQ_NBAR, 4 
    bn.lid x0, 0(t0)
    bn.lid idx_wresult, 0(t1++)
    bn.addvm.16H wresult, wresult, w0
    bn.sid idx_wresult, 0(t0++)

/*********************************************************/
/***************** u' = Decode(M) ************************/
/*********************************************************/
    
add xarg0, x22, x0
jal x1, decode

bn.mov wu_, wresult

/*********************************************************/
/***************** B'||C *********************************/
/*********************************************************/

li t0, LEN_B_
add t0, t0, x20 # points to the end of B'
loopi WLEN_SQ_NBAR, 2
    bn.lid x0, 0(x23++)
    bn.sid x0, 0(t0++)

/**************** Update ptr to free memory **************/
li t0, LEN_B_C
add xaddr_free, x20, t0

/*********************************************************/
/************** pkh|u'|salt ******************************/
/*********************************************************/

add x23, xaddr_free, x0 # sets ptr for pkh|u'|salt

#if (FRODO_N == 640)

li t0, LEN_SK
li t1, LEN_PKH
sub t0, t0, t1 
la t1, secret_key
add t2, t0, t1 # ptr to pkh

li t0, LEN_CT
li t1, LEN_SALT
sub t0, t0, t1
li t1, 24
sub t0, t0, t1 # now it is divisible by 32 bytes
la t1, ciphertext
add x22, t0, t1 # ptr to DMEM = c2[-24:]|salt[:8]

bn.lid x0, 0(t2) # [xxxx|pkh[:16]]
bn.rshi w0, w0, bn0 >> 128 # [pkh|xxxx]
bn.rshi wresult, wu_, w0 >> 128 # [u'|pkh]

add t2, xaddr_free, x0
bn.sid idx_wresult, 0(t2++) # stores pkh|u'

bn.lid x0, 0(x22++) # [salt[:8]|c2[-24:]]
bn.lid idx_wresult, 0(x22++) # [xxxx|salt[8:32]]
bn.rshi wresult, wresult, w0 >> 192
bn.sid idx_wresult, 0(t2++) # stores salt
bn.mov wsalt_0, wresult

#elif (FRODO_N == 976)
la t1, secret_key
li t0, LEN_SK
add t0, t0, t1
li t1, 32
sub t0, t0, t1 # ptr to DMEM=[low..high]=[S_T[-8:]|pkh]

bn.lid x0, 0(t0) # pkh|S_T[:-8]
bn.rshi wresult, wu_, w0 >> 64 # u'[:8]|pkh

add t2, xaddr_free, x0
bn.sid idx_wresult, 0(t2++)


li t0, LEN_CT
li t1, LEN_SALT
sub t0, t0, t1
la t1, ciphertext
add t0, t0, t1 # ptr to DMEM=[low..high]=[salt[:32]]

bn.lid x0, 0(t0++) # salt[:32]
bn.mov wsalt_0, w0
bn.rshi w1, wu_, bn0 >> 192 # u'[:24]|0 
bn.rshi wresult, w0, w1 >> 128 # salt[:16]|u'[8:24]
bn.sid idx_wresult, 0(t2++)

bn.mov wresult, w0
bn.lid x0, 0(t0++) # 0x0..0|salt[32:48]
bn.rshi wresult, w0, wresult >> 128
bn.sid idx_wresult, 0(t2++)
bn.mov wsalt_1, wresult

#else 
la t1, secret_key
li t0, LEN_SK
add t0, t0, t1
li t1, 48
sub t0, t0, t1 # ptr to DMEM=[low..high]=[S_T[-16:]|pkh[:16]

bn.lid x0, 0(t0++) # pkh[:16]|S_T[:-16]
bn.lid idx_wresult, 0(t0) # xxxx|pkh[16:32]
bn.rshi wresult, wresult, w0 >> 128

add t2, xaddr_free, x0
bn.sid idx_wresult, 0(t2++) # pkh

bn.mov wresult, wu_
bn.sid idx_wresult, 0(t2++) # u'

li t0, LEN_CT
li t1, LEN_SALT
sub t0, t0, t1
la t1, ciphertext
add t0, t0, t1 # ptr to DMEM=[low..high]=[salt[:32]]

bn.lid idx_wresult, 0(t0++)
bn.sid idx_wresult, 0(t2++) # salt[:32]

bn.mov wsalt_0, wresult

bn.lid idx_wresult, 0(t0++)
bn.sid idx_wresult, 0(t2++) # salt[32:64]

bn.mov wsalt_1, wresult

#endif

/*********************************************************/
/************** SHAKE(pkh|u'|salt) ***********************/
/*********************************************************/

li xarg0, LEN_PKH_U_SALT
# la xarg1, addr_free
add xarg1, x23, x0
li xarg2, NEG_GENA
jal x1, ctx_shake


li xarg0, WLEN_DIG_SEEDSE_K
li xarg1, 0
# la xarg2, addr_free
add xarg2, x23, x0
jal x1, squeeze_shake # B'|C|seedSE|k|xaddr_free

/*********************************************************/
/************** 0x96||seedSE *****************************/
/*********************************************************/

add t0, x23, x0 # ptr to seedSE'||k'

#if (FRODO_N == 640)

# la t0, addr_free
bn.lid x0, 0(t0)
bn.addi w1, bn0, 0x96
bn.or w2, bn0, w0 << 8
bn.or wresult, w2, w1
bn.sid idx_wresult, 0(t0++) # DMEM[0x96|seedSE[:31]]

bn.or wresult, bn0, w0 >> 248 # 0x0..0|seedSE[:-1]

bn.lid x0, 0(t0) # save k before storing data. Only the lowest 16 bytes are valid
bn.mov wk_, w0

bn.sid idx_wresult, 0(t0++) # DMEM[seedSE[:-1]|0x0..0]

#elif (FRODO_N == 976)

# la t0, addr_free
bn.lid x0, 0(t0)
bn.addi w1, bn0, 0x96
bn.or w2, bn0, w0 << 8
bn.or wresult, w2, w1
bn.sid idx_wresult, 0(t0++) # DMEM[0x96|seedSE[:31]]

bn.lid idx_wresult, 0(t0) # k[:16]|seedSE[32:48]
bn.mov wk_, wresult

bn.rshi wresult, wresult, w0 >> 248 # xxx|seedSE[31:48]
bn.sid idx_wresult, 0(t0++) # DMEM[seedSE[31:48]|xxx]

bn.lid x0, 0(t0++) # xxxx|k[16:24]
bn.rshi wk_, w0, wk_ >> 128

#else

# la t0, addr_free
bn.lid x0, 0(t0) # seedSE[:32]
bn.addi w1, bn0, 0x96
bn.or w2, bn0, w0 << 8
bn.or wresult, w2, w1
bn.sid idx_wresult, 0(t0++) # DMEM[0x96|seedSE[:31]]

bn.lid idx_wresult, 0(t0) # seedSE[32:64]
bn.rshi w0, wresult, w0 >> 248 # seedSE[32:63]
bn.sid x0, 0(t0++)

bn.lid x0, 0(t0) # save k before storing data. 
bn.mov wk_, w0

bn.rshi wresult, bn0, wresult >> 248 # 0x0..0|seedSE[:64]
bn.sid idx_wresult, 0(t0++)

#endif

# B'|C|x23->0x96|seedSE'
add xaddr_free, x23, x0 # 0x96|seedSE will be overwritten

#if (FRODO_N == 640)

/*********************************************************/
/************** SHAKE(0x96||seedSE) ***********************/
/*********************************************************/

li xarg0, LEN_SEED_PRNDSTR
# la xarg1, addr_free
add xarg1, x23, x0
li xarg2, NEG_GENA
jal x1, ctx_shake

li xarg0, WLEN_PRNDSTR
li xarg1, 0
# la xarg2, addr_free
add xarg2, x23, x0
jal x1, squeeze_shake

/*********************************************************/
/************ S',E',E'' <- Sample(prndtr) ****************/
/*********************************************************/

# la xarg0, addr_free
add xarg0, x23, x0
li xarg1, WLEN_PRNDSTR
# la xarg2, addr_free
add xarg2, x23, x0
jal x1, inverse_sampler 

#elif (FRODO_N == 976)

/*********************************************************/
/************** SHAKE(0x96||seedSE) ***********************/
/*********************************************************/

li xarg0, LEN_SEED_PRNDSTR
# la xarg1, addr_free
add xarg1, x23, x0
li xarg2, NEG_GENA
jal x1, ctx_shake

li xarg0, WLEN_PRNDSTR
li xarg1, 0
# la xarg2, addr_free
add xarg2, x23, x0
jal x1, squeeze_shake

/*********************************************************/
/************ S',E',E'' <- Sample(prndtr) ****************/
/*********************************************************/

# la xarg0, addr_free
add xarg0, x23, x0
li xarg1, WLEN_PRNDSTR
# la xarg2, addr_free
add xarg2, x23, x0
jal x1, inverse_sampler

#else

# B'|C|x23->0x96|seedSE'

## update free address ##
li t0, 96
add xaddr_free, x23, t0 # B'|C|0x96|seedSE'|xaddr_free

/*********************************************************/
/************** r_S' <- SHAKE(0x96||seedSE) ***************/
/*********************************************************/

li xarg0, LEN_SEED_PRNDSTR
add xarg1, x23, x0 # ptr to 0x96||seedSE
li xarg2, NEG_GENA
jal x1, ctx_shake

li xarg0, WLEN_MATRIX_S_
li xarg1, 0
## update x23 ##
li t0, 96 # lenSE+32B
add x23, x23, t0
add xarg2, x23, x0 
jal x1, squeeze_shake

/*********************************************************/
/************ S' <- Sample(prndtr) ***********************/
/*********************************************************/

add xarg0, x23, x0
li xarg1, WLEN_MATRIX_S_
add xarg2, x23, x0
jal x1, inverse_sampler 

/*********************************************************/
/******************** WDR <- seedA ***********************/
/*********************************************************/

la t0, secret_key
li t1, 32
add t0, t0, t1
bn.lid x0, 0(t0) # xxxx|seedA[:16]
bn.rshi wseedA, w0, bn0 >> 128 # seedA[:16]|0x0..0
bn.rshi wseedA, bn0, wseedA >> 128 # 0x0..0|seedA[:16]

/*********************************************************/
/******************** S'A ********************************/
/*********************************************************/

## S_T[16:] and pkh[:16] will get overwritten with S'A ##
la t0, secret_key
li t1, 21568 # len(s+seedA+b)+16 for 32B-alignment
add t0, t0, t1 # ptr to S_T[16:]||pkh

/**************clean output area*************************/
/**************!!!!REQUIRED!!!!!*************************/
add t1, t0, x0
bn.mov wresult, bn0
loopi WLEN_MATRIX_B__, 1
    bn.sid idx_wresult, 0(t1++)

add x28, t0, x0 # xaddr_matrix_B__ 
add x27, t0, x0 # output address (used internally by mult SA)

add x26, xaddr_free, x0 # xaddr_matrix_A
add x22, x23, x0 # save ptr to sampled S' in x22 because mult_SA overwrites x23
add x25, x22, x0 # xaddr_buf_sampled
jal x1, mult_SA

# replace back addr to sampled bytes #
add x23, x22, x0

/*********************************************************/
/******* r_E'|r_E'' <- SHAKE(0x96||seedSE) ***************/
/*********************************************************/

## update free address ##
add xaddr_free, x23, x0 # B'|C|0x96|seedSE'|xaddr_free

li xarg0, LEN_SEED_PRNDSTR
li t0, 96
sub xarg1, x23, t0 # ptr to 0x96||seedSE
li xarg2, NEG_GENA
jal x1, ctx_shake

li xarg0, WLEN_PRNDSTR
li xarg1, LEN_MATRIX_S_
add xarg2, x23, x0 
jal x1, squeeze_shake

/*********************************************************/
/************ E'|E'' <- Sample(prndtr) ***********************/
/*********************************************************/

add xarg0, x23, x0
li t0, WLEN_MATRIX_E_
li t1, 4 # wsize E''
add xarg1, t0, t1
add xarg2, x23, x0
jal x1, inverse_sampler 

/*********************************************************/
/************** B'' = S'A + E' ***************************/
/*********************************************************/

add xarg0, x28, x0 # ptr to S'A
# li t1, LEN_MATRIX_S_
add xarg1, x23, x0 # ptr to E'
li xarg2, WLEN_MATRIX_E_ 
jal x1, matrix_matrix_add

/*********************************************************/
/****************** relocate b ***************************/
/*********************************************************/

### load seed s to WDR ###
la t0, secret_key
bn.lid idx_wresult, 0(t0++)
bn.mov wseed_s, wresult

bn.lid idx_wresult, 0(t0++) # b[:16]|seedA
la t1, secret_key
loopi WLEN_b, 4
    bn.lid x0, 0(t0++)
    bn.rshi wresult, w0, wresult >> 128
    bn.sid idx_wresult, 0(t1++)
    bn.mov wresult, w0


/*********************************************************/
/************** B = Unpack(b) ***************************/
/*********************************************************/

li xarg0, LEN_b
la xarg1, secret_key
la xarg2, secret_key
jal x1, unpack


/*********************************************************/
/************** r_S' <- SHAKE(0x96||seedSE) ***************/
/*********************************************************/

## update free address ##
la t0, addr_free
li t1, LEN_B_
add t0, t0, t1
addi xaddr_free, t0, 224 # +len(C)+len(0x96|seedSE')
li t0, 96
sub x23, xaddr_free, t0 # ptr to 0x96||seedSE

li xarg0, LEN_SEED_PRNDSTR
add xarg1, x23, x0 # ptr to 0x96||seedSE
li xarg2, NEG_GENA
jal x1, ctx_shake

li xarg0, WLEN_MATRIX_S_
li xarg1, 0
## update x23 ##
li t0, 96 # lenSE+32B
add x23, x23, t0
add xarg2, x23, x0 
jal x1, squeeze_shake

addi xaddr_free, xaddr_free, LEN_SQ_NBAR # ...rS'|E''|xaddr_free

/*********************************************************/
/************ S' <- Sample(prndtr) ***********************/
/*********************************************************/

add xarg0, x23, x0
li xarg1, WLEN_MATRIX_S_
add xarg2, x23, x0
jal x1, inverse_sampler

/*********************************************************/
/************************ S'B ****************************/
/*********************************************************/

add x22, x23, x0 # for coherence but actually irrelevant

add xarg0, x22, x0 # ptr to S'
li t1, LEN_S_
la xarg1, secret_key # ptr to B
add xarg2, xaddr_free, x0 # output
jal x1, mult_SB

addi xaddr_free, xaddr_free, LEN_SQ_NBAR # ...S'|E''|S'B|xaddr_free

/*********************************************************/
/************************ E'' ****************************/
/*********************************************************/

li t0, LEN_SQ_NBAR
slli t0, t0, 1 
sub x23, xaddr_free, t0 # ptr to E''

/*********************************************************/
/********************** V = S'B + E'' ********************/
/*********************************************************/
li t0, LEN_SQ_NBAR
sub xarg0, xaddr_free, t0 # ptr to start of S'B
add xarg1, x23, x0
li xarg2, WLEN_SQ_NBAR
jal x1, matrix_matrix_add # ...S'|E''|V|xaddr_free

li t0, LEN_SQ_NBAR
sub x23, xaddr_free, t0 # saves ptr to V

/*********************************************************/
/********************** Encode(u') ********************/
/*********************************************************/

li xarg0, LEN_SEC
bn.mov wresult, wu_
bn.sid idx_wresult, 0(xaddr_free++)
li t0, 32
sub xarg1, xaddr_free, t0
add xarg2, xaddr_free, x0
jal x1, encode

/*********************************************************/
/**************** C' = V + Encode(u') ********************/
/*********************************************************/

add xarg0, x23, x0 # ptr to V
# li t0, LEN_SQ_NBAR
sub xarg1, xaddr_free, x0 # ptr to Encode(u')
li xarg2, WLEN_SQ_NBAR
jal x1, matrix_matrix_add

/*********************************************************/
/*********************** B'C == B''C' ********************/
/*********************************************************/

bn.mov wresult, bn0
la t0, addr_free # ptr to B'
add t1, x28, x0 # ptr to B''
li t2, 2
loopi WLEN_B_, 4
    bn.lid x0, 0(t0++)
    bn.lid t2, 0(t1++)
    bn.xor w0, w0, w2
    bn.or wresult, wresult, w0

loopi WLEN_SQ_NBAR, 4
    bn.lid x0, 0(t0++)
    bn.lid t2, 0(x23++)
    bn.xor w0, w0, w2
    bn.or wresult, wresult, w0

/*********************************************************/
/************ STORE FOR EASIER CHECK ********************/
/*********************************************************/

#### Corrupts B' ####
la t0, addr_free
bn.sid idx_wresult, 0(t0)

/*********************************************************/
/************ ----------------------- ********************/
/*********************************************************/

bn.cmp wresult, bn0

# constant time check
CSRRS t0, FG0, x0
srli t0, t0, 3 # t0 = Zero Flag
li t1, 1
bne t1, t0, return_seeds_1344
bn.mov wkbar, wk_
jal x0, compute_shared_secret_1344
return_seeds_1344:
bn.mov wkbar, wseed_s
jal x0, compute_shared_secret_1344
compute_shared_secret_1344:

/*********************************************************/
/************** ciphertext||wkbar ************************/
/*********************************************************/

### we append wkbar to ciphertext in DMEM ###

la t0, ciphertext
li t1, LEN_CT
add t0, t0, t1
bn.mov wresult, wkbar
bn.sid idx_wresult, 0(t0)

li t0, LEN_CT
li t1, LEN_SEC
add xarg0, t0, t1
la xarg1, ciphertext
li xarg2, NEG_GENA
jal x1, ctx_shake

li xarg0, 1
li xarg1, 0
add xarg2, xaddr_free, x0
jal x1, squeeze_shake

ret

#endif


/*********************************************************/
/******************** seedA -> WDR ***********************/
/*********************************************************/

#if (FRODO_N == 640)

la t0, secret_key
bn.lid x0, 0(t0) # seedA[:16]|s[:16]
bn.rshi wseedA, bn0, w0 >> 128

#elif (FRODO_N == 976)

la t0, secret_key
bn.lid x0, 0(t0++) # seedA[:8]|s[:24]
bn.lid idx_wresult, 0(t0) # xxxx|seedA[:8]
bn.rshi wseedA, wresult, w0 >> 192 # xxxx|seedA[:16]
bn.rshi wseedA, wseedA, bn0 >> 128 # seedA[:16]|0x0..0
bn.rshi wseedA, bn0, wseedA >> 128 # 0x0..0|seedA[:16]

#endif

/*********************************************************/
/******************** S'A ********************************/
/*********************************************************/

add x28, xaddr_free, x0 # xaddr_matrix_B__ 
add x27, xaddr_free, x0 # output address (used internally by mult SA)

/* reserve space for B'' */
li t0, LEN_B__
add xaddr_free, xaddr_free, t0

add x26, xaddr_free, x0 # xaddr_matrix_A
# la x25, addr_free # xaddr_buf_sampled
add x22, x23, x0 # save ptr to sampled S' in x22 because mult_SA overwrites x23
add x25, x22, x0 # xaddr_buf_sampled
jal x1, mult_SA

/*********************************************************/
/************** B'' = S'A + E' ***************************/
/*********************************************************/

add xarg0, x28, x0 # ptr to S'A
# la t0, addr_free
li t1, LEN_S_
add xarg1, x22, t1 # ptr to E'
li xarg2, WLEN_MATRIX_E_ 
jal x1, matrix_matrix_add

/*********************************************************/
/************** B = Unpack(b) ***************************/
/*********************************************************/

#if (FRODO_N == 640)

la t0, secret_key
li xarg0, LEN_b
li t1, 32
add xarg1, t0, t1 # ptr to b
li t1, LEN_S_
add xarg2, x22, t1 # ptr to E' to overwrite it with B
jal x1, unpack

#elif (FRODO_N == 976)

### relocate b for unpacking since it does not lie at a 32B aligned address ###

la t0, secret_key
li t1, 32
add t0, t0, t1 # ptr to seedA|b...
li t1, LEN_S_
add t1, x22, t1 # ptr to E' to overwrite it with b
bn.lid x0, 0(t0++)
loopi WLEN_b, 4
    bn.lid idx_wresult, 0(t0++)
    bn.rshi w0, wresult, w0 >> 64
    bn.sid x0, 0(t1++)
    bn.mov w0, wresult

### -------------------------------------------------------------------- ###

li xarg0, LEN_b
li t1, LEN_S_
add xarg1, x22, t1 # new ptr to b
add xarg2, xarg1, x0 # in-place unpacking
jal x1, unpack

#endif

/*********************************************************/
/************************ S'B ****************************/
/*********************************************************/

add xarg0, x22, x0 # ptr to S'
li t1, LEN_S_
add xarg1, x22, t1 # ptr to B
add xarg2, xaddr_free, x0
jal x1, mult_SB

/*********************************************************/
/************************ E'' ****************************/
/*********************************************************/

li t0, LEN_MATRIX_S
slli t0, t0, 1 # size of S'|E'
add x23, t0, x22 # ptr to E''

/*********************************************************/
/********************** V = S'B + E'' ********************/
/*********************************************************/

add xarg0, xaddr_free, x0 # ptr to start of S'B
add xarg1, x23, x0
li xarg2, WLEN_SQ_NBAR
jal x1, matrix_matrix_add

add x23, xaddr_free, x0 # saves ptr to V
addi xaddr_free, xaddr_free, LEN_SQ_NBAR

/*********************************************************/
/********************** Encode(u') ********************/
/*********************************************************/

li xarg0, LEN_SEC
bn.mov wresult, wu_
bn.sid idx_wresult, 0(xaddr_free++)
li t0, 32
sub xarg1, xaddr_free, t0
add xarg2, xaddr_free, x0
jal x1, encode

/*********************************************************/
/**************** C' = V + Encode(u') ********************/
/*********************************************************/

add xarg0, x23, x0 # ptr to V
# li t0, LEN_SQ_NBAR
sub xarg1, xaddr_free, x0 # ptr to Encode(u')
li xarg2, WLEN_SQ_NBAR
jal x1, matrix_matrix_add

####### ----------- relocate C' ------------- ######

li t0, LEN_B__
add t0, x28, t0 
loopi WLEN_SQ_NBAR, 2
    bn.lid x0, 0(x23++)
    bn.sid x0, 0(t0++)

/*********************************************************/
/*********************** B'C == B''C' ********************/
/*********************************************************/

bn.mov wresult, bn0
la t0, addr_free # ptr to B'
add t1, x28, x0 # ptr to B''
li t2, 2
loopi WLEN_B_C, 4
    bn.lid x0, 0(t0++)
    bn.lid t2, 0(t1++)
    bn.xor w0, w0, w2
    bn.or wresult, wresult, w0

/*********************************************************/
/************ STORE FOR EASIER CHECK ********************/
/*********************************************************/

#### Corrupts B' ####
la t0, addr_free
bn.sid idx_wresult, 0(t0)

/*********************************************************/
/************ ----------------------- ********************/
/*********************************************************/

bn.cmp wresult, bn0

### load seed s in w0 ###
la t0, secret_key
bn.lid x0, 0(t0)
#if (FRODO_N == 640)
bn.rshi w0, w0, bn0 >> 128
bn.rshi w0, bn0, w0 >> 128
#elif (FRODO_N == 976)
bn.rshi w0, w0, bn0 >> 192
bn.rshi w0, bn0, w0 >> 192
#endif

# constant time check
CSRRS t0, FG0, x0
srli t0, t0, 3 # t0 = Zero Flag
li t1, 1
bne t1, t0, return_seeds
bn.mov wkbar, wk_
jal x0, compute_shared_secret
return_seeds:
bn.mov wkbar, w0
jal x0, compute_shared_secret
compute_shared_secret:

/*********************************************************/
/************** ciphertext||wkbar ************************/
/*********************************************************/

### we append wkbar to ciphertext in DMEM ###
#if (FRODO_N == 640)

li t0, LEN_CT
la t1, ciphertext
add t0, t0, t1
li t1, 24
sub t0, t0, t1 
li t1, 1
bn.lid t1, 0(t0)
bn.rshi wresult, w1, bn0 >> 192 # erases bytes not belonging to ciphertext
bn.rshi wresult, wkbar, wresult >> 64
bn.sid idx_wresult, 0(t0++)
bn.rshi wresult, bn0, wkbar >> 64
bn.sid idx_wresult, 0(t0)

#elif (FRODO_N == 976)

li t0, LEN_CT
la t1, ciphertext
add t0, t0, t1
li t1, 16
sub t0, t0, t1 
li t1, 1
bn.lid t1, 0(t0)
bn.rshi wresult, w1, bn0 >> 128 # erases bytes not belonging to ciphertext
bn.rshi wresult, wkbar, wresult >> 128
bn.sid idx_wresult, 0(t0++)
bn.rshi wresult, bn0, wkbar >> 128
bn.sid idx_wresult, 0(t0)
#endif

li t0, LEN_CT
li t1, LEN_SEC
add xarg0, t0, t1
la xarg1, ciphertext
li xarg2, NEG_GENA
jal x1, ctx_shake

li xarg0, 1
li xarg1, 0
# add xarg2, xaddr_free, x0
la xarg2, addr_free 
jal x1, squeeze_shake

ret






















