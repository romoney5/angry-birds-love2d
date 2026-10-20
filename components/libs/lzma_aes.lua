--aes, also reimplemented in luajit
--the implementation in lzma sdk happens to be the simplest one out there so..

--[[
/* Aes.c -- AES encryption / decryption
2024-03-01 : Igor Pavlov : Public domain */

#include "Precomp.h"

#include "CpuArch.h"
#include "Aes.h"

AES_CODE_FUNC g_AesCbc_Decode;
#ifndef Z7_SFX
AES_CODE_FUNC g_AesCbc_Encode;
AES_CODE_FUNC g_AesCtr_Code;
UInt32 g_Aes_SupportedFunctions_Flags;
#endif
]]

--Aes.h
local AES_BLOCK_SIZE = 16

--[[ UInt32 pointers must be 16-byte aligned ]]

--[[ 16-byte (4 * 32-bit words) blocks: 1 (IV) + 1 (keyMode) + 15 (AES-256 roundKeys) ]]
local AES_NUM_IVMRK_WORDS = ((1 + 1 + 15) * 4)

local function MY_ALIGN(a) --attribute
	return
end

MY_ALIGN(64)
--static UInt32 T[256 * 4];
local T = ffi.new("UInt32[1024]")
MY_ALIGN(64)
--[[static const Byte Sbox[256] = {]]
local Sbox = ffi.new("Byte[256]", {
  0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
  0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
  0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
  0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
  0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
  0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
  0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
  0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
  0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
  0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
  0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
  0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
  0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
  0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
  0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
  0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16})


MY_ALIGN(64)
--static UInt32 D[256 * 4];
local D = ffi.new("UInt32[1024]")
MY_ALIGN(64)
--static Byte InvS[256];
local InvS = ffi.new("Byte[256]")

local UInt32 = ffi.typeof("UInt32")

--#define xtime(x) ((((x) << 1) ^ (((x) & 0x80) != 0 ? 0x1B : 0)) & 0xFF)
local function xtime(x) return UInt32((((x) << 1) ~ (((x) & 0x80) != 0 ? 0x1B : 0)) & 0xFF) end

--#define Ui32(a0, a1, a2, a3) ((UInt32)(a0) | ((UInt32)(a1) << 8) | ((UInt32)(a2) << 16) | ((UInt32)(a3) << 24))
--optimizeable?
local function Ui32(a0, a1, a2, a3) return UInt32((a0) | ((a1) << 8) | ((a2) << 16) | ((a3) << 24)) end

--[[#define gb0(x) ( (x)          & 0xFF)
#define gb1(x) (((x) >> ( 8)) & 0xFF)
#define gb2(x) (((x) >> (16)) & 0xFF)
#define gb3(x) (((x) >> (24)))]]
local function gb0(x) return ( (x)          & 0xFF) end
local function gb1(x) return (((x) >> ( 8)) & 0xFF) end
local function gb2(x) return (((x) >> (16)) & 0xFF) end
local function gb3(x) return (((x) >> (24))) end
local gbs = {[0] = gb0, [1] = gb1, [2] = gb2, [3] = gb3}

--#define gb(n, x) gb ## n(x)
--## seems to be concat
local function gb(n, x) return gbs[n](x) end

--#define TT(x) (T + (x << 8))
--#define DD(x) (D + (x << 8))
local function TT(x) return (T + (x << 8)) end
local function DD(x) return (D + (x << 8)) end


local function GetUi32(p)
	--CpuArch.h
	return UInt32(ffi.cast("UInt32 *", ffi.cast("void *", p))[0])
end

local function SetUi32(p, v)
	ffi.cast("UInt32 *", ffi.cast("void *", p))[0] = v
end


--[[ Call AesGenTables one time before other AES functions ]]
--void AesGenTables(void)
local function AesGenTables()
  --unsigned i;
  --for (i = 0; i < 256; i++)
    --InvS[Sbox[i]] = (Byte)i;
  for i = 0, 256 - 1 do
    InvS[Sbox[i]] = i;
  end
  
  --for (i = 0; i < 256; i++)
  for i = 0, 256 - 1 do
    do
      local a1 = Sbox[i];
      local a2 = xtime(a1);
      local a3 = a2 ~ a1;
      TT(0)[i] = Ui32(a2, a1, a1, a3);
      TT(1)[i] = Ui32(a3, a2, a1, a1);
      TT(2)[i] = Ui32(a1, a3, a2, a1);
      TT(3)[i] = Ui32(a1, a1, a3, a2);
    end
    do
      local a1 = InvS[i];
      local a2 = xtime(a1);
      local a4 = xtime(a2);
      local a8 = xtime(a4);
      local a9 = a8 ~ a1;
      local aB = a8 ~ a2 ~ a1;
      local aD = a8 ~ a4 ~ a1;
      local aE = a8 ~ a4 ~ a2;
      DD(0)[i] = Ui32(aE, a9, aD, aB);
      DD(1)[i] = Ui32(aB, aE, a9, aD);
      DD(2)[i] = Ui32(aD, aB, aE, a9);
      DD(3)[i] = Ui32(a9, aD, aB, aE);
    end
  end
end


--#define HT(i, x, s) TT(x)[gb(x, s[(i + x) & 3])]
local function HT(i, x, s) return TT(x)[gb(x, s[(i + x) & 3])] end

local w, m

--[[
#define HT4(m, i, s, p) m[i] = \
    HT(i, 0, s) ^ \
    HT(i, 1, s) ^ \
    HT(i, 2, s) ^ \
    HT(i, 3, s) ^ w[p + i]

#define HT16(m, s, p) \
    HT4(m, 0, s, p); \
    HT4(m, 1, s, p); \
    HT4(m, 2, s, p); \
    HT4(m, 3, s, p); \
]]
local function HT4(m, i, s, p) m[i] =
    HT(i, 0, s) ~
    HT(i, 1, s) ~
    HT(i, 2, s) ~
    HT(i, 3, s) ~ w[p + i]
end

local function HT16(m, s, p)
    HT4(m, 0, s, p);
    HT4(m, 1, s, p);
    HT4(m, 2, s, p);
    HT4(m, 3, s, p);
end

local dest

--#define FT(i, x) Sbox[gb(x, m[(i + x) & 3])]
--#define FT4(i) dest[i] = Ui32(FT(i, 0), FT(i, 1), FT(i, 2), FT(i, 3)) ^ w[i];
local function FT(i, x) return Sbox[gb(x, m[(i + x) & 3])] end
local function FT4(i) dest[i] = Ui32(FT(i, 0), FT(i, 1), FT(i, 2), FT(i, 3)) ~ w[i]; end


--[[
#define HD(i, x, s) DD(x)[gb(x, s[(i - x) & 3])]

#define HD4(m, i, s, p) m[i] = \
    HD(i, 0, s) ^ \
    HD(i, 1, s) ^ \
    HD(i, 2, s) ^ \
    HD(i, 3, s) ^ w[p + i];

#define HD16(m, s, p) \
    HD4(m, 0, s, p); \
    HD4(m, 1, s, p); \
    HD4(m, 2, s, p); \
    HD4(m, 3, s, p); \
]]
local function HD(i, x, s) return DD(x)[gb(x, s[(i - x) & 3])] end

local function HD4(m, i, s, p) m[i] =
    HD(i, 0, s) ~
    HD(i, 1, s) ~
    HD(i, 2, s) ~
    HD(i, 3, s) ~ w[p + i];
end

local function HD16(m, s, p)
    HD4(m, 0, s, p);
    HD4(m, 1, s, p);
    HD4(m, 2, s, p);
    HD4(m, 3, s, p);
end

--#define FD(i, x) InvS[gb(x, m[(i - x) & 3])]
--#define FD4(i) dest[i] = Ui32(FD(i, 0), FD(i, 1), FD(i, 2), FD(i, 3)) ^ w[i];
local function FD(i, x) return InvS[gb(x, m[(i - x) & 3])] end
local function FD4(i) dest[i] = Ui32(FD(i, 0), FD(i, 1), FD(i, 2), FD(i, 3)) ~ w[i]; end

--[[ aes - 16-byte aligned pointer to keyMode+roundKeys sequence ]]
--[[ keySize = 16 or 24 or 32 (bytes) ]]

--void Z7_FASTCALL Aes_SetKey_Enc(UInt32 *w, const Byte *key, unsigned keySize)
local function Aes_SetKey_Enc(_w, key, keySize)
  w = _w
  --[[unsigned i, m;
  const UInt32 *wLim;
  UInt32 t;
  UInt32 rcon = 1;]]
  local m
  local wLim;
  local t;
  local rcon = 1;
  
  keySize /= 4;
  w[0] = (keySize / 2) + 3;
  w += 4;

  for i = 0, keySize - 1 do
    w[i] = GetUi32(key);
	key += 4
  end

  t = w[keySize - 1];
  wLim = w + keySize * 3 + 28;
  m = 0;
  repeat
    if (m == 0) then
      t = Ui32(Sbox[gb1(t)] ~ rcon, Sbox[gb2(t)], Sbox[gb3(t)], Sbox[gb0(t)]);
      rcon <<= 1;
	  rcon = UInt32(rcon)
      if (rcon & 0x100 ~= 0) then
        rcon = 0x1b;
      end
      m = keySize;
    elseif (m == 4 && keySize > 6) then
      t = Ui32(Sbox[gb0(t)], Sbox[gb1(t)], Sbox[gb2(t)], Sbox[gb3(t)]);
	end
    m -= 1;
    t ~= w[0];
    w[keySize] = t;
	
	w += 1
  until not (w != wLim);
end

--void Z7_FASTCALL Aes_SetKey_Dec(UInt32 *w, const Byte *key, unsigned keySize)
local function Aes_SetKey_Dec(_w, key, keySize)
  w = _w
  --unsigned i, num;
  local num
  Aes_SetKey_Enc(w, key, keySize);
  num = keySize + 20;
  w = _w
  
  w += 8;
  for i = 0, num - 1 do
    --UInt32 r = w[i];
    local r = UInt32(w[i]);
    w[i] =
      DD(0)[Sbox[gb0(r)]] ~
      DD(1)[Sbox[gb1(r)]] ~
      DD(2)[Sbox[gb2(r)]] ~
      DD(3)[Sbox[gb3(r)]];
  end
end

--[[ Aes_Encode and Aes_Decode functions work with little-endian words.
  src and dest are pointers to 4 UInt32 words.
  src and dest can point to same block ]]

-- Z7_FORCE_INLINE
--static void Aes_Encode(const UInt32 *w, UInt32 *dest, const UInt32 *src)
local function Aes_Encode(_w, _dest, src)
  dest = _dest
  w = _w
  --UInt32 s[4];
  --UInt32 m[4];
  --UInt32 numRounds2 = w[0];
  local s = ffi.new("UInt32[4]");
  local _m = ffi.new("UInt32[4]");
  m = _m
  local numRounds2 = w[0];
  w += 4;
  s[0] = src[0] ~ w[0];
  s[1] = src[1] ~ w[1];
  s[2] = src[2] ~ w[2];
  s[3] = src[3] ~ w[3];
  w += 4;
  while true do
    HT16(m, s, 0)
	numRounds2 -= 1
    --if (--numRounds2 == 0)
    if (numRounds2 == 0) then
      break;
	end
    HT16(s, m, 4)
    w += 8;
  end
  w += 4;
  FT4(0)
  FT4(1)
  FT4(2)
  FT4(3)
end

--Z7_FORCE_INLINE
--static void Aes_Decode(const UInt32 *w, UInt32 *dest, const UInt32 *src)
local function Aes_Decode(_w, _dest, src)
  dest = _dest
  w = _w
  --UInt32 s[4];
  --UInt32 m[4];
  --UInt32 numRounds2 = w[0];
  local s = ffi.new("UInt32[4]");
  local _m = ffi.new("UInt32[4]");
  m = _m
  local numRounds2 = w[0];
  w += 4 + numRounds2 * 8;
  s[0] = src[0] ~ w[0];
  s[1] = src[1] ~ w[1];
  s[2] = src[2] ~ w[2];
  s[3] = src[3] ~ w[3];
  while true do
    w -= 8;
    HD16(m, s, 4)
	numRounds2 -= 1
    --if (--numRounds2 == 0)
    if (numRounds2 == 0) then
      break;
	end
    HD16(s, m, 0)
  end
  FD4(0)
  FD4(1)
  FD4(2)
  FD4(3)
end

--[[ ivAes - 16-byte aligned pointer to iv+keyMode+roundKeys sequence: UInt32[AES_NUM_IVMRK_WORDS] ]]
--void AesCbc_Init(UInt32 *p, const Byte *iv)
local function AesCbc_Init(p, iv)
  --unsigned i;
  for i = 0, 4 - 1 do
    p[i] = GetUi32(iv + i * 4);
  end
end

--[[ data - 16-byte aligned pointer to data ]]
--[[ numBlocks - the number of 16-byte blocks in data array ]]

--void Z7_FASTCALL AesCbc_Encode(UInt32 *p, Byte *data, size_t numBlocks)
local function AesCbc_Encode(p, data, numBlocks)
  --for (; numBlocks != 0; numBlocks--, data += AES_BLOCK_SIZE)
  repeat
    p[0] ~= GetUi32(data);
    p[1] ~= GetUi32(data + 4);
    p[2] ~= GetUi32(data + 8);
    p[3] ~= GetUi32(data + 12);
    
    Aes_Encode(p + 4, p, p);
    
    SetUi32(data,      p[0])
    SetUi32(data + 4,  p[1])
    SetUi32(data + 8,  p[2])
    SetUi32(data + 12, p[3])
	
	numBlocks -= 1
	data += AES_BLOCK_SIZE
  until not (numBlocks != 0)
end

--void Z7_FASTCALL AesCbc_Decode(UInt32 *p, Byte *data, size_t numBlocks)
local function AesCbc_Decode(p, data, numBlocks)
  --UInt32 in[4], out[4];
  --in is a keyword in lua
  local data_in = ffi.new("UInt32[4]");
  local data_out = ffi.new("UInt32[4]");
  --for (; numBlocks != 0; numBlocks--, data += AES_BLOCK_SIZE)
  repeat
    data_in[0] = GetUi32(data);
    data_in[1] = GetUi32(data + 4);
    data_in[2] = GetUi32(data + 8);
    data_in[3] = GetUi32(data + 12);

    Aes_Decode(p + 4, data_out, data_in);

    SetUi32(data,      p[0] ~ data_out[0])
    SetUi32(data + 4,  p[1] ~ data_out[1])
    SetUi32(data + 8,  p[2] ~ data_out[2])
    SetUi32(data + 12, p[3] ~ data_out[3])
    --[[]]
    p[0] = data_in[0];
    p[1] = data_in[1];
    p[2] = data_in[2];
    p[3] = data_in[3];
	
	numBlocks -= 1
	data += AES_BLOCK_SIZE
  until not (numBlocks != 0)
end


--frontend
AesGenTables()

--decrypt a string with a key and optional iv
--angry birds does not use an iv
--calling it is really simple:
--local dec = decrypt(src, AES.Keys.Assets.Classic, nil)
function AES.Decrypt(ciphertext, key, iv)
	assert(ciphertext:len() % AES_BLOCK_SIZE == 0)

    local aes = ffi.new("UInt32[?]", (AES_NUM_IVMRK_WORDS + 3) * 2)

	iv = iv or ("\x00"):rep(AES_BLOCK_SIZE)
    local c_iv = ffi.new("Byte[?]", AES_BLOCK_SIZE + 1, iv)

    local data = ffi.new("Byte[?]", ciphertext:len() + 1, ciphertext)
    local c_key = ffi.new("Byte[?]", key:len() + 1, key)
	
	collectgarbage("stop")
	
	Aes_SetKey_Dec(aes + 4, c_key, key:len())
    
    AesCbc_Init(aes, c_iv)
	
	local size = ciphertext:len() >> 4
	
	AesCbc_Decode(aes, data, size)
	
	dest, w, m = nil, nil, nil
	
	collectgarbage("restart")
	
	--print("WILL IT WORK?")
	local out_size = size << 4
	
	--process pkcs7 padding
	local padded_bytes = data[out_size - 1]
	local final_size = out_size - padded_bytes
    
    return ffi.string(data, final_size)
end

--this is entirely untested, please fix this when necessary
function AES.Encrypt(ciphertext, key, iv)
    local aes = ffi.new("UInt32[?]", (AES_NUM_IVMRK_WORDS + 3) * 2)

	iv = iv or ("\x00"):rep(AES_BLOCK_SIZE)
    local c_iv = ffi.new("Byte[?]", AES_BLOCK_SIZE + 1, iv)

    local data = ffi.new("Byte[?]", ciphertext:len() + 1, ciphertext)
    local c_key = ffi.new("Byte[?]", key:len() + 1, key)
	
	collectgarbage("stop")
	
	Aes_SetKey_enc(aes + 4, c_key, key:len())
    
    AesCbc_Init(aes, c_iv)
	
	local size = ciphertext:len() >> 4
	
	AesCbc_Encode(aes, data, size)
	
	dest, w, m = nil, nil, nil
	
	collectgarbage("restart")
	
	--print("WILL IT WORK?")
	local out_size = size << 4
    
    return ffi.string(data, final_size)
end

--[[
#undef xtime
#undef Ui32
#undef gb0
#undef gb1
#undef gb2
#undef gb3
#undef gb
#undef TT
#undef DD
#undef USE_HW_AES
#undef PRF
]]
