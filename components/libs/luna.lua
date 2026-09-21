--romoney5
--luna is a reimplementation of the lua vm in lua, focused on performance and efficiency

--resources used:
--https://ferib.dev/blog/lua-devirtualization-part-2-decompiling-lua/ (basics, i.e. introducing opcodes)
--https://usermanual.wiki/Pdf/A20No20Frill20s20Intro20To20Lua205120VM20Instructions.560214948 (opcode list and descriptions)
--lua 5.1's lundump.c/h (header/chunk structure)
--https://www.luac.nl/ (opcode descriptions)
--https://github.com/JustAPerson/lbi/blob/master/src/lbi.lua (assistance on implementations)
--https://openpunk.com/pages/lua-bytecode-parser/ (format of iABC structure)
--https://www.lua.org/tests/ (lua 5.1 testing suite's calls.lua)
--as you can see i'm not too familiar with lua's bytecode format

local unpack = love.data.unpack

local assert = assert

--replacement for luajit's table.new if it doesn't exist
table.new = table.new or function(array_size, hash_size)
	return {}
end

--basic assert function
local function l_assert(got, expected, message)
	if got ~= expected then
		error("[Luna] "..message.." (expected "..tostring(expected)..", got "..tostring(got)..")", 2)
	end
end

local LUAC_VERSION = 0x51
local LUAC_FORMAT = 0

--stack caching (insane memory optimization)
--this option can be changed freely at runtime,
--but it's not recommended to as it uses way more memory without any gain
local cached_stacks = {}
luna_cache_stacks = true

--function prototypes so that they can be run recursively
local l_load_chunk
local l_place_returns
local l_place_varargs
local l_run_chunk
local l_error_handler

local function l_read_number(src, pos, size, unpack_endian)
	local value

	if size == 8 then
		value = unpack(unpack_endian.."d", src, pos)
	elseif size == 4 then
		value = unpack(unpack_endian.."f", src, pos)
	else
		l_assert(size, 8, "unsupported number size")
		--TODO: also support integral
	end
	
	skip(size)
	
	return value
end

--it's important for this to be optimized
local function l_decode_inst(inst)
	--parse the instruction into iABC format
	--as well as iABx and iAsBx in case an opcode needs either
	--opcode  reg. A   reg. C    reg. B
	--______ ________ _________ _________
	--000000 00000000 000000000 000000000
	--                ^^^^^^^^^^^^^^^^^^^
	--                    Bx (b and c)
	local opcode = bit.band(inst, (2 ^ 6) - 1)
	local reg_a = bit.band(bit.arshift(inst, 6), (2 ^ 8) - 1)
	local reg_b = bit.band(bit.arshift(inst, 23), (2 ^ 9) - 1)
	local reg_c = bit.band(bit.arshift(inst, 14), (2 ^ 9) - 1)
	
	local reg_bx = bit.band(bit.arshift(inst, 14), (2 ^ 18) - 1)
	local reg_sbx = reg_bx - (bit.arshift(2 ^ 18, 1) - 1) --signed bx
	
	return opcode, reg_a, reg_b, reg_c, reg_bx, reg_sbx
end

--should this be called a "chunk?"
--parse all the chunk's info into tables that luna can operate on
function l_load_chunk(src, info, chunk, name)
	local unpack_endian = info.endian == 1 and "<" or ">"

	--pos 13
	local debugname_length = unpack(unpack_endian.."i"..info.size_size, src, pos)
	skip(info.size_size)

	if debugname_length > 0 then
		chunk.debugname = readString(src, pos, debugname_length - 1)
		skip(debugname_length)
	else
		chunk.debugname = name
	end
	
	chunk.line_defined = unpack(unpack_endian.."i"..info.size_int, src, pos)
	skip(info.size_int)
	
	chunk.last_line_defined = unpack(unpack_endian.."i"..info.size_int, src, pos)
	skip(info.size_int)
	
	chunk.num_upvalues = unpack(unpack_endian.."i"..info.size_byte, src, pos)
	skip(info.size_byte)
	
	chunk.num_parameters = unpack(unpack_endian.."i"..info.size_byte, src, pos)
	skip(info.size_byte)
	
	chunk.is_vararg = unpack(unpack_endian.."i"..info.size_byte, src, pos)
	skip(info.size_byte)
	
	chunk.max_stack_size = unpack(unpack_endian.."i"..info.size_byte, src, pos)
	skip(info.size_byte)
	
	
	--load instructions
	--cache them all consecutively so that instructions
	--don't have to be decoded at runtime
	local num_instructions = unpack(unpack_endian.."i"..info.size_int, src, pos)
	skip(info.size_int)
	
	chunk.instructions_opcodes = ffi.new("int32_t[?]", num_instructions)--table.new(num_instructions, 0)
	chunk.instructions_regs = ffi.new("int32_t[?]", num_instructions * 5)--table.new(num_instructions * 5, 0)
	
	for i = 1, num_instructions do
		local inst = unpack(unpack_endian.."i"..info.size_inst, src, pos)
		local opcode, reg_a, reg_b, reg_c, reg_bx, reg_sbx = l_decode_inst(inst)
		
		chunk.instructions_opcodes[i - 1] = opcode
		
		chunk.instructions_regs[i * 5 - 5] = reg_a
		chunk.instructions_regs[i * 5 - 4] = reg_b
		chunk.instructions_regs[i * 5 - 3] = reg_c
		chunk.instructions_regs[i * 5 - 2] = reg_bx
		chunk.instructions_regs[i * 5 - 1] = reg_sbx
		
		skip(info.size_inst)
	end
	
	
	--load constants
	local num_constants = unpack(unpack_endian.."i"..info.size_int, src, pos)
	skip(info.size_int)
	
	chunk.constants = table.new(num_constants, 0)
	
	local LUA_TNIL = 0
	local LUA_TBOOLEAN = 1
	local LUA_TNUMBER = 3
	local LUA_TSTRING = 4
	
	for i = 1, num_constants do
		local constant_type = unpack(unpack_endian.."i"..info.size_byte, src, pos)
		skip(info.size_byte)
		
		if constant_type == LUA_TNIL then
			chunk.constants[i] = nil
		elseif constant_type == LUA_TBOOLEAN then
			local value = unpack(unpack_endian.."i"..info.size_byte, src, pos)
			skip(info.size_byte)
			
			chunk.constants[i] = value ~= 0
		elseif constant_type == LUA_TNUMBER then
			local value = l_read_number(src, pos, info.size_number, unpack_endian)
			
			chunk.constants[i] = value
		elseif constant_type == LUA_TSTRING then
			local length = unpack(unpack_endian.."i"..info.size_size, src, pos)
			skip(info.size_size)

			local value = readString(src, pos, length - 1)
			skip(length)
			
			chunk.constants[i] = value
		else
			l_assert(constant_type, "nil, boolean, number, or string", "invalid constant type in index "..i)
		end
	end
	
	--I am Proto! Your security is my.. motto!
	local num_protos = unpack(unpack_endian.."i"..info.size_int, src, pos)
	skip(info.size_int)
	
	chunk.protos = table.new(num_protos, 0)
	
	for i = 1, num_protos do
		chunk.protos[i] = {}
		chunk.protos[i].env = chunk.env
		l_load_chunk(src, info, chunk.protos[i], name)
	end
	
	--parse debug info (disabled as it is not used in luna)
	local num_line_info = unpack(unpack_endian.."i"..info.size_int, src, pos)
	skip(info.size_int)
	
	--chunk.line_info = table.new(num_line_info, 0)
	
	for i = 1, num_line_info do
		--chunk.line_info[i] = unpack(unpack_endian.."i"..info.size_int, src, pos)
		skip(info.size_int)
	end
	
	
	local num_local_vars = unpack(unpack_endian.."i"..info.size_int, src, pos)
	skip(info.size_int)
	
	--chunk.local_vars = table.new(num_local_vars, 0)
	
	for i = 1, num_local_vars do
		local length_name = unpack(unpack_endian.."i"..info.size_size, src, pos)
		skip(info.size_size)

		--local name = readString(src, pos, length_name - 1)
		skip(length_name)
		
		--local start_pc = unpack(unpack_endian.."i"..info.size_int, src, pos)
		skip(info.size_int)
		
		--local end_pc = unpack(unpack_endian.."i"..info.size_int, src, pos)
		skip(info.size_int)
		
		--[[
		chunk.local_vars[i] = {
			name = name,
			start_pc = start_pc,
			end_pc = end_pc,
		}
		]]
	end
	
	
	local num_upvalue_names = unpack(unpack_endian.."i"..info.size_int, src, pos)
	skip(info.size_int)
	
	--chunk.upvalue_names = table.new(num_upvalue_names, 0)
	
	for i = 1, num_upvalue_names do
		local length_name = unpack(unpack_endian.."i"..info.size_size, src, pos)
		skip(info.size_size)

		--local name = readString(src, pos, length_name - 1)
		skip(length_name)
		
		--chunk.upvalue_names[i] = name
	end
end

local function l_load_header(src, info)
	pos = 1

	info.signature = readString(src, pos, 4)
	skip(4)
	l_assert(info.signature, "\x1bLua", "lua signature does not match")

	info.version = read8Int(src, pos)
	skip(1)
	l_assert(info.version, LUAC_VERSION, "lua version does not match")

	info.official = read8Int(src, pos) --0 = official
	l_assert(info.official, LUAC_FORMAT, "lua format does not match")
	skip(1)

	info.endian = read8Int(src, pos) --1 = little endian
	skip(1)

	info.size_int = read8Int(src, pos) --4 = size of int is 4 bytes
	skip(1)

	info.size_size = read8Int(src, pos) --4 = size of size is 4 (or 8 for 64-bit) bytes
	skip(1)

	info.size_inst = read8Int(src, pos) --4 = size of instruction is 4 bytes
	skip(1)

	info.size_number = read8Int(src, pos) --8 = size of lua number is 8 (or 4 in angry birds) bytes
	skip(1)

	info.integral = read8Int(src, pos) --does the chunk only support integers
	skip(1)
	
	info.size_byte = 1
end

local function l_get_constant(chunk, stack, register)
	if register > 255 then
		return chunk.constants[register - 255]
	else
		return stack[register]
	end
end

--closes all upvalues starting from stack index [start]
local function l_close_upvalues(stack, start)
	if not stack.open_upvalues then
		return
	end
	
	for i = start, stack.top do
		local upvalue = stack.open_upvalues[i]
		
		if upvalue then
			--i is the upvalue stack number
			upvalue[3] = upvalue[2][upvalue[1]]
			upvalue[1] = 3
			upvalue[2] = upvalue
			
			stack.open_upvalues[i] = nil
		end
	end
end

--the list of opcode functions
local instructions
instructions = {
	--MOVE; copies stack's B to stack's A
	[0] = {name = "MOVE"},
	--LOADK; loads a constant found in Bx into stack's A
	[1] = {name = "LOADK", uses_constants = {bx = true}},
	--LOADBOOL; loads a boolean into stack's A and jumps an instruction if c ~= 0
	[2] = {name = "LOADBOOL"},
	--LOADNIL; loads nil values from stack's A to stack's B
	[3] = {name = "LOADNIL"},
	--GETUPVAL; retrieves an upvalue B into stack's A
	[4] = {name = "GETUPVAL"},
	--GETGLOBAL; loads a constant found in Bx, gets it from the env, and puts it into stack's A
	[5] = {name = "GETGLOBAL", uses_constants = {bx = true}},
	--GETTABLE; gets an index (constant C) from a table found in stack's B, and puts it into stack's A
	[6] = {name = "GETTABLE", uses_constants = {c = true}},
	--SETGLOBAL; sets an env variable (constant Bx) to stack's A
	[7] = {name = "SETGLOBAL", uses_constants = {bx = true}},
	--SETUPVAL; sets an upvalue B's value to stack's A
	[8] = {name = "SETUPVAL"},
	--SETTABLE; sets an index (constant B) of a table, found in stack's A, to constant C
	[9] = {name = "SETTABLE", uses_constants = {b = true, c = true}},
	--NEWTABLE; creates a new table with array size B and hash size C, and puts it into stack's A
	[10] = {name = "NEWTABLE"},
	--SELF; same as GETTABLE, but also sets stack's A + 1 to the table itself
	[11] = {name = "SELF", uses_constants = {c = true}},
	--ADD; performs addition on constants B and C, putting the result in stack's A
	[12] = {name = "ADD", uses_constants = {b = true, c = true}},
	--SUB; performs subtraction on constants B and C, putting the result in stack's A
	[13] = {name = "SUB", uses_constants = {b = true, c = true}},
	--MUL; performs multiplication on constants B and C, putting the result in stack's A
	[14] = {name = "MUL", uses_constants = {b = true, c = true}},
	--DIV; performs division on constants B and C, putting the result in stack's A
	[15] = {name = "DIV", uses_constants = {b = true, c = true}},
	--MOD; performs modulus on constants B and C, putting the result in stack's A
	[16] = {name = "MOD", uses_constants = {b = true, c = true}},
	--POW; performs exponentiation on constants B and C, putting the result in stack's A
	[17] = {name = "POW", uses_constants = {b = true, c = true}},
	--UNM; sets stack's A to the negative of stack's B
	[18] = {name = "UNM"},
	--NOT; sets stack's A to "not" stack's B
	[19] = {name = "NOT"},
	--LEN; sets stack's A to "#" (length of) stack's B
	[20] = {name = "LEN"},
	--CONCAT; concatenates values from stack's B to stack's C, putting the result in stack's A
	[21] = {name = "CONCAT"},
	--JMP; unconditionally jumps ahead sBx instructions (can be negative or positive)
	[22] = {name = "JMP"},
	--EQ; calculates if constants B and C are equal (or unequal if A is 1),
	--skipping an instruction ahead if not
	[23] = {name = "EQ", uses_constants = {b = true, c = true}},
	--LT; calculates if constant B is less than constant C (or greater if A is 1),
	--skipping an instruction ahead if not
	[24] = {name = "LT", uses_constants = {b = true, c = true}},
	--LE; calculates if constant B is less than or equal to constant C (or greater than/equal if A is 1),
	--skipping an instruction ahead if not
	[25] = {name = "LE", uses_constants = {b = true, c = true}},
	--TEST; converts stack's A into a boolean, skipping an instruction ahead if it is unequal to C's boolean
	[26] = {name = "TEST"},
	--TESTSET; converts stack's B into a boolean, setting stack's A to stack's B if it is equal to C's boolean,
	--otherwise skipping an instruction ahead
	[27] = {name = "TESTSET"},
	--CALL; calls a function found in stack's A, with no. arguments B - 1 and no. return values C - 1
	--(both of them adapt to whatever was passed in/returned if their respective register is 0)
	[28] = {name = "CALL"},
	--TAILCALL; similar to CALL but performs a tail call (not very effective here
	--as it's very hard to emulate tail calls)
	[29] = {name = "TAILCALL"},
	--RETURN; returns values from stack's A to stack's B (or the stack's top if B is 0)
	[30] = {name = "RETURN"},
	--FORLOOP; jumps to the start of a loop and increments if the current index < the current limit
	[31] = {name = "FORLOOP"},
	--FORPREP; skips ahead to the FORLOOP instruction and initializes stack's A
	[32] = {name = "FORPREP"},
	--TFORLOOP; initializes a generic for loop by calling the iterator function
	[33] = {name = "TFORLOOP"},
	--SETLIST; sets an amount of values B (or up to stack's top if 0) of a table found in stack's A, starting from C
	[34] = {name = "SETLIST"},
	--CLOSE; closes all upvalues starting from A, making them local to the closure that used them
	[35] = {name = "CLOSE"},
	--CLOSURE; creates a closure using proto Bx + 1, initializing upvalues if necessary
	[36] = {name = "CLOSURE"},
	--VARARG; copies B (or all) amount of varargs into stack's A and beyond
	[37] = {name = "VARARG"},
}

function l_place_returns(stack, target_index, num, ...)
	--pop the function and arguments from the stack
	for i = target_index, stack.top do
		stack[i] = nil
	end
	
	num = num or select("#", ...)
	
	stack.top = target_index - 1 + num

	for i = 1, num do
		stack[target_index + i - 1] = select(i, ...)
	end
end

function l_place_varargs(stack, ...)
	local num = select("#", ...)
	
	stack.vararg_num = num --i hate to do this

	for i = -1, -num, -1 do
		stack[i] = select(-i, ...)
	end
end

--loops through and runs instructions in the chunk
local function l_run_instructions(stack, chunk)
	while true do
		local program_counter = stack.program_counter
		local opcode = chunk.instructions_opcodes[program_counter - 1]
		local a, b, c, bx, sbx =
			chunk.instructions_regs[program_counter * 5 - 5],
			chunk.instructions_regs[program_counter * 5 - 4],
			chunk.instructions_regs[program_counter * 5 - 3],
			chunk.instructions_regs[program_counter * 5 - 2],
			chunk.instructions_regs[program_counter * 5 - 1]
		
		stack.program_counter = stack.program_counter + 1
		
		--call the opcode
		if opcode == 0 then --MOVE; copies stack's B to stack's A
			stack[a] = stack[b]
			stack.top = a
		elseif opcode == 1 then --LOADK; loads a constant found in Bx into stack's A
			local constant = chunk.constants[bx + 1]
			
			stack[a] = constant
			stack.top = a
		elseif opcode == 2 then --LOADBOOL; loads a boolean into stack's A and jumps an instruction if c ~= 0
			stack[a] = b ~= 0
			
			if c ~= 0 then
				stack.program_counter = stack.program_counter + 1
			end
			stack.top = a
		elseif opcode == 3 then --LOADNIL; loads nil values from stack's A to stack's B
			for i = a, b do
				stack[i] = nil
			end
			stack.top = b
		elseif opcode == 4 then --GETUPVAL; retrieves an upvalue B into stack's A
			local upvalue = stack.upvalues[b + 1]
			
			stack[a] = upvalue[2][upvalue[1]]
			stack.top = a
		elseif opcode == 5 then --GETGLOBAL; loads a constant found in Bx, gets it from the env, and puts it into stack's A
			local constant = chunk.constants[bx + 1]
			
			stack[a] = chunk.env[constant]
			stack.top = a
		elseif opcode == 6 then --GETTABLE; gets an index (constant C) from a table found in stack's B, and puts it into stack's A
			local value_2 = l_get_constant(chunk, stack, c)
			
			stack[a] = stack[b][value_2]
			stack.top = a
		elseif opcode == 7 then --SETGLOBAL; sets an env variable (constant Bx) to stack's A
			local constant = chunk.constants[bx + 1]
			
			chunk.env[constant] = stack[a]
		elseif opcode == 8 then --SETUPVAL; sets an upvalue B's value to stack's A
			local upvalue = stack.upvalues[b + 1]
			upvalue[2][upvalue[1]] = stack[a]
			--this shouldn't update the origin's top
		elseif opcode == 9 then --SETTABLE; sets an index (constant B) of a table, found in stack's A, to constant C
			local value_1 = l_get_constant(chunk, stack, b)
			local value_2 = l_get_constant(chunk, stack, c)
			
			stack[a][value_1] = value_2
		elseif opcode == 10 then --NEWTABLE; creates a new table with array size B and hash size C, and puts it into stack's A
			stack[a] = table.new(b, c)
			stack.top = a
		elseif opcode == 11 then --SELF; same as GETTABLE, but also sets stack's A + 1 to the table itself
			local value_2 = l_get_constant(chunk, stack, c)
			
			--the order matters here for some reason?
			stack[a + 1] = stack[b]
			stack[a] = stack[b][value_2]
			
			stack.top = a + 1
		elseif opcode == 12 then --ADD; performs addition on constants B and C, putting the result in stack's A
			local value_1 = l_get_constant(chunk, stack, b)
			local value_2 = l_get_constant(chunk, stack, c)
			
			stack[a] = value_1 + value_2
			stack.top = a
		elseif opcode == 13 then --SUB; performs subtraction on constants B and C, putting the result in stack's A
			local value_1 = l_get_constant(chunk, stack, b)
			local value_2 = l_get_constant(chunk, stack, c)
			
			stack[a] = value_1 - value_2
			stack.top = a
		elseif opcode == 14 then --MUL; performs multiplication on constants B and C, putting the result in stack's A
			local value_1 = l_get_constant(chunk, stack, b)
			local value_2 = l_get_constant(chunk, stack, c)
			
			stack[a] = value_1 * value_2
			stack.top = a
		elseif opcode == 15 then --DIV; performs division on constants B and C, putting the result in stack's A
			local value_1 = l_get_constant(chunk, stack, b)
			local value_2 = l_get_constant(chunk, stack, c)
			
			stack[a] = value_1 / value_2
			stack.top = a
		elseif opcode == 16 then --MOD; performs modulus on constants B and C, putting the result in stack's A
			local value_1 = l_get_constant(chunk, stack, b)
			local value_2 = l_get_constant(chunk, stack, c)
			
			stack[a] = value_1 % value_2
			stack.top = a
		elseif opcode == 17 then --POW; performs exponentiation on constants B and C, putting the result in stack's A
			local value_1 = l_get_constant(chunk, stack, b)
			local value_2 = l_get_constant(chunk, stack, c)
			
			stack[a] = value_1 ^ value_2
			stack.top = a
		elseif opcode == 18 then --UNM; sets stack's A to the negative of stack's B
			stack[a] = -stack[b]
			stack.top = a
		elseif opcode == 19 then --NOT; sets stack's A to "not" stack's B
			stack[a] = not stack[b]
			stack.top = a
		elseif opcode == 20 then --LEN; sets stack's A to "#" (length of) stack's B
			stack[a] = #stack[b]
			stack.top = a
		elseif opcode == 21 then --CONCAT; concatenates values from stack's B to stack's C, putting the result in stack's A
			stack[a] = stack[b]
			
			for i = b + 1, c do
				stack[a] = stack[a]..stack[i]
			end
			stack.top = a
		elseif opcode == 22 then --JMP; unconditionally jumps ahead sBx instructions (can be negative or positive)
			stack.program_counter = stack.program_counter + sbx
		elseif opcode == 23 then --EQ; calculates if constants B and C are equal (or unequal if A is 1),
		--skipping an instruction ahead if not
			local value_1 = l_get_constant(chunk, stack, b)
			local value_2 = l_get_constant(chunk, stack, c)
			
			local target = a == 1
			
			if (value_1 == value_2) ~= target then
				stack.program_counter = stack.program_counter + 1
			end
		elseif opcode == 24 then --LT; calculates if constant B is less than constant C (or greater if A is 1),
		--skipping an instruction ahead if not
			local value_1 = l_get_constant(chunk, stack, b)
			local value_2 = l_get_constant(chunk, stack, c)
			
			local target = a == 1
			
			if (value_1 < value_2) ~= target then
				stack.program_counter = stack.program_counter + 1
			end
		elseif opcode == 25 then --LE; calculates if constant B is less than or equal to constant C (or greater than/equal if A is 1),
		--skipping an instruction ahead if not
			local value_1 = l_get_constant(chunk, stack, b)
			local value_2 = l_get_constant(chunk, stack, c)
			
			local target = a == 1
			
			if (value_1 <= value_2) ~= target then
				stack.program_counter = stack.program_counter + 1
			end
		elseif opcode == 26 then --TEST; converts stack's A into a boolean, skipping an instruction ahead if it is unequal to C's boolean
			if (not not stack[a]) ~= (c ~= 0) then
				stack.program_counter = stack.program_counter + 1
			end
		elseif opcode == 27 then --TESTSET; converts stack's B into a boolean, setting stack's A to stack's B if it is equal to C's boolean,
		--otherwise skipping an instruction ahead
			if (not not stack[b]) == (c ~= 0) then
				stack[a] = stack[b]
				
				stack.top = a
			else
				stack.program_counter = stack.program_counter + 1
			end
		elseif opcode == 28 then --CALL; calls a function found in stack's A, with no. arguments B - 1 and no. return values C - 1
		--(both of them adapt to whatever was passed in/returned if their respective register is 0)
			local num_args = b - 1
			local num_returns = c - 1
			
			--if b is 0, the call parameters will default to the top of the stack
			if b == 0 then
				num_args = stack.top - a
			else
				stack.top = a + b
			end
			
			--hack: override environment functions
			if stack[a] == getfenv then
				l_place_returns(stack, a, nil, chunk.env)
			elseif stack[a] == setfenv and stack[a + 1] == 1 then
				chunk.env = stack[a + 2]
				l_place_returns(stack, a)
			else
				--if c is 0, l_place_returns will default to the amount of args
				l_place_returns(stack, a, c > 0 and num_returns, stack[a](table.unpack(stack, a + 1, a + num_args)))
			end
		elseif opcode == 29 then --TAILCALL; similar to CALL but performs a tail call (not very effective here
		--as it's very hard to emulate tail calls)
			local num_args = b - 1
			local num_returns = c - 1
			
			--if b is 0, the call parameters will default to the top of the stack
			if b == 0 then
				num_args = stack.top - a
			end
			
			--[[
										   -
					  -                 - - -             -
			----   - -   -    -     -  -          -     - --
					-          -     -        -       -   ---
						-       -  -            -   -
								 -             
			]]
			
			return stack[a](table.unpack(stack, a + 1, a + num_args))
		elseif opcode == 30 then --RETURN; returns values from stack's A to stack's B (or the stack's top if B is 0)
			local num_returns = b - 1
			
			--if b is 0, the amount of returns will default to the top of the stack
			if b == 0 then
				num_returns = stack.top - a + 1
			end
			
			return table.unpack(stack, a, a - 1 + num_returns)
		elseif opcode == 31 then --FORLOOP; jumps to the start of a loop and increments if the current index < the current limit
			local value = stack[a] --the initial value
			local limit = stack[a + 1]
			local step = stack[a + 2]
			local external_value = stack[a + 3] --the visible value (e.g. i)
			
			stack[a] = value + step
			
			--jump back to FORPREP + 1 if..
			if stack[a] * step <= limit * step then
				stack.program_counter = stack.program_counter + sbx
				stack[a + 3] = stack[a]
			end
			
			stack.top = a + 3
		elseif opcode == 32 then --FORPREP; skips ahead to the FORLOOP instruction and initializes stack's A
			local value = stack[a]
			local limit = stack[a + 1]
			local step = stack[a + 2]
			local external_value = stack[a + 3]
			
			stack[a] = stack[a] - step
			
			--jump to the FORLOOP
			stack.program_counter = stack.program_counter + sbx
		elseif opcode == 33 then --TFORLOOP; initializes a generic for loop by calling the iterator function
			local value = stack[a] --the initial value
			local limit = stack[a + 1]
			local step = stack[a + 2]
			local external_value = stack[a + 3] --the visible value (e.g. i)
			
			--jump back if..
			l_place_returns(stack, a + 3, (a + 2 + c) - (a + 3) + 1, stack[a](stack[a + 1], stack[a + 2]))
			
			if stack[a + 3] ~= nil then
				stack[a + 2] = stack[a + 3]
			else
				stack.program_counter = stack.program_counter + 1
			end
		elseif opcode == 34 then --SETLIST; sets an amount of values B (or up to stack's top if 0) of a table found in stack's A, starting from C
			--let's assume no one is changing this in c
			local LFIELDS_PER_FLUSH = 50
			
			local num_args = b
			
			--if b is 0, the call parameters will default to the top of the stack
			if b == 0 then
				num_args = stack.top - a
			end
			
			for i = 1, num_args do
				stack[a][(c - 1) * LFIELDS_PER_FLUSH + i] = stack[a + i]
			end
		elseif opcode == 35 then --CLOSE; closes all upvalues starting from A, making them local to the closure that used them
			l_close_upvalues(stack, a)
		elseif opcode == 36 then --CLOSURE; creates a closure using proto Bx + 1, initializing upvalues if necessary
			local proto = chunk.protos[bx + 1]
			
			local upvalues
			
			--lua's upvalue system is hacky
			for i = 1, proto.num_upvalues do
				local opcode = chunk.instructions_opcodes[stack.program_counter - 1]
				local reg_b = chunk.instructions_regs[stack.program_counter * 5 - 4]
				
				--making tables is scary here
				upvalues = upvalues or table.new(proto.num_upvalues, 0)
				stack.open_upvalues = stack.open_upvalues or table.new(proto.num_upvalues, 0)
				
				if opcode == 0 then --mMOVE
					--open an upvalue
					--upvalue_num is the index in the stack
					--GETUPVAL uses that index
					--i is the index in the upvalues table
					local upvalue_num = reg_b
					
					--open_upvalue functions similarly to upvalue,
					--but deals with currently opened upvalues
					--this is needed so that repeated upvalues share the same table
					local open_upvalue = stack.open_upvalues[upvalue_num]
					
					if not open_upvalue then
						upvalues[i] = {upvalue_num, stack}
					else
						upvalues[i] = open_upvalue
					end
					
					stack.open_upvalues[upvalue_num] = upvalues[i]
				elseif opcode == 4 then --GETUPVAL
					--open an upvalue from an existing upvalue
					local upvalue_i = reg_b + 1
					local upvalue = stack.upvalues[upvalue_i]
					local upvalue_num = upvalue[1]
					local upvalue_origin = upvalue[2]
					
					l_assert(upvalue_origin ~= nil, true, "no upvalue found")
					
					upvalues[i] = upvalue
				else
					l_assert(instructions[opcode].name, "MOVE or GETUPVAL", "unexpected opcode "..opcode.." after closure instruction")
				end
				
				stack.program_counter = stack.program_counter + 1
			end
			
			--wrap the function
			stack[a] = function(...)
				return l_run_chunk(proto, upvalues, ...)
			end
			stack.top = a
		elseif opcode == 37 then --VARARG; copies B (or all) amount of varargs into stack's A and beyond
			local start = a
			local num = b - 1
			
			local i = start
			local evil_i = -1
			
			--if b is 0, the amount of copied parameters will adjust
			while (b == 0 and -evil_i <= stack.vararg_num) or (b ~= 0 and i <= start + num) do
				stack[i] = stack[evil_i]
				
				i = i + 1
				evil_i = evil_i - 1
			end
			
			stack.top = start - evil_i - 2
		end
	end
end

--general function for running a chunk
function l_run_chunk(chunk, upvalues, ...)
	--if a stack table is cached, use it and free it from the cache
	local stack = luna_cache_stacks and cached_stacks[#cached_stacks] or {}
	cached_stacks[#cached_stacks] = nil
	
	stack.upvalues = upvalues
	stack.top = 0
	
	--program_counter is the next instruction to execute
	stack.program_counter = 1
	
	--put parameters and varargs into place
	local is_vararg = chunk.is_vararg
	local VARARG_HASARG = 1 --"arg" support compiled in
	local VARARG_ISVARARG = 2 --function uses varargs
	local VARARG_NEEDSARG = 4 --function body does not use ...
	
	l_place_returns(stack, 0, chunk.num_parameters, ...)
	
	if bit.band(is_vararg, VARARG_ISVARARG) ~= 0 then
		if bit.band(is_vararg, VARARG_HASARG) ~= 0 and bit.band(is_vararg, VARARG_NEEDSARG) ~= 0 then --needs "arg"
			stack[chunk.num_parameters] = {...}
		else
			l_place_varargs(stack, select(chunk.num_parameters + 1, ...))
		end
	end
	
	return l_error_handler(stack, chunk, pcall(l_run_instructions, stack, chunk))
end

--debug error handler, which prints a snapshot of previous instructions in the file
--unlike the previous error blame implementation this doesn't deal with executed instructions
function l_error_handler(stack, chunk, success, ...)
	if not success then
		local message = ...
		local out = tostring(message)..("\n[Luna] Recent instructions (%s):\n"):format(chunk.debugname)
		
		for i = math.max(stack.program_counter - 16 - 32, 1), stack.program_counter - 1 do
			local program_counter = i
			local opcode = chunk.instructions_opcodes[program_counter - 1]
			local reg_a, reg_b, reg_c, reg_bx, reg_sbx =
				chunk.instructions_regs[program_counter * 5 - 5],
				chunk.instructions_regs[program_counter * 5 - 4],
				chunk.instructions_regs[program_counter * 5 - 3],
				chunk.instructions_regs[program_counter * 5 - 2],
				chunk.instructions_regs[program_counter * 5 - 1]
			
			if i == stack.program_counter - 1 then
				out = out.."-> "
			end
			
			out = out..("#%d: %s \t%d \t%d \t%d"):format(i, instructions[opcode].name, reg_a, reg_b, reg_c)
			
			local uses_constants = instructions[opcode].uses_constants
			if uses_constants then
				if uses_constants.b and reg_b > 255 and chunk.constants[reg_b - 255] ~= nil then
					out = out.."    \t; B= "..tostring(chunk.constants[reg_b - 255])
				end
				
				if uses_constants.c and reg_c > 255 and chunk.constants[reg_c - 255] ~= nil then
					out = out.."    \t; C= "..tostring(chunk.constants[reg_c - 255])
				end
				
				if uses_constants.bx and chunk.constants[reg_bx] ~= nil then
					out = out.."    \t; Bx= "..tostring(chunk.constants[reg_bx + 1])
				end
			end
			
			out = out.."\n"
		end
		
		--this line shouldn't be to blame,
		--nor the caller of l_error_handler
		error(out, 3)
	end
	
	--close all upvalues right at the end
	l_close_upvalues(stack, 0)
	
	--the call operation always makes a stack, so go ahead and clear it for later usage
	--this can save MASSIVE amounts of memory overhead
	if luna_cache_stacks then
		table.insert(cached_stacks, stack)
		
		table.clear(stack)
	end
	
	--cap the amount of cached stacks
	if #cached_stacks > 128 then
		cached_stacks[#cached_stacks] = nil
	end
	
	return ...
end

--load a bytecode lua file
local function l_load(src, env, name)
	--first, parse the file's header
	local info = {}
	
	l_load_header(src, info)
	
	--then parse the protos
	info.chunk = {}
	
	local chunk = info.chunk
	
	chunk.env = env
	
	l_load_chunk(src, info, chunk, name)
	
	--return a function that runs the chunk
	return function(...)
		return l_run_chunk(chunk, nil, ...)
	end
end

return l_load
