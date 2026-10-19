--complete translation of lzma to lua with luajit features (works!)

--from lzma sdk's LzmaDec.c
--lzma sdk is licensed under the public domain

--set a custom environment to store constants so that
--we don't hit the upvalue limit (of 60!)
local lzma = setmetatable({}, {__index = _G})
setfenv(1, lzma)

--/* LzmaDec.c -- LZMA Decoder
--2023-04-07 : Igor Pavlov : Public domain */

--[[#include "Precomp.h"

#include <string.h>

/* #include "CpuArch.h" */
#include "LzmaDec.h"

// #define kNumTopBits 24
#define kTopValue ((UInt32)1 << 24)

#define kNumBitModelTotalBits 11
#define kBitModelTotal (1 << kNumBitModelTotalBits)

#define RC_INIT_SIZE 5

#ifndef Z7_LZMA_DEC_OPT

#define kNumMoveBits 5
#define NORMALIZE if (range < kTopValue) { range <<= 8; code = (code << 8) | (*buf++); }

#define IF_BIT_0(p) ttt = *(p); NORMALIZE; bound = (range >> kNumBitModelTotalBits) * (UInt32)ttt; if (code < bound)
#define UPDATE_0(p) range = bound; *(p) = (CLzmaProb)(ttt + ((kBitModelTotal - ttt) >> kNumMoveBits));
#define UPDATE_1(p) range -= bound; code -= bound; *(p) = (CLzmaProb)(ttt - (ttt >> kNumMoveBits));
#define GET_BIT2(p, i, A0, A1) IF_BIT_0(p) \
  { UPDATE_0(p)  i = (i + i); A0; } else \
  { UPDATE_1(p)  i = (i + i) + 1; A1; }

#define TREE_GET_BIT(probs, i) { GET_BIT2(probs + i, i, ;, ;); }

#define REV_BIT(p, i, A0, A1) IF_BIT_0(p + i) \
  { UPDATE_0(p + i)  A0; } else \
  { UPDATE_1(p + i)  A1; }
#define REV_BIT_VAR(  p, i, m) REV_BIT(p, i, i += m; m += m, m += m; i += m; )
#define REV_BIT_CONST(p, i, m) REV_BIT(p, i, i += m;       , i += m * 2; )
#define REV_BIT_LAST( p, i, m) REV_BIT(p, i, i -= m        , ; )

#define TREE_DECODE(probs, limit, i) \
  { i = 1; do { TREE_GET_BIT(probs, i); } while (i < limit); i -= limit; }

/* #define Z7_LZMA_SIZE_OPT */

#ifdef Z7_LZMA_SIZE_OPT
#define TREE_6_DECODE(probs, i) TREE_DECODE(probs, (1 << 6), i)
#else
#define TREE_6_DECODE(probs, i) \
  { i = 1; \
  TREE_GET_BIT(probs, i) \
  TREE_GET_BIT(probs, i) \
  TREE_GET_BIT(probs, i) \
  TREE_GET_BIT(probs, i) \
  TREE_GET_BIT(probs, i) \
  TREE_GET_BIT(probs, i) \
  i -= 0x40; }
#endif

#define NORMAL_LITER_DEC TREE_GET_BIT(prob, symbol)
#define MATCHED_LITER_DEC \
  matchByte += matchByte; \
  bit = offs; \
  offs &= matchByte; \
  probLit = prob + (offs + bit + symbol); \
  GET_BIT2(probLit, symbol, offs ^= bit; , ;)

#endif // Z7_LZMA_DEC_OPT


#define NORMALIZE_CHECK if (range < kTopValue) { if (buf >= bufLimit) return DUMMY_INPUT_EOF; range <<= 8; code = (code << 8) | (*buf++); }

#define IF_BIT_0_CHECK(p) ttt = *(p); NORMALIZE_CHECK bound = (range >> kNumBitModelTotalBits) * (UInt32)ttt; if (code < bound)
#define UPDATE_0_CHECK range = bound;
#define UPDATE_1_CHECK range -= bound; code -= bound;
#define GET_BIT2_CHECK(p, i, A0, A1) IF_BIT_0_CHECK(p) \
  { UPDATE_0_CHECK  i = (i + i); A0; } else \
  { UPDATE_1_CHECK  i = (i + i) + 1; A1; }
#define GET_BIT_CHECK(p, i) GET_BIT2_CHECK(p, i, ; , ;)
#define TREE_DECODE_CHECK(probs, limit, i) \
  { i = 1; do { GET_BIT_CHECK(probs + i, i) } while (i < limit); i -= limit; }


#define REV_BIT_CHECK(p, i, m) IF_BIT_0_CHECK(p + i) \
  { UPDATE_0_CHECK  i += m; m += m; } else \
  { UPDATE_1_CHECK  m += m; i += m; }


#define kNumPosBitsMax 4
#define kNumPosStatesMax (1 << kNumPosBitsMax)

#define kLenNumLowBits 3
#define kLenNumLowSymbols (1 << kLenNumLowBits)
#define kLenNumHighBits 8
#define kLenNumHighSymbols (1 << kLenNumHighBits)

#define LenLow 0
#define LenHigh (LenLow + 2 * (kNumPosStatesMax << kLenNumLowBits))
#define kNumLenProbs (LenHigh + kLenNumHighSymbols)

#define LenChoice LenLow
#define LenChoice2 (LenLow + (1 << kLenNumLowBits))

#define kNumStates 12
#define kNumStates2 16
#define kNumLitStates 7

#define kStartPosModelIndex 4
#define kEndPosModelIndex 14
#define kNumFullDistances (1 << (kEndPosModelIndex >> 1))

#define kNumPosSlotBits 6
#define kNumLenToPosStates 4

#define kNumAlignBits 4
#define kAlignTableSize (1 << kNumAlignBits)

#define kMatchMinLen 2
#define kMatchSpecLenStart (kMatchMinLen + kLenNumLowSymbols * 2 + kLenNumHighSymbols)

#define kMatchSpecLen_Error_Data (1 << 9)
#define kMatchSpecLen_Error_Fail (kMatchSpecLen_Error_Data - 1)

/* External ASM code needs same CLzmaProb array layout. So don't change it. */

/* (probs_1664) is faster and better for code size at some platforms */
/*
#ifdef MY_CPU_X86_OR_AMD64
*/
#define kStartOffset 1664
#define GET_PROBS p->probs_1664
/*
#define GET_PROBS p->probs + kStartOffset
#else
#define kStartOffset 0
#define GET_PROBS p->probs
#endif
*/

#define SpecPos (-kStartOffset)
#define IsRep0Long (SpecPos + kNumFullDistances)
#define RepLenCoder (IsRep0Long + (kNumStates2 << kNumPosBitsMax))
#define LenCoder (RepLenCoder + kNumLenProbs)
#define IsMatch (LenCoder + kNumLenProbs)
#define Align (IsMatch + (kNumStates2 << kNumPosBitsMax))
#define IsRep (Align + kAlignTableSize)
#define IsRepG0 (IsRep + kNumStates)
#define IsRepG1 (IsRepG0 + kNumStates)
#define IsRepG2 (IsRepG1 + kNumStates)
#define PosSlot (IsRepG2 + kNumStates)
#define Literal (PosSlot + (kNumLenToPosStates << kNumPosSlotBits))
#define NUM_BASE_PROBS (Literal + kStartOffset)

#if Align != 0 && kStartOffset != 0
  #error Stop_Compiling_Bad_LZMA_kAlign
#endif

#if NUM_BASE_PROBS != 1984
  #error Stop_Compiling_Bad_LZMA_PROBS
#endif


#define LZMA_LIT_SIZE 0x300

#define LzmaProps_GetNumProbs(p) (NUM_BASE_PROBS + ((UInt32)LZMA_LIT_SIZE << ((p)->lc + (p)->lp)))


#define CALC_POS_STATE(processedPos, pbMask) (((processedPos) & (pbMask)) << 4)
#define COMBINED_PS_STATE (posState + state)
#define GET_LEN_STATE (posState)

#define LZMA_DIC_MIN (1 << 12)

/*
p->remainLen : shows status of LZMA decoder:
    < kMatchSpecLenStart  : the number of bytes to be copied with (p->rep0) offset
    = kMatchSpecLenStart  : the LZMA stream was finished with end mark
    = kMatchSpecLenStart + 1  : need init range coder
    = kMatchSpecLenStart + 2  : need init range coder and state
    = kMatchSpecLen_Error_Fail                : Internal Code Failure
    = kMatchSpecLen_Error_Data + [0 ... 273]  : LZMA Data Error
*/

/* ---------- LZMA_DECODE_REAL ---------- */
/*
LzmaDec_DecodeReal_3() can be implemented in external ASM file.
3 - is the code compatibility version of that function for check at link time.
*/

#define LZMA_DECODE_REAL LzmaDec_DecodeReal_3

/*
LZMA_DECODE_REAL()
In:
  RangeCoder is normalized
  if (p->dicPos == limit)
  {
    LzmaDec_TryDummy() was called before to exclude LITERAL and MATCH-REP cases.
    So first symbol can be only MATCH-NON-REP. And if that MATCH-NON-REP symbol
    is not END_OF_PAYALOAD_MARKER, then the function doesn't write any byte to dictionary,
    the function returns SZ_OK, and the caller can use (p->remainLen) and (p->reps[0]) later.
  }

Processing:
  The first LZMA symbol will be decoded in any case.
  All main checks for limits are at the end of main loop,
  It decodes additional LZMA-symbols while (p->buf < bufLimit && dicPos < limit),
  RangeCoder is still without last normalization when (p->buf < bufLimit) is being checked.
  But if (p->buf < bufLimit), the caller provided at least (LZMA_REQUIRED_INPUT_MAX + 1) bytes for
  next iteration  before limit (bufLimit + LZMA_REQUIRED_INPUT_MAX),
  that is enough for worst case LZMA symbol with one additional RangeCoder normalization for one bit.
  So that function never reads bufLimit [LZMA_REQUIRED_INPUT_MAX] byte.

Out:
  RangeCoder is normalized
  Result:
    SZ_OK - OK
      p->remainLen:
        < kMatchSpecLenStart : the number of bytes to be copied with (p->reps[0]) offset
        = kMatchSpecLenStart : the LZMA stream was finished with end mark

    SZ_ERROR_DATA - error, when the MATCH-Symbol refers out of dictionary
      p->remainLen : undefined
      p->reps[*]    : undefined
*/
]]

--LzmaDec.h
LZMA_PROPS_SIZE = 5
LZMA_REQUIRED_INPUT_MAX = 20

ffi.cdef[[
typedef enum
{
  LZMA_STATUS_NOT_SPECIFIED,               /* use main error code instead */
  LZMA_STATUS_FINISHED_WITH_MARK,          /* stream was finished with end mark. */
  LZMA_STATUS_NOT_FINISHED,                /* stream was not finished */
  LZMA_STATUS_NEEDS_MORE_INPUT,            /* you must provide more input bytes */
  LZMA_STATUS_MAYBE_FINISHED_WITHOUT_MARK  /* there is probability that stream was finished without end mark */
} ELzmaStatus;

typedef enum
{
  LZMA_FINISH_ANY,   /* finish at any point */
  LZMA_FINISH_END    /* block must be finished at the end */
} ELzmaFinishMode;

typedef unsigned char Byte;
typedef short Int16;
typedef unsigned short UInt16;
typedef int Int32;
typedef unsigned int UInt32;

typedef size_t SizeT;

typedef
//#ifdef Z7_LZMA_PROB32
  UInt32
//#else
  //UInt16
//#endif
  CLzmaProb;

typedef struct
{
  Byte lc;
  Byte lp;
  Byte pb;
  Byte _pad_;
  UInt32 dicSize;
} CLzmaProps;

typedef struct
{
  /* Don't change this structure. ASM code can use it. */
  CLzmaProps prop;
  CLzmaProb *probs;
  CLzmaProb *probs_1664;
  Byte *dic;
  SizeT dicBufSize;
  SizeT dicPos;
  const Byte *buf;
  UInt32 range;
  UInt32 code;
  UInt32 processedPos;
  UInt32 checkDicSize;
  UInt32 reps[4];
  UInt32 state;
  UInt32 remainLen;

  UInt32 numProbs;
  unsigned tempBufSize;
  Byte tempBuf[/*LZMA_REQUIRED_INPUT_MAX*/ 20];
} CLzmaDec;
]]

local function LzmaDec_CONSTRUCT(p) (p).dic = nil; (p).probs = nil; end
local function LzmaDec_Construct(p) LzmaDec_CONSTRUCT(p) end

--from 7zTypes.h
SZ_OK = 0

SZ_ERROR_DATA = 1
SZ_ERROR_MEM = 2
SZ_ERROR_CRC = 3
SZ_ERROR_UNSUPPORTED = 4
SZ_ERROR_PARAM = 5
SZ_ERROR_INPUT_EOF = 6
SZ_ERROR_OUTPUT_EOF = 7
SZ_ERROR_READ = 8
SZ_ERROR_WRITE = 9
SZ_ERROR_PROGRESS = 10
SZ_ERROR_FAIL = 11
SZ_ERROR_THREAD = 12

SZ_ERROR_ARCHIVE = 16
SZ_ERROR_NO_ARCHIVE = 17

local p
local bufLimit
local posState, state
local range
local code
local prob, bound

local buf

local symbol
local offs

local bit, probLit

local ttt --

local matchByte

kTopValue = (1 << 24)

RC_INIT_SIZE = 5

kNumMoveBits = 5

kNumBitModelTotalBits = 11
kBitModelTotal = (1 << kNumBitModelTotalBits)

UInt32 = ffi.typeof("UInt32")

local function NORMALIZE()
	if (range < kTopValue) then
		range <<= 8;
		--code = (code << 8) | (*buf++);
		code = (code << 8) | buf[0];
		code = ffi.new("UInt32", code)
		buf += 1;
	end
end

local function IF_BIT_0(p)
	ttt = (p)[0];
	NORMALIZE();
	bound = UInt32((range >> kNumBitModelTotalBits) * ttt);
	return (code < bound)
end

local function UPDATE_0(p)
	range = UInt32(bound);
	--*(p) = (CLzmaProb)(ttt + ((kBitModelTotal - ttt) >> kNumMoveBits));
	p[0] = (ttt + ((kBitModelTotal - ttt) >> kNumMoveBits));
end

local function UPDATE_1(p)
	range = UInt32(range - bound);
	code = UInt32(code - bound);
	--*(p) = (CLzmaProb)(ttt - (ttt >> kNumMoveBits));
	p[0] = (ttt - (ttt >> kNumMoveBits));
end
local function GET_BIT2(p, i, A0, A1)
	if IF_BIT_0(p) then
		UPDATE_0(p)
		i = (i + i);
		if A0 then A0() end
	else
		UPDATE_1(p)
		i = (i + i) + 1;
		if A1 then A1() end
	end
	
	return i
end

local function TREE_GET_BIT(probs, i)
	return GET_BIT2(probs + i, i, nil, nil);
end

local function REV_BIT(p, i, A0, A1)
	if IF_BIT_0(p + i) then
		UPDATE_0(p + i)
		if A0 then A0(); end
	else
		UPDATE_1(p + i)
		if A1 then A1() end
	end
end
local function i_pe_m() i += m end
local function offs_xe_bit() offs ~= bit end --this is xor, not unequal
local function offs_xe_bit() offs ~= bit end --this is xor, not unequal
local function REV_BIT_VAR(  p, i, m)
	REV_BIT(p, i, function() i += m m += m end, function() m += m i += m end)
	return i, m
end
local function REV_BIT_CONST(p, i, m)
	REV_BIT(p, i, function() i += m end, function() i += m * 2 end)
	return i, m
end
local function REV_BIT_LAST( p, i, m)
	REV_BIT(p, i, function() i -= m end, nil)
	return i, m
end

local function TREE_DECODE(probs, limit, i)
	i = 1;
	repeat
		i = TREE_GET_BIT(probs, i);
	until not (i < limit);
	i -= limit
	
	return i
end

local function TREE_6_DECODE(probs, i)
  i = 1;
  i = TREE_GET_BIT(probs, i)
  i = TREE_GET_BIT(probs, i)
  i = TREE_GET_BIT(probs, i)
  i = TREE_GET_BIT(probs, i)
  i = TREE_GET_BIT(probs, i)
  i = TREE_GET_BIT(probs, i)
  i -= 0x40;
  
  return i
end

local function NORMAL_LITER_DEC()
	symbol = TREE_GET_BIT(prob, symbol)
end
local function offs_xe_bit() offs ~= bit end --this is xor, not unequal
local function MATCHED_LITER_DEC()
	matchByte += matchByte;
	bit = offs;
	offs &= matchByte;
	probLit = prob + (offs + bit + symbol);
	symbol = GET_BIT2(probLit, symbol, offs_xe_bit, nil)
end

local function NORMALIZE_CHECK()
	if (range < kTopValue) then
		if (buf >= bufLimit) then
			return ffi.C.DUMMY_INPUT_EOF;
		end
		range = UInt32(range << 8);
		--code = (code << 8) | (*buf++);
		code = UInt32((code << 8) | buf[0]);
		buf += 1;
	end
end

local normalize_return_hack --normalize return hack

local function clear_nrh()
	local nrh = normalize_return_hack
	normalize_return_hack = nil
	
	return nrh
end

local function IF_BIT_0_CHECK(p)
	ttt = (p)[0];
	normalize_return_hack = NORMALIZE_CHECK() or normalize_return_hack
	if normalize_return_hack then return true end
	bound = (range >> kNumBitModelTotalBits) * ttt;
	return (code < bound)
end
local function UPDATE_0_CHECK() range = bound; end
local function UPDATE_1_CHECK() range -= bound; range = ffi.new("UInt32", range) code -= bound; code = ffi.new("UInt32", code) end
local function GET_BIT2_CHECK(p, i, A0, A1)
	if IF_BIT_0_CHECK(p) then	if normalize_return_hack then return end
		UPDATE_0_CHECK()
		i = (i + i);
		if A0 then A0() end
	else
		UPDATE_1_CHECK()
		i = (i + i) + 1;
		if A1 then A1() end
	end
	
	return i
end
local function GET_BIT_CHECK(p, i) return GET_BIT2_CHECK(p, i, nil, nil) end
local function TREE_DECODE_CHECK(probs, limit, i)
	i = 1;
	repeat i = GET_BIT_CHECK(probs + i, i) if normalize_return_hack then return i end until not (i < limit)
	i -= limit;
	return i
end

local function GET_PROBS()
	return p.probs
end

local function CALC_POS_STATE(processedPos, pbMask)
	return (((processedPos) & (pbMask)) << 4)
end

local function COMBINED_PS_STATE()
	return (posState + state)
end
local function GET_LEN_STATE()
	return (posState) --,
end

local function REV_BIT_CHECK(p, i, m)
	if IF_BIT_0_CHECK(p + i) then	if normalize_return_hack then return end
		UPDATE_0_CHECK()
		i += m;
		m += m;
	else
		UPDATE_1_CHECK()
		m += m;
		i += m;
	end
	
	return i, m
end

--rest of constants

kStartOffset = 0

kNumPosBitsMax = 4
kNumPosStatesMax = (1 << kNumPosBitsMax)

kLenNumLowBits = 3
kLenNumLowSymbols = (1 << kLenNumLowBits)
kLenNumHighBits = 8
kLenNumHighSymbols = (1 << kLenNumHighBits)

LenLow = 0
LenHigh = (LenLow + 2 * (kNumPosStatesMax << kLenNumLowBits))
kNumLenProbs = (LenHigh + kLenNumHighSymbols)

LenChoice = LenLow
LenChoice2 = (LenLow + (1 << kLenNumLowBits))

kNumStates = 12
kNumStates2 = 16
kNumLitStates = 7

kStartPosModelIndex = 4
kEndPosModelIndex = 14
kNumFullDistances = (1 << (kEndPosModelIndex >> 1))

kNumPosSlotBits = 6
kNumLenToPosStates = 4

kNumAlignBits = 4
kAlignTableSize = (1 << kNumAlignBits)

kMatchMinLen = 2
kMatchSpecLenStart = (kMatchMinLen + kLenNumLowSymbols * 2 + kLenNumHighSymbols)

kMatchSpecLen_Error_Data = (1 << 9)
kMatchSpecLen_Error_Fail = (kMatchSpecLen_Error_Data - 1)

SpecPos = (-kStartOffset)
IsRep0Long = (SpecPos + kNumFullDistances)
RepLenCoder = (IsRep0Long + (kNumStates2 << kNumPosBitsMax))
LenCoder = (RepLenCoder + kNumLenProbs)
IsMatch = (LenCoder + kNumLenProbs)
Align = (IsMatch + (kNumStates2 << kNumPosBitsMax))
IsRep = (Align + kAlignTableSize)
IsRepG0 = (IsRep + kNumStates)
IsRepG1 = (IsRepG0 + kNumStates)
IsRepG2 = (IsRepG1 + kNumStates)
PosSlot = (IsRepG2 + kNumStates)
Literal = (PosSlot + (kNumLenToPosStates << kNumPosSlotBits))
NUM_BASE_PROBS = (Literal + kStartOffset)

LZMA_LIT_SIZE = 0x300

local function LzmaProps_GetNumProbs(p)
	return (NUM_BASE_PROBS + (LZMA_LIT_SIZE << ((p).lc + (p).lp)))
end

LZMA_DIC_MIN = (1 << 12)

--I am Proto!
--local LzmaDec_InitDicAndState

--#ifdef Z7_LZMA_DEC_OPT

--#else

--static
--int Z7_FASTCALL LZMA_DECODE_REAL(CLzmaDec *p, SizeT limit, const Byte *bufLimit)
local function LZMA_DECODE_REAL(_p, limit, _bufLimit)
  --CLzmaProb *probs = GET_PROBS;
  p = _p --make parameter global
  bufLimit = _bufLimit --make parameter global
  local probs = GET_PROBS();
  --unsigned state = (unsigned)p->state;
  state = p.state;
  --UInt32 rep0 = p->reps[0], rep1 = p->reps[1], rep2 = p->reps[2], rep3 = p->reps[3];
  local rep0, rep1, rep2, rep3 = p.reps[0], p.reps[1], p.reps[2], p.reps[3]
  --unsigned pbMask = ((unsigned)1 << (p->prop.pb)) - 1;
  local pbMask = (1 << (p.prop.pb)) - 1;
  --unsigned lc = p->prop.lc;
  local lc = p.prop.lc;
  --unsigned lpMask = ((unsigned)0x100 << p->prop.lp) - ((unsigned)0x100 >> lc);
  local lpMask = (0x100 << p.prop.lp) - (0x100 >> lc);

  --Byte *dic = p->dic;
  --SizeT dicBufSize = p->dicBufSize;
  --SizeT dicPos = p->dicPos;
  local dic = p.dic;
  local dicBufSize = p.dicBufSize;
  local dicPos = p.dicPos;
  
  --UInt32 processedPos = p->processedPos;
  --UInt32 checkDicSize = p->checkDicSize;
  local processedPos = p.processedPos;
  local checkDicSize = p.checkDicSize;
  --unsigned len = 0;
  local len = 0

  --const Byte *buf = p->buf;
  --UInt32 range = p->range;
  --UInt32 code = p->code;
  buf = p.buf;
  range = p.range;
  code = p.code;
  
  repeat
    --[[CLzmaProb *prob;
    UInt32 bound;
    unsigned ttt;
    unsigned posState = CALC_POS_STATE(processedPos, pbMask);]]
    prob = nil;
    bound = nil;
    ttt = nil;
    posState = CALC_POS_STATE(processedPos, pbMask);

    prob = probs + IsMatch + COMBINED_PS_STATE();
    if IF_BIT_0(prob) then
      --unsigned symbol;
      symbol = nil;
      UPDATE_0(prob)
      prob = probs + Literal;
      if (processedPos != 0 || checkDicSize != 0) then
        prob += 3 * ((((processedPos << 8) + dic[(dicPos == 0 ? dicBufSize : dicPos) - 1]) & lpMask) << lc);
		end
      processedPos += 1;

      if (state < kNumLitStates) then
        state -= (state < 4) ? state : 3;
        symbol = 1;
        --[[#ifdef Z7_LZMA_SIZE_OPT
        while (symbol < 0x100) do
			NORMAL_LITER_DEC()
		end
        #else]]
        NORMAL_LITER_DEC()
        NORMAL_LITER_DEC()
        NORMAL_LITER_DEC()
        NORMAL_LITER_DEC()
        NORMAL_LITER_DEC()
        NORMAL_LITER_DEC()
        NORMAL_LITER_DEC()
        NORMAL_LITER_DEC()
        --#endif
      else
        --[[unsigned matchByte = dic[dicPos - rep0 + (dicPos < rep0 ? dicBufSize : 0)];
        unsigned offs = 0x100;
        state -= (state < 10) ? 3 : 6;
        symbol = 1;]]
        matchByte = dic[dicPos - rep0 + (dicPos < rep0 ? dicBufSize : 0)];
        offs = 0x100;
        state -= (state < 10) ? 3 : 6;
        symbol = 1;
        --[[#ifdef Z7_LZMA_SIZE_OPT
        while (symbol < 0x100) do
          --unsigned bit;
          --CLzmaProb *probLit;
          bit = nil;
          probLit = nil;
          MATCHED_LITER_DEC()
        end
        #else]]
		do
          --unsigned bit;
          --CLzmaProb *probLit;
          bit = nil;
          probLit = nil;
          MATCHED_LITER_DEC()
          MATCHED_LITER_DEC()
          MATCHED_LITER_DEC()
          MATCHED_LITER_DEC()
          MATCHED_LITER_DEC()
          MATCHED_LITER_DEC()
          MATCHED_LITER_DEC()
          MATCHED_LITER_DEC()
        end
        --#endif
      end

      --dic[dicPos++] = (Byte)symbol;
      dic[dicPos] = symbol--tonumber(ffi.cast("Byte", symbol));
	  dicPos += 1
      continue
    end
    
    do
      UPDATE_1(prob)
      prob = probs + IsRep + state;
      if IF_BIT_0(prob) then
        UPDATE_0(prob)
        state += kNumStates;
        prob = probs + LenCoder;
      else
        UPDATE_1(prob)
        prob = probs + IsRepG0 + state;
        if IF_BIT_0(prob) then
          UPDATE_0(prob)
          prob = probs + IsRep0Long + COMBINED_PS_STATE();
          if IF_BIT_0(prob) then
            UPDATE_0(prob)
  
            --[[// that case was checked before with kBadRepCode
            // if (checkDicSize == 0 && processedPos == 0) { len = kMatchSpecLen_Error_Data + 1; break; }
            // The caller doesn't allow (dicPos == limit) case here
            // so we don't need the following check:
            // if (dicPos == limit) { state = state < kNumLitStates ? 9 : 11; len = 1; break; }]]
            
            dic[dicPos] = dic[dicPos - rep0 + (dicPos < rep0 ? dicBufSize : 0)];
            dicPos += 1;
            processedPos += 1;
            state = state < kNumLitStates ? 9 : 11;
            continue
          end
          UPDATE_1(prob)
        else
          --UInt32 distance;
          local distance;
          UPDATE_1(prob)
          prob = probs + IsRepG1 + state;
          if IF_BIT_0(prob) then
            UPDATE_0(prob)
            distance = rep1;
          else
            UPDATE_1(prob)
            prob = probs + IsRepG2 + state;
            if IF_BIT_0(prob) then
              UPDATE_0(prob)
              distance = rep2;
            else
              UPDATE_1(prob)
              distance = rep3;
              rep3 = rep2;
            end
            rep2 = rep1;
          end
          rep1 = rep0;
          rep0 = distance;
        end
        state = state < kNumLitStates ? 8 : 11;
        prob = probs + RepLenCoder;
      end
      
      --[[#ifdef Z7_LZMA_SIZE_OPT
      do
        --unsigned lim, offset;
        --CLzmaProb *probLen = prob + LenChoice;
        local lim, offset;
        local probLen = prob + LenChoice;
        if IF_BIT_0(probLen) then
          UPDATE_0(probLen)
          probLen = prob + LenLow + GET_LEN_STATE;
          offset = 0;
          lim = (1 << kLenNumLowBits);
        else
          UPDATE_1(probLen)
          probLen = prob + LenChoice2;
          if IF_BIT_0(probLen) then
            UPDATE_0(probLen)
            probLen = prob + LenLow + GET_LEN_STATE + (1 << kLenNumLowBits);
            offset = kLenNumLowSymbols;
            lim = (1 << kLenNumLowBits);
          else
            UPDATE_1(probLen)
            probLen = prob + LenHigh;
            offset = kLenNumLowSymbols * 2;
            lim = (1 << kLenNumHighBits);
          end
        end
        len = TREE_DECODE(probLen, lim, len)
        len += offset;
      end
      #else]]
      do
        --CLzmaProb *probLen = prob + LenChoice;
        local probLen = prob + LenChoice;
        if IF_BIT_0(probLen) then
          UPDATE_0(probLen)
          probLen = prob + LenLow + GET_LEN_STATE();
          len = 1;
          len = TREE_GET_BIT(probLen, len)
          len = TREE_GET_BIT(probLen, len)
          len = TREE_GET_BIT(probLen, len)
          len -= 8;
        else
          UPDATE_1(probLen)
          probLen = prob + LenChoice2;
          if IF_BIT_0(probLen) then
            UPDATE_0(probLen)
            probLen = prob + LenLow + GET_LEN_STATE() + (1 << kLenNumLowBits);
            len = 1;
            len = TREE_GET_BIT(probLen, len)
            len = TREE_GET_BIT(probLen, len)
            len = TREE_GET_BIT(probLen, len)
          else
            UPDATE_1(probLen)
            probLen = prob + LenHigh;
            len = TREE_DECODE(probLen, (1 << kLenNumHighBits), len)
            len += kLenNumLowSymbols * 2;
          end
        end
      end
      --#endif

      if (state >= kNumStates) then
        --UInt32 distance;
        local distance;
        prob = probs + PosSlot +
            ((len < kNumLenToPosStates ? len : kNumLenToPosStates - 1) << kNumPosSlotBits);
        distance = TREE_6_DECODE(prob, distance)
        if (distance >= kStartPosModelIndex) then
          --unsigned posSlot = (unsigned)distance;
          --unsigned numDirectBits = (unsigned)(((distance >> 1) - 1));
          local posSlot = distance;
          local numDirectBits = (((distance >> 1) - 1));
          distance = (2 | (distance & 1));
          if (posSlot < kEndPosModelIndex) then
            distance <<= numDirectBits;
            prob = probs + SpecPos;
            do
              --UInt32 m = 1;
              local m = 1;
              distance += 1;
              repeat
                distance, m = REV_BIT_VAR(prob, distance, m)
				numDirectBits -= 1
		      until not (numDirectBits ~= 0)
              --while (--numDirectBits);
              distance -= m;
            end
          else
            numDirectBits -= kNumAlignBits;
            
            repeat
              NORMALIZE()
              range >>= 1;
              
              do
                --UInt32 t;
                local t;
                code = UInt32(code - range);
                t = UInt32(0 - (code >> 31)); --[[/* (UInt32)((Int32)code >> 31) */]]
                distance = (distance << 1) + UInt32(t + 1);
                code = UInt32(code + (range & t));
              end
              --[[
              distance <<= 1;
              if (code >= range)
              {
                code -= range;
                distance |= 1;
              }
              ]]
			  numDirectBits -= 1
		    until not (numDirectBits ~= 0)
            --while (--numDirectBits);
            prob = probs + Align;
            distance <<= kNumAlignBits;
            do
              --unsigned i = 1;
              local i = 1;
              i = REV_BIT_CONST(prob, i, 1)
              i = REV_BIT_CONST(prob, i, 2)
              i = REV_BIT_CONST(prob, i, 4)
              i = REV_BIT_LAST (prob, i, 8)
              distance |= i;
            end
            if (distance == 0xFFFFFFFF) then
              len = kMatchSpecLenStart;
              state -= kNumStates;
              break;
            end
          end
        end
        
        rep3 = rep2;
        rep2 = rep1;
        rep1 = rep0;
        rep0 = distance + 1;
        state = (state < kNumStates + kNumLitStates) ? kNumLitStates : kNumLitStates + 3;
        if (distance >= (checkDicSize == 0 ? processedPos: checkDicSize)) then
          len += kMatchSpecLen_Error_Data + kMatchMinLen;
          --// len = kMatchSpecLen_Error_Data;
          --// len += kMatchMinLen;
          break;
        end
      end

      len += kMatchMinLen;

      do
        --SizeT rem;
        --unsigned curLen;
        --SizeT pos;
        local rem;
        local curLen;
        local pos;
        
		rem = limit - dicPos
        if (rem == 0) then
          --[[
          We stop decoding and return SZ_OK, and we can resume decoding later.
          Any error conditions can be tested later in caller code.
          For more strict mode we can stop decoding with error
          // len += kMatchSpecLen_Error_Data;
          ]]
          break;
        end
        
        curLen = ((rem < len) ? rem : len);
        pos = dicPos - rep0 + (dicPos < rep0 ? dicBufSize : 0);

        processedPos += curLen;

        len -= curLen;
        if (curLen <= dicBufSize - pos) then
          --Byte *dest = dic + dicPos;
          --ptrdiff_t src = (ptrdiff_t)pos - (ptrdiff_t)dicPos;
          --const Byte *lim = dest + curLen;
          local dest = dic + dicPos;
          local src = pos - dicPos;
          local lim = dest + curLen;
          dicPos += curLen;
          --do
            --*(dest) = (Byte)*(dest + src);
          --while (++dest != lim);
          repeat
            dest[0] = (dest + src)[0]--tonumber(ffi.cast("Byte", (dest + src)[0]));
			dest += 1
          until not (dest != lim);
        else
          --[[do
          {
            dic[dicPos++] = dic[pos];
            if (++pos == dicBufSize)
              pos = 0;
          }
          while (--curLen != 0);]]
          repeat
            dic[dicPos] = dic[pos];
			dicPos += 1
			pos += 1
            if (pos == dicBufSize) then
              --pos = 0; --this breaks
			end
			curLen -= 1
          until not (curLen != 0);
        end
      end
    end
  until not (dicPos < limit && buf < bufLimit)

  NORMALIZE()
  
  p.buf = buf;
  p.range = range;
  p.code = code;
  p.remainLen = len; --// & (kMatchSpecLen_Error_Data - 1); // we can write real length for error matches too.
  p.dicPos = dicPos;
  p.processedPos = processedPos;
  p.reps[0] = rep0;
  p.reps[1] = rep1;
  p.reps[2] = rep2;
  p.reps[3] = rep3;
  p.state = state;
  if (len >= kMatchSpecLen_Error_Data) then
	error("SZ_ERROR_DATA")
    return SZ_ERROR_DATA;
	end
  return SZ_OK;
end
--#endif



--static void Z7_FASTCALL LzmaDec_WriteRem(CLzmaDec *p, SizeT limit)
local function LzmaDec_WriteRem(p, limit)
  --unsigned len = (unsigned)p->remainLen;
  local len = p.remainLen;
  if (len == 0 --[[ || len >= kMatchSpecLenStart ]]) then
    return;
	end
  do
    --[[SizeT dicPos = p->dicPos;
    Byte *dic;
    SizeT dicBufSize;
    SizeT rep0;   /* we use SizeT to avoid the BUG of VC14 for AMD64 */]]
    local dicPos = p.dicPos;
    local dic;
    local dicBufSize;
    local rep0;   --[[ we use SizeT to avoid the BUG of VC14 for AMD64 ]]
    do
      --SizeT rem = limit - dicPos;
      local rem = limit - dicPos;
      if (rem < len) then
        len = rem;
        if (len == 0) then
          return;
		end
      end
    end

    if (p.checkDicSize == 0 && p.prop.dicSize - p.processedPos <= len) then
      p.checkDicSize = p.prop.dicSize;
	end

    p.processedPos += len;
    p.remainLen -= len;
    dic = p.dic;
    rep0 = p.reps[0];
    dicBufSize = p.dicBufSize;
    --[[do
    {
      dic[dicPos] = dic[dicPos - rep0 + (dicPos < rep0 ? dicBufSize : 0)];
      dicPos++;
    }
    while (--len);]]
    repeat
      dic[dicPos] = dic[dicPos - rep0 + (dicPos < rep0 ? dicBufSize : 0)];
      dicPos += 1;
	  len -= 1
    until not (len ~= 0)
    p.dicPos = dicPos;
  end
end


--[[
At staring of new stream we have one of the following symbols:
  - Literal        - is allowed
  - Non-Rep-Match  - is allowed only if it's end marker symbol
  - Rep-Match      - is not allowed
We use early check of (RangeCoder:Code) over kBadRepCode to simplify main decoding code
]]

local kRange0 = 0xFFFFFFFF
local kBound0 = ((kRange0 >> kNumBitModelTotalBits) << (kNumBitModelTotalBits - 1))
local kBadRepCode = (kBound0 + (((kRange0 - kBound0) >> kNumBitModelTotalBits) << (kNumBitModelTotalBits - 1)))
if kBadRepCode != (0xC0000000 - 0x400) then
  error("Stop_Compiling_Bad_LZMA_Check")
end


--[[
LzmaDec_DecodeReal2():
  It calls LZMA_DECODE_REAL() and it adjusts limit according (p->checkDicSize).

We correct (p->checkDicSize) after LZMA_DECODE_REAL() and in LzmaDec_WriteRem(),
and we support the following state of (p->checkDicSize):
  if (total_processed < p->prop.dicSize) then
  {
    (total_processed == p->processedPos)
    (p->checkDicSize == 0)
  }
  else
    (p->checkDicSize == p->prop.dicSize)
]]

--static int Z7_FASTCALL LzmaDec_DecodeReal2(CLzmaDec *p, SizeT limit, const Byte *bufLimit)
local function LzmaDec_DecodeReal2(p, limit, bufLimit)
  if (p.checkDicSize == 0) then
    --UInt32 rem = p->prop.dicSize - p->processedPos;
    local rem = p.prop.dicSize - p.processedPos;
    if (limit - p.dicPos > rem) then
      limit = p.dicPos + rem;
	end
  end
  do
    --int res = LZMA_DECODE_REAL(p, limit, bufLimit);
    local res = LZMA_DECODE_REAL(p, limit, bufLimit);
    if (p.checkDicSize == 0 && p.processedPos >= p.prop.dicSize) then
      p.checkDicSize = p.prop.dicSize;
	end
    return res;
  end
end



ffi.cdef[[
typedef enum
{
  DUMMY_INPUT_EOF, /* need more input data */
  DUMMY_LIT,
  DUMMY_MATCH,
  DUMMY_REP
} ELzmaDummy;
]]

assert(ffi.C.DUMMY_MATCH ~= nil, "no DUMMY_MATCH")
local function IS_DUMMY_END_MARKER_POSSIBLE(dummyRes) return ((dummyRes) == ffi.C.DUMMY_MATCH) end

--static ELzmaDummy LzmaDec_TryDummy(const CLzmaDec *p, const Byte *buf, const Byte **bufOut)
local function LzmaDec_TryDummy(_p, _buf, bufOut)
	p = _p
	buf = _buf
  --UInt32 range = p->range;
  --UInt32 code = p->code;
  --const Byte *bufLimit = *bufOut;
  range = p.range;
  code = p.code;
  bufLimit = bufOut--[[[0] ]];
  --const CLzmaProb *probs = GET_PROBS;
  local probs = GET_PROBS();
  --unsigned state = (unsigned)p->state;
  state = p.state;
  --ELzmaDummy res;
  local res;

  while true do
    --[[const CLzmaProb *prob;
    UInt32 bound;
    unsigned ttt;
    unsigned posState = CALC_POS_STATE(p->processedPos, ((unsigned)1 << p->prop.pb) - 1);]]
    prob = nil;
    bound = nil;
    ttt = nil;
    posState = CALC_POS_STATE(p.processedPos, (1 << p.prop.pb) - 1);

    prob = probs + IsMatch + COMBINED_PS_STATE();
    if IF_BIT_0_CHECK(prob) then	if normalize_return_hack then return clear_nrh() end
      UPDATE_0_CHECK()

      prob = probs + Literal;
      if (p.checkDicSize != 0 || p.processedPos != 0) then
        prob += (LZMA_LIT_SIZE *
            ((((p.processedPos) & ((1 << (p.prop.lp)) - 1)) << p.prop.lc) +
            (p.dic[(p.dicPos == 0 ? p.dicBufSize : p.dicPos) - 1] >> (8 - p.prop.lc))));
	  end

      if (state < kNumLitStates) then
        --unsigned symbol = 1;
        local symbol = 1;
        --do { GET_BIT_CHECK(prob + symbol, symbol) } while (symbol < 0x100);
        repeat symbol = GET_BIT_CHECK(prob + symbol, symbol)
			if normalize_return_hack then return clear_nrh() end until not (symbol < 0x100)
      else
        --[[unsigned matchByte = p->dic[p->dicPos - p->reps[0] +
            (p->dicPos < p->reps[0] ? p->dicBufSize : 0)];
        unsigned offs = 0x100;
        unsigned symbol = 1;]]
        matchByte = p.dic[p.dicPos - p.reps[0] +
            (p.dicPos < p.reps[0] ? p.dicBufSize : 0)];
        offs = 0x100;
        symbol = 1;
        --[[do
        {
          unsigned bit;
          const CLzmaProb *probLit;
          matchByte += matchByte;
          bit = offs;
          offs &= matchByte;
          probLit = prob + (offs + bit + symbol);
          GET_BIT2_CHECK(probLit, symbol, offs ^= bit; , ; )
        }
        while (symbol < 0x100);]]
        repeat
          bit = nil;
          probLit = nil;
          matchByte += matchByte;
          bit = offs;
          offs &= matchByte;
          probLit = prob + (offs + bit + symbol);
          symbol = GET_BIT2_CHECK(probLit, symbol, function() offs ~= bit; end, nil)
		  if normalize_return_hack then return clear_nrh() end
        until not (symbol < 0x100);
      end
      res = ffi.C.DUMMY_LIT;
    else
      --unsigned len;
      local len;
      UPDATE_1_CHECK()

      prob = probs + IsRep + state;
      if IF_BIT_0_CHECK(prob) then	if normalize_return_hack then return clear_nrh() end
        UPDATE_0_CHECK()
        state = 0;
        prob = probs + LenCoder;
        res = ffi.C.DUMMY_MATCH;
      else
        UPDATE_1_CHECK()
        res = ffi.C.DUMMY_REP;
        prob = probs + IsRepG0 + state;
        if IF_BIT_0_CHECK(prob) then	if normalize_return_hack then return clear_nrh() end
          UPDATE_0_CHECK()
          prob = probs + IsRep0Long + COMBINED_PS_STATE();
          if IF_BIT_0_CHECK(prob) then	if normalize_return_hack then return clear_nrh() end
            UPDATE_0_CHECK()
            break;
          else
            UPDATE_1_CHECK()
          end
        else
          UPDATE_1_CHECK()
          prob = probs + IsRepG1 + state;
          if IF_BIT_0_CHECK(prob) then	if normalize_return_hack then return clear_nrh() end
            UPDATE_0_CHECK()
          else
            UPDATE_1_CHECK()
            prob = probs + IsRepG2 + state;
            if IF_BIT_0_CHECK(prob) then	if normalize_return_hack then return clear_nrh() end
              UPDATE_0_CHECK()
            else
              UPDATE_1_CHECK()
            end
          end
        end
        state = kNumStates;
        prob = probs + RepLenCoder;
      end
      do
        --unsigned limit, offset;
        local limit, offset;
        --const CLzmaProb *probLen = prob + LenChoice;
        local probLen = prob + LenChoice;
        if IF_BIT_0_CHECK(probLen) then	if normalize_return_hack then return clear_nrh() end
          UPDATE_0_CHECK()
          probLen = prob + LenLow + GET_LEN_STATE();
          offset = 0;
          limit = 1 << kLenNumLowBits;
        else
          UPDATE_1_CHECK()
          probLen = prob + LenChoice2;
          if IF_BIT_0_CHECK(probLen) then	if normalize_return_hack then return clear_nrh() end
            UPDATE_0_CHECK()
            probLen = prob + LenLow + GET_LEN_STATE() + (1 << kLenNumLowBits);
            offset = kLenNumLowSymbols;
            limit = 1 << kLenNumLowBits;
          else
            UPDATE_1_CHECK()
            probLen = prob + LenHigh;
            offset = kLenNumLowSymbols * 2;
            limit = 1 << kLenNumHighBits;
          end
        end
        len = TREE_DECODE_CHECK(probLen, limit, len)
		if normalize_return_hack then return clear_nrh() end
		
        len += offset;
      end

      if (state < 4) then
        --unsigned posSlot;
        local posSlot;
        prob = probs + PosSlot +
            ((len < kNumLenToPosStates - 1 ? len : kNumLenToPosStates - 1) <<
            kNumPosSlotBits);
        posSlot = TREE_DECODE_CHECK(prob, 1 << kNumPosSlotBits, posSlot)
		if normalize_return_hack then return clear_nrh() end
		
        if (posSlot >= kStartPosModelIndex) then
          --unsigned numDirectBits = ((posSlot >> 1) - 1);
          local numDirectBits = ((posSlot >> 1) - 1);

          if (posSlot < kEndPosModelIndex) then
            prob = probs + SpecPos + ((2 | (posSlot & 1)) << numDirectBits);
          else
            numDirectBits -= kNumAlignBits;
            --[[do
            {
              NORMALIZE_CHECK()
              range >>= 1;
              code -= range & (((code - range) >> 31) - 1);
              /* if (code >= range) code -= range; */
            }
            while (--numDirectBits);]]
            repeat
              local result = NORMALIZE_CHECK()
			  if result then return result end
              range >>= 1;
              code -= range & ((UInt32(code - range) >> 31) - 1); --this should be uint32
              --[[ if (code >= range) code -= range; ]]
			  numDirectBits -= 1
            until not (numDirectBits ~= 0)
            prob = probs + Align;
            numDirectBits = kNumAlignBits;
          end
          do
            --unsigned i = 1;
            --unsigned m = 1;
            local i = 1;
            local m = 1;
            --[[do
            {
              REV_BIT_CHECK(prob, i, m)
            }
            while (--numDirectBits);]]
            repeat
             i, m = REV_BIT_CHECK(prob, i, m)
			
			 if normalize_return_hack then return clear_nrh() end
			 numDirectBits -= 1
            until not (numDirectBits ~= 0)
          end
        end
      end
    end
    break;
  end
  local result = NORMALIZE_CHECK()
  if result then return result end
  local newbuf = buf
  buf = _buf

  --bufOut[0] = buf;
  return res, newbuf;
end

--void LzmaDec_InitDicAndState(CLzmaDec *p, BoolInt initDic, BoolInt initState);
local function LzmaDec_InitDicAndState(p, initDic, initState)
  p.remainLen = kMatchSpecLenStart + 1;
  p.tempBufSize = 0;

  if (initDic) then
    p.processedPos = 0;
    p.checkDicSize = 0;
    p.remainLen = kMatchSpecLenStart + 2;
  end
  if (initState) then
    p.remainLen = kMatchSpecLenStart + 2;
  end
end

--void LzmaDec_Init(CLzmaDec *p)
local function LzmaDec_Init(p)
  p.dicPos = 0;
  LzmaDec_InitDicAndState(p, true, true);
end --vs woody


--[[
LZMA supports optional end_marker.
So the decoder can lookahead for one additional LZMA-Symbol to check end_marker.
That additional LZMA-Symbol can require up to LZMA_REQUIRED_INPUT_MAX bytes in input stream.
When the decoder reaches dicLimit, it looks (finishMode) parameter:
  if (finishMode == LZMA_FINISH_ANY), the decoder doesn't lookahead
  if (finishMode != LZMA_FINISH_ANY), the decoder lookahead, if end_marker is possible for current position

When the decoder lookahead, and the lookahead symbol is not end_marker, we have two ways:
  1) Strict mode (default) : the decoder returns SZ_ERROR_DATA.
  2) The relaxed mode (alternative mode) : we could return SZ_OK, and the caller
     must check (status) value. The caller can show the error,
     if the end of stream is expected, and the (status) is noit
     LZMA_STATUS_FINISHED_WITH_MARK or LZMA_STATUS_MAYBE_FINISHED_WITHOUT_MARK.
]]


--[[#define RETURN_NOT_FINISHED_FOR_FINISH \
  *status = LZMA_STATUS_NOT_FINISHED; \
  return SZ_ERROR_DATA; // for strict mode
  // return SZ_OK; // for relaxed mode]]

local function RETURN_NOT_FINISHED_FOR_FINISH(status)
  status[0] = ffi.C.LZMA_STATUS_NOT_FINISHED;
	error("SZ_ERROR_DATA")
  return SZ_ERROR_DATA; -- for strict mode
  -- return SZ_OK; // for relaxed mode
end


--SRes LzmaDec_DecodeToDic(CLzmaDec *p, SizeT dicLimit, const Byte *src, SizeT *srcLen,
--    ELzmaFinishMode finishMode, ELzmaStatus *status)
local function LzmaDec_DecodeToDic(p, dicLimit, src, srcLen,
    finishMode, status)
  --SizeT inSize = *srcLen;
  local inSize = srcLen[0];
  --(*srcLen) = 0;
  srcLen[0] = 0;
  --*status = ffi.C.LZMA_STATUS_NOT_SPECIFIED;
  status[0] = ffi.C.LZMA_STATUS_NOT_SPECIFIED;

  if (p.remainLen > kMatchSpecLenStart) then
    if (p.remainLen > kMatchSpecLenStart + 2) then
	error(p.remainLen == kMatchSpecLen_Error_Fail ? "SZ_ERROR_FAIL" : "SZ_ERROR_DATA")
      return p.remainLen == kMatchSpecLen_Error_Fail ? SZ_ERROR_FAIL : SZ_ERROR_DATA;
	end

    --for (; inSize > 0 && p->tempBufSize < RC_INIT_SIZE; (*srcLen)++, inSize--)
    --  p->tempBuf[p->tempBufSize++] = *src++;
    while (inSize > 0 && p.tempBufSize < RC_INIT_SIZE) do
		p.tempBuf[p.tempBufSize] = src[0];
		src += 1
		p.tempBufSize += 1
		srcLen[0] += 1
		inSize -= 1
	end
    if (p.tempBufSize != 0 && p.tempBuf[0] != 0) then
	error("SZ_ERROR_DATA")
      return SZ_ERROR_DATA;
	end
    if (p.tempBufSize < RC_INIT_SIZE) then
      status[0] = ffi.C.LZMA_STATUS_NEEDS_MORE_INPUT;
      return SZ_OK;
    end
    p.code =
        (p.tempBuf[1] << 24)
      | (p.tempBuf[2] << 16)
      | (p.tempBuf[3] << 8)
      | (p.tempBuf[4]);

    if (p.checkDicSize == 0
        && p.processedPos == 0
        && p.code >= kBadRepCode) then
	error("SZ_ERROR_DATA")
      return SZ_ERROR_DATA;
	end

    p.range = 0xFFFFFFFF;
    p.tempBufSize = 0;

    if (p.remainLen > kMatchSpecLenStart + 1) then
      --SizeT numProbs = LzmaProps_GetNumProbs(&p->prop);
      --SizeT i;
      --CLzmaProb *probs = p->probs;
      local numProbs = LzmaProps_GetNumProbs(p.prop);
      local probs = p.probs;
      --for (i = 0; i < numProbs; i++)
        --probs[i] = kBitModelTotal >> 1;
      for i = 0, numProbs - 1 do
        probs[i] = kBitModelTotal >> 1;
      end
      --p->reps[0] = p->reps[1] = p->reps[2] = p->reps[3] = 1;
      p.reps[0], p.reps[1], p.reps[2], p.reps[3] = 1, 1, 1, 1;
      p.state = 0;
    end

    p.remainLen = 0;
  end

  while true do
    if (p.remainLen == kMatchSpecLenStart) then
      if (p.code != 0) then
        return SZ_ERROR_DATA;
      end
      status[0] = ffi.C.LZMA_STATUS_FINISHED_WITH_MARK;
      return SZ_OK;
    end

    LzmaDec_WriteRem(p, dicLimit);

    do
      -- (p.remainLen == 0 || p.dicPos == dicLimit)

      --int checkEndMarkNow = 0;
      local checkEndMarkNow = 0;

      if (p.dicPos >= dicLimit) then
        if (p.remainLen == 0 && p.code == 0) then
          status[0] = ffi.C.LZMA_STATUS_MAYBE_FINISHED_WITHOUT_MARK;
          return SZ_OK;
        end
        if (finishMode == ffi.C.LZMA_FINISH_ANY) then
          status[0] = ffi.C.LZMA_STATUS_NOT_FINISHED;
          return SZ_OK;
        end
        if (p.remainLen != 0) then
          return RETURN_NOT_FINISHED_FOR_FINISH(status) and true
        end
        checkEndMarkNow = 1;
      end

      -- (p.remainLen == 0)

      if (p.tempBufSize == 0) then
        --const Byte *bufLimit;
        --int dummyProcessed = -1;
        local bufLimit;
        local dummyProcessed = -1;
        
        if (inSize < LZMA_REQUIRED_INPUT_MAX || checkEndMarkNow ~= 0) then
          --const Byte *bufOut = src + inSize;
          local bufOut = src + inSize;
          
          --ELzmaDummy dummyRes = LzmaDec_TryDummy(p, src, &bufOut);
		  local dummyRes
          dummyRes, bufOut = LzmaDec_TryDummy(p, src, bufOut);
          
          if (dummyRes == ffi.C.DUMMY_INPUT_EOF) then
            --size_t i;
            if (inSize >= LZMA_REQUIRED_INPUT_MAX) then
		  error()
              break;
			end
            (srcLen)[0] += inSize;
            p.tempBufSize = inSize;
            for i = 0, inSize - 1 do
              p.tempBuf[i] = src[i];
			end
            status[0] = ffi.C.LZMA_STATUS_NEEDS_MORE_INPUT;
            return SZ_OK;
          end
 
          dummyProcessed = (bufOut - src);
          if (dummyProcessed > LZMA_REQUIRED_INPUT_MAX) then
		  error()
            break;
          end
          
          if (checkEndMarkNow ~= 0 && !IS_DUMMY_END_MARKER_POSSIBLE(dummyRes)) then
            --unsigned i;
            (srcLen)[0] += dummyProcessed;
            p.tempBufSize = dummyProcessed;
            for i = 0, dummyProcessed - 1 do
              p.tempBuf[i] = src[i];
			end
            -- p.remainLen = kMatchSpecLen_Error_Data;
            return RETURN_NOT_FINISHED_FOR_FINISH(status) and true --prevent tail calls for now
          end
          
          bufLimit = src;
          -- we will decode only one iteration
        else
          bufLimit = src + inSize - LZMA_REQUIRED_INPUT_MAX;
		end
        p.buf = src;
        
        do
          --int res = LzmaDec_DecodeReal2(p, dicLimit, bufLimit);
          local res = LzmaDec_DecodeReal2(p, dicLimit, bufLimit);
          
          --SizeT processed = (SizeT)(p->buf - src);
          local processed = (p.buf - src);

          if (dummyProcessed < 0) then
            if (processed > inSize) then
		  error()
              break;
			end
          elseif (dummyProcessed != processed) then
		  error()
            break;
          end

          src += processed;
          inSize -= processed;
          (srcLen)[0] += processed;

          if (res != SZ_OK) then
            p.remainLen = kMatchSpecLen_Error_Data;
            return SZ_ERROR_DATA;
          end
        end
        continue
      end

      do
        -- we have some data in (p->tempBuf)
        -- in strict mode: tempBufSize is not enough for one Symbol decoding.
        -- in relaxed mode: tempBufSize not larger than required for one Symbol decoding.

        --unsigned rem = p->tempBufSize;
        --unsigned ahead = 0;
        --int dummyProcessed = -1;
        local rem = p.tempBufSize;
        local ahead = 0;
        local dummyProcessed = -1;
        
        while (rem < LZMA_REQUIRED_INPUT_MAX && ahead < inSize) do
          p.tempBuf[rem] = src[ahead];
		  rem += 1;
		  ahead += 1;
		end
        
        -- ahead - the size of new data copied from (src) to (p->tempBuf)
        -- rem   - the size of temp buffer including new data from (src)
        
        if (rem < LZMA_REQUIRED_INPUT_MAX || checkEndMarkNow ~= 0) then
          --const Byte *bufOut = p->tempBuf + rem;
          local bufOut = p.tempBuf + rem;
        
          --ELzmaDummy dummyRes = LzmaDec_TryDummy(p, p->tempBuf, &bufOut);
		  local dummyRes
          dummyRes, bufOut = LzmaDec_TryDummy(p, p.tempBuf, bufOut);
          
          if (dummyRes == ffi.C.DUMMY_INPUT_EOF) then
            if (rem >= LZMA_REQUIRED_INPUT_MAX) then
		  error()
              break;
			end
            p.tempBufSize = rem;
            (srcLen)[0] += ahead;
            status[0] = ffi.C.LZMA_STATUS_NEEDS_MORE_INPUT;
            return SZ_OK;
          end
          
          dummyProcessed = (bufOut - p.tempBuf);

          if (dummyProcessed < p.tempBufSize) then
		  error()
            break;
          end

          if (checkEndMarkNow ~= 0 && !IS_DUMMY_END_MARKER_POSSIBLE(dummyRes)) then
            (srcLen)[0] += dummyProcessed - p.tempBufSize;
            p.tempBufSize = dummyProcessed;
            -- p.remainLen = kMatchSpecLen_Error_Data;
            return RETURN_NOT_FINISHED_FOR_FINISH(status) and true
          end
        end

        p.buf = p.tempBuf;
        
        do
          -- we decode one symbol from (p->tempBuf) here, so the (bufLimit) is equal to (p->buf)
          --int res = LzmaDec_DecodeReal2(p, dicLimit, p->buf);
          local res = LzmaDec_DecodeReal2(p, dicLimit, p.buf);

          --SizeT processed = (SizeT)(p->buf - p->tempBuf);
          local processed = (p.buf - p.tempBuf);
          rem = p.tempBufSize;
          
          if (dummyProcessed < 0) then
            if (processed > LZMA_REQUIRED_INPUT_MAX) then
		  error()
              break;
			end
            if (processed < rem) then
		  error()
              break;
			end
          elseif (dummyProcessed != processed) then
		  error()
            break;
          end
          
          processed -= rem;

          src += processed;
          inSize -= processed;
          (srcLen)[0] += processed;
          p.tempBufSize = 0;
          
          if (res != SZ_OK) then
            p.remainLen = kMatchSpecLen_Error_Data;
            return SZ_ERROR_DATA;
          end
        end
      end
    end
  end

  --[[  Some unexpected error: internal error of code, memory corruption or hardware failure ]]
  p.remainLen = kMatchSpecLen_Error_Fail;
  error("SZ_ERROR_FAIL")
  return SZ_ERROR_FAIL;
end



--void LzmaDec_FreeProbs(CLzmaDec *p, ISzAllocPtr alloc)
local function LzmaDec_FreeProbs(p, alloc)
  --ISzAlloc_Free(alloc, p.probs);
  p.probs = nil;
end

--static void LzmaDec_FreeDict(CLzmaDec *p, ISzAllocPtr alloc)
local function LzmaDec_FreeDict(p, alloc)
  --ISzAlloc_Free(alloc, p.dic);
  p.dic = nil;
end

--void LzmaDec_Free(CLzmaDec *p, ISzAllocPtr alloc)
local function LzmaDec_Free(p, alloc)
  LzmaDec_FreeProbs(p, alloc);
  LzmaDec_FreeDict(p, alloc);
end

--SRes LzmaProps_Decode(CLzmaProps *p, const Byte *data, unsigned size)
local function LzmaProps_Decode(p, data, size)
  --UInt32 dicSize;
  --Byte d;
  local dicSize;
  local d;
  
  if (size < LZMA_PROPS_SIZE) then
    return SZ_ERROR_UNSUPPORTED;
  else
    dicSize = data[1] | (data[2] << 8) | (data[3] << 16) | (data[4] << 24);
  end
 
  if (dicSize < LZMA_DIC_MIN) then
    dicSize = LZMA_DIC_MIN;
  end
  p.dicSize = dicSize;

  d = data[0];
  if (d >= (9 * 5 * 5)) then
    return SZ_ERROR_UNSUPPORTED;
  end

  p.lc = (d % 9);
  d /= 9;
  p.pb = (d / 5);
  p.lp = (d % 5);

  return SZ_OK;
end

--static SRes LzmaDec_AllocateProbs2(CLzmaDec *p, const CLzmaProps *propNew, ISzAllocPtr alloc)
local function LzmaDec_AllocateProbs2(p, propNew, alloc)
  --UInt32 numProbs = LzmaProps_GetNumProbs(propNew);
  local numProbs = LzmaProps_GetNumProbs(propNew);
  if (!p.probs || numProbs != p.numProbs) then
    LzmaDec_FreeProbs(p, alloc);
    p.probs = ffi.new("CLzmaProb[?]", numProbs) --ffi.cast("CLzmaProb *", ISzAlloc_Alloc(alloc, numProbs * ffi.sizeof("CLzmaProb")));
    if (!p.probs) then
      return SZ_ERROR_MEM; --luajit should handle this for us, but just in case
	end
    p.probs_1664 = p.probs + 1664;
    p.numProbs = numProbs;
  end
  return SZ_OK;
end

--SRes LzmaDec_AllocateProbs(CLzmaDec *p, const Byte *props, unsigned propsSize, ISzAllocPtr alloc)
local function LzmaDec_AllocateProbs(p, props, propsSize, alloc)
  --CLzmaProps propNew;
  local propNew = ffi.new("CLzmaProps");
  --RINOK(LzmaProps_Decode(&propNew, props, propsSize))
  --RINOK(LzmaDec_AllocateProbs2(p, &propNew, alloc))
  local result_1 = LzmaProps_Decode(propNew, props, propsSize)
  if result_1 ~= 0 then return result_1 end
  local result_2 = LzmaDec_AllocateProbs2(p, propNew, alloc)
  if result_2 ~= 0 then return result_2 end
  p.prop = propNew;
  return SZ_OK;
end

--SRes LzmaDecode(Byte *dest, SizeT *destLen, const Byte *src, SizeT *srcLen,
    --const Byte *propData, unsigned propSize, ELzmaFinishMode finishMode,
    --ELzmaStatus *status, ISzAllocPtr alloc)
--called by LzmaUncompress in LzmaLib.c,
local function LzmaDecode(dest, destLen, src, srcLen,
    propData, propSize, finishMode,
    status, alloc)
  --CLzmaDec p;
  --SRes res;
  --SizeT outSize = *destLen, inSize = *srcLen;
  local p = ffi.new("CLzmaDec");
  local res;
  local outSize, inSize = destLen[0], srcLen[0];
  destLen[0], srcLen[0] = 0, 0;
  status[0] = ffi.C.LZMA_STATUS_NOT_SPECIFIED;
  if (inSize < RC_INIT_SIZE) then
    return SZ_ERROR_INPUT_EOF;
  end
  LzmaDec_CONSTRUCT(p)
  --RINOK(LzmaDec_AllocateProbs(&p, propData, propSize, alloc))
  local result_1 = LzmaDec_AllocateProbs(p, propData, propSize, alloc)
  if result_1 ~= 0 then return result_1 end
  p.dic = dest;
  --p.dicBufSize = outSize;

  do
    --UInt32 dictSize = propNew.dicSize;
    --SizeT mask = ((UInt32)1 << 12) - 1;
    local dictSize = p.prop.dicSize;
    local mask = (1 << 12) - 1;
         if (dictSize >= (1 << 30)) then mask = (1 << 22) - 1;
    elseif (dictSize >= (1 << 22)) then mask = (1 << 20) - 1;
    end
    dicBufSize = (dictSize + mask) & ~mask;
    if (dicBufSize < dictSize) then
      dicBufSize = dictSize;
	end
  end
  p.dicBufSize = dicBufSize
  
  LzmaDec_Init(p);
  srcLen[0] = inSize;
  res = LzmaDec_DecodeToDic(p, outSize, src, srcLen, finishMode, status);
  destLen[0] = p.dicPos;
  if (res == SZ_OK && status[0] == ffi.C.LZMA_STATUS_NEEDS_MORE_INPUT) then
    res = SZ_ERROR_INPUT_EOF;
  end
  LzmaDec_FreeProbs(p, alloc);
  return res;
end

local LZMA86_SIZE_OFFSET = (1 + 5)
local LZMA86_HEADER_SIZE = (LZMA86_SIZE_OFFSET + 8)

function decode(input_data) --TODO: make a wrapper like this for pvr decoding
	local header_size = LZMA86_HEADER_SIZE - 1
	local input_buffer = ffi.cast("Byte *", ffi.new("const char *", input_data))
	local srcLen = ffi.new("SizeT[1]", input_data:len() - header_size)
	
	local output_length = love.data.unpack("<I8", input_data, 6)
	local destLen = ffi.new("SizeT[1]", output_length)
	local dest = ffi.new("Byte[?]", output_length)
	
	local status = ffi.new("ELzmaStatus[1]", 0)
	
	--disable gc for now to hide crashes from freed pointers and stuff
	--this has been in the works for multiple days i don't want to delay this any further
	collectgarbage("stop")
	
	local result = LzmaDecode(dest, destLen, input_buffer + header_size, srcLen,
		input_buffer, LZMA_PROPS_SIZE, ffi.C.LZMA_FINISH_ANY,
		status, alloc)
	
	collectgarbage("restart")
	
	local out = ffi.string(dest, output_length)
	
	return out
end

return lzma
