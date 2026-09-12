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

--uncomment later
--[[table.new = table.new or function(a, b)
	return {}
end]]

local function l_assert(got, expected, message)
	if got ~= expected then
		error("run: "..message.." (expected "..tostring(expected)..", got "..tostring(got)..")", 2)
	end
end

local function l_debug_print(...)
	--print(...)
end

local LUAC_VERSION = 0x51
local LUAC_FORMAT = 0
local LUAC_HEADERSIZE = 12

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

--should this be called a "chunk?"
--parse all the chunk's info into tables that luna can operate on
local l_load_chunk
function l_load_chunk(src, info, chunk, name)
	l_debug_print("parsing chunk")
	
	local unpack_endian = info.endian == 1 and "<" or ">"

	--pos 13
	local debugname_length = unpack(unpack_endian.."i"..info.size_size, src, pos)
	skip(info.size_size)

	if debugname_length > 0 then
		chunk.debugname = readString(src, pos, debugname_length - 1)
		skip(debugname_length)
		l_debug_print("chunk.debugname is ", chunk.debugname)
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
	
	l_debug_print("chunk.num_upvalues is ", chunk.num_upvalues)
	l_debug_print("chunk.num_parameters is ", chunk.num_parameters)
	l_debug_print("chunk.is_vararg is ", chunk.is_vararg)
	l_debug_print("chunk.max_stack_size is ", chunk.max_stack_size)
	
	--load instructions
	local num_instructions = unpack(unpack_endian.."i"..info.size_int, src, pos)
	skip(info.size_int)
	
	chunk.instructions = table.new(num_instructions, 0)
	
	for i = 1, num_instructions do
		chunk.instructions[i] = unpack(unpack_endian.."i"..info.size_inst, src, pos)
		skip(info.size_inst)
	end
	
	l_debug_print("chunk.num_instructions is ", chunk.num_instructions)
	
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
		
		--l_debug_print(chunk.constants[i])
	end
	
	l_debug_print("chunk.num_constants is ", chunk.num_constants)
	
	--I am Proto! Your security is my.. motto!
	local num_protos = unpack(unpack_endian.."i"..info.size_int, src, pos)
	skip(info.size_int)
	
	chunk.protos = table.new(num_protos, 0)
	
	for i = 1, num_protos do
		l_debug_print("found a proto")
		
		chunk.protos[i] = {}
		chunk.protos[i].env = chunk.env
		l_load_chunk(src, info, chunk.protos[i], name)
	end
	
	l_debug_print("chunk.num_protos is ", chunk.num_protos)
	
	--parse debug
	local num_line_info = unpack(unpack_endian.."i"..info.size_int, src, pos)
	skip(info.size_int)
	
	chunk.line_info = table.new(num_line_info, 0)
	
	for i = 1, num_line_info do
		chunk.line_info[i] = unpack(unpack_endian.."i"..info.size_int, src, pos)
		skip(info.size_int)
	end
	
	l_debug_print("chunk.num_line_info is ", chunk.num_line_info)
	
	
	local num_local_vars = unpack(unpack_endian.."i"..info.size_int, src, pos)
	skip(info.size_int)
	
	chunk.local_vars = table.new(num_local_vars, 0)
	
	for i = 1, num_local_vars do
		local length_name = unpack(unpack_endian.."i"..info.size_size, src, pos)
		skip(info.size_size)

		local name = readString(src, pos, length_name - 1)
		skip(length_name)
		
		local start_pc = unpack(unpack_endian.."i"..info.size_int, src, pos)
		skip(info.size_int)
		
		local end_pc = unpack(unpack_endian.."i"..info.size_int, src, pos)
		skip(info.size_int)
		
		chunk.local_vars[i] = {
			name = name,
			start_pc = start_pc,
			end_pc = end_pc,
		}
	end
	
	l_debug_print("chunk.num_local_vars is ", chunk.num_local_vars)
	
	
	local num_upvalue_names = unpack(unpack_endian.."i"..info.size_int, src, pos)
	skip(info.size_int)
	
	chunk.upvalue_names = table.new(num_upvalue_names, 0)
	
	for i = 1, num_upvalue_names do
		local length_name = unpack(unpack_endian.."i"..info.size_size, src, pos)
		skip(info.size_size)

		local name = readString(src, pos, length_name - 1)
		skip(length_name)
		
		chunk.upvalue_names[i] = name
	end
	
	l_debug_print("chunk.num_upvalue_names is ", chunk.num_upvalue_names)
	l_debug_print("finished chunk")
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

	info.size_number = read8Int(src, pos) --8 = size of lua number is 8 (or 4 for angry birds) bytes
	skip(1)

	info.integral = read8Int(src, pos) --does the chunk only support integers
	skip(1)
	
	info.size_byte = 1

	l_debug_print("luna:")
	l_debug_print("info.official is ", info.official)
	l_debug_print("info.endian is ", info.endian)
	l_debug_print("info.size_int is ", info.size_int)
	l_debug_print("info.size_size is ", info.size_size)
	l_debug_print("info.size_inst is ", info.size_inst)
	l_debug_print("info.size_number is ", info.size_number)
	l_debug_print("info.integral is ", info.integral)
end

local l_place_returns
local l_place_varargs
local l_decode_inst
local l_run_chunk
local l_error_handler
local l_finish_chunk

local function l_get_constant(chunk, stack, register)
	if register > 255 then
		return chunk.constants[register - 255]
	else
		return stack[register]
	end
end

local function l_update_top(stack, a)
	if a > stack.top then
		stack.top = a
	end
end

local function l_close_upvalues(stack, start)
	if not stack.open_upvalues then
		return
	end
	
	for i = start, stack.top do
		local upvalues = stack.open_upvalues[i]
		
		if upvalues then
			--i is the upvalue stack number
			--v is the same
			--ii is the upvalue number
			for ii, v in ipairs(upvalues) do
				if v == i then
					upvalues[-ii] = {[i] = upvalues[-ii][i]}
				end
			end
			
			stack.open_upvalues[i] = nil
		end
	end
end

--idea Copied from lbi
local meta = {
	__newindex = function(self, k, v)
		if type(k) == "number" then
			l_update_top(self, k)
		end
		
		rawset(self, k, v)
	end,
}

--stack caching (insane memory optimization)
--this cannot be changed at runtime
--TODO: what if the table sizes get too big?
local free_stacks = {}
luna_cache_stacks = not true --this needs more work

--the list of opcode functions
local instructions
instructions = {
	--MOVE; copies stack's B to stack's A
	[0] = {name = "MOVE", action = function(info, chunk, stack, a, b, c, bx)
		stack[a] = stack[b]
	end},
	--LOADK; loads a constant found in Bx into stack's A
	[1] = {name = "LOADK", action = function(info, chunk, stack, a, b, c, bx)
		local constant = chunk.constants[bx + 1]
		
		stack[a] = constant
	end, uses_constants = {bx = true}},
	--LOADBOOL
	[2] = {name = "LOADBOOL", action = function(info, chunk, stack, a, b, c, bx)
		stack[a] = b ~= 0
		
		if c ~= 0 then
			stack.program_counter = stack.program_counter + 1
		end
	end},
	--LOADNIL
	[3] = {name = "LOADNIL", action = function(info, chunk, stack, a, b, c, bx)
		for i = a, b do
			stack[i] = nil
		end
	end},
	--GETUPVAL
	[4] = {name = "GETUPVAL", action = function(info, chunk, stack, a, b, c, bx)
		--l_debug_print("getting upvalue "..b + 1 .." from "..tostring(stack.upvalues))
		local value = stack.upvalues[(b + 1)]
		local origin = stack.upvalues[-(b + 1)]
		stack[a] = origin[value]
		--l_debug_print(stack[a])
	end},
	--GETGLOBAL; loads a constant found in Bx, gets it from the env, into stack's A
	[5] = {name = "GETGLOBAL", action = function(info, chunk, stack, a, b, c, bx)
		local constant = chunk.constants[bx + 1]
		
		stack[a] = chunk.env[constant]
	end, uses_constants = {bx = true}},
	--GETTABLE
	[6] = {name = "GETTABLE", action = function(info, chunk, stack, a, b, c, bx)
		local value_2 = l_get_constant(chunk, stack, c)
		
		stack[a] = stack[b][value_2]
	end, uses_constants = {c = true}},
	--SETGLOBAL
	[7] = {name = "SETGLOBAL", action = function(info, chunk, stack, a, b, c, bx)
		local constant = chunk.constants[bx + 1]
		
		chunk.env[constant] = stack[a]
	end, uses_constants = {bx = true}},
	--SETUPVAL
	[8] = {name = "SETUPVAL", action = function(info, chunk, stack, a, b, c, bx)
		--l_debug_print("getting upvalue "..b + 1 .." from "..tostring(stack.upvalues))
		local value = stack.upvalues[(b + 1)]
		local origin = stack.upvalues[-(b + 1)]
		origin[value] = stack[a]
		--l_debug_print(stack[a])
	end},
	--SETTABLE
	[9] = {name = "SETTABLE", action = function(info, chunk, stack, a, b, c, bx)
		local value_1 = l_get_constant(chunk, stack, b)
		local value_2 = l_get_constant(chunk, stack, c)
		
		stack[a][value_1] = value_2
	end, uses_constants = {b = true, c = true}},
	--NEWTABLE
	[10] = {name = "NEWTABLE", action = function(info, chunk, stack, a, b, c, bx)
		stack[a] = table.new(b, c)
	end},
	--SELF
	[11] = {name = "SELF", action = function(info, chunk, stack, a, b, c, bx)
		local value_2 = l_get_constant(chunk, stack, c)
		
		--the order matters here for some reason?
		stack[a + 1] = stack[b]
		stack[a] = stack[b][value_2]
	end, uses_constants = {c = true}},
	--ADD
	[12] = {name = "ADD", action = function(info, chunk, stack, a, b, c, bx)
		local value_1 = l_get_constant(chunk, stack, b)
		local value_2 = l_get_constant(chunk, stack, c)
		
		stack[a] = value_1 + value_2
	end, uses_constants = {b = true, c = true}},
	--SUB
	[13] = {name = "SUB", action = function(info, chunk, stack, a, b, c, bx)
		local value_1 = l_get_constant(chunk, stack, b)
		local value_2 = l_get_constant(chunk, stack, c)
		
		stack[a] = value_1 - value_2
	end, uses_constants = {b = true, c = true}},
	--MUL
	[14] = {name = "MUL", action = function(info, chunk, stack, a, b, c, bx)
		local value_1 = l_get_constant(chunk, stack, b)
		local value_2 = l_get_constant(chunk, stack, c)
		
		stack[a] = value_1 * value_2
	end, uses_constants = {b = true, c = true}},
	--DIV
	[15] = {name = "DIV", action = function(info, chunk, stack, a, b, c, bx)
		local value_1 = l_get_constant(chunk, stack, b)
		local value_2 = l_get_constant(chunk, stack, c)
		
		stack[a] = value_1 / value_2
	end, uses_constants = {b = true, c = true}},
	--MOD
	[16] = {name = "MOD", action = function(info, chunk, stack, a, b, c, bx)
		local value_1 = l_get_constant(chunk, stack, b)
		local value_2 = l_get_constant(chunk, stack, c)
		
		stack[a] = value_1 % value_2
	end, uses_constants = {b = true, c = true}},
	--POW
	[17] = {name = "POW", action = function(info, chunk, stack, a, b, c, bx)
		local value_1 = l_get_constant(chunk, stack, b)
		local value_2 = l_get_constant(chunk, stack, c)
		
		stack[a] = value_1 ^ value_2
	end, uses_constants = {b = true, c = true}},
	--UNM
	[18] = {name = "UNM", action = function(info, chunk, stack, a, b, c, bx)
		stack[a] = -stack[b]
	end},
	--NOT
	[19] = {name = "NOT", action = function(info, chunk, stack, a, b, c, bx)
		stack[a] = not stack[b]
	end},
	--LEN
	[20] = {name = "LEN", action = function(info, chunk, stack, a, b, c, bx)
		stack[a] = #stack[b]
	end},
	--CONCAT
	[21] = {name = "CONCAT", action = function(info, chunk, stack, a, b, c, bx)
		stack[a] = stack[b]
		
		for i = b + 1, c do
			stack[a] = stack[a]..stack[i]
		end
	end},
	--JMP
	[22] = {name = "JMP", action = function(info, chunk, stack, a, b, c, bx, sbx)
		stack.program_counter = stack.program_counter + sbx
	end},
	--EQ
	[23] = {name = "EQ", action = function(info, chunk, stack, a, b, c, bx)
		local value_1 = l_get_constant(chunk, stack, b)
		local value_2 = l_get_constant(chunk, stack, c)
		
		local target = a == 1
		
		if (value_1 == value_2) ~= target then
			stack.program_counter = stack.program_counter + 1
		end
	end, uses_constants = {b = true, c = true}},
	--LT
	[24] = {name = "LT", action = function(info, chunk, stack, a, b, c, bx)
		local value_1 = l_get_constant(chunk, stack, b)
		local value_2 = l_get_constant(chunk, stack, c)
		
		local target = a == 1
		
		if (value_1 < value_2) ~= target then
			stack.program_counter = stack.program_counter + 1
		end
	end, uses_constants = {b = true, c = true}},
	--LE
	[25] = {name = "LE", action = function(info, chunk, stack, a, b, c, bx)
		local value_1 = l_get_constant(chunk, stack, b)
		local value_2 = l_get_constant(chunk, stack, c)
		
		local target = a == 1
		
		if (value_1 <= value_2) ~= target then
			stack.program_counter = stack.program_counter + 1
		end
	end, uses_constants = {b = true, c = true}},
	--TEST
	[26] = {name = "TEST", action = function(info, chunk, stack, a, b, c, bx)
		if (not not stack[a]) ~= (c ~= 0) then
			stack.program_counter = stack.program_counter + 1
		end
	end},
	--TESTSET
	[27] = {name = "TESTSET", action = function(info, chunk, stack, a, b, c, bx)
		if (not not stack[b]) == (c ~= 0) then
			stack[a] = stack[b]
		else
			stack.program_counter = stack.program_counter + 1
		end
	end},
	--CALL
	[28] = {name = "CALL", action = function(info, chunk, stack, a, b, c, bx)
		local num_args = b - 1
		local num_returns = c - 1
		
		--if b is 0, the call parameters will default to the top of the stack
		if b == 0 then
			num_args = stack.top - a
		else
			stack.top = a + b
		end
		
		l_debug_print("calling with args", table.unpack(stack, a + 1, a + num_args))
		
		--hack: override environment functions
		if stack[a] == getfenv then
			l_place_returns(stack, a, nil, chunk.env)
			
			return
		elseif stack[a] == setfenv and stack[a + 1] == 1 then
			chunk.env = stack[a + 2]
			l_place_returns(stack, a, nil)
			return
		end
		
		--if c is 0, l_place_returns will default to the amount of args
		--l_place_returns(stack, a, c > 0 and num_returns, stack[a](table.unpack(stack, a + 1, a + num_args)))
		l_place_returns(stack, a, c > 0 and num_returns, stack[a](table.unpack(stack, a + 1, a + num_args)))
	end},
	--TAILCALL
	[29] = {name = "TAILCALL", action = function(info, chunk, stack, a, b, c, bx)
		local num_args = b - 1
		local num_returns = c - 1
		
		--if b is 0, the call parameters will default to the top of the stack
		if b == 0 then
			num_args = stack.top - a
		end
		
		l_debug_print("tailcalling with args", table.unpack(stack, a + 1, a + num_args))
		
		--[[
		                               -
		          -                 - - -             -
		----   - -   -    -     -  -          -     - --
		        -          -     -        -       -   ---
		            -       -  -            -   -
					         -             
		]]
		
		--if c is 0, l_place_returns will default to the amount of args
		--TODO: free the stack here?
		return stack[a](table.unpack(stack, a + 1, a + num_args))
	end, returnable = true},
	--RETURN
	[30] = {name = "RETURN", action = function(info, chunk, stack, a, b, c, bx)
		local num_returns = b - 1
		
		--if b is 0, the amount of returns will default to the top of the stack
		if b == 0 then
			num_returns = stack.top - a + 1
		end
		
		if stack.open_upvalues then
			--l_close_upvalues(stack, a)
		end
		
		return table.unpack(stack, a, a - 1 + num_returns)
	end, returnable = true},
	--FORLOOP
	[31] = {name = "FORLOOP", action = function(info, chunk, stack, a, b, c, bx, sbx)
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
	end},
	--FORPREP
	[32] = {name = "FORPREP", action = function(info, chunk, stack, a, b, c, bx, sbx)
		local value = stack[a]
		local limit = stack[a + 1]
		local step = stack[a + 2]
		local external_value = stack[a + 3]
		
		stack[a] = stack[a] - step
		
		--jump to the FORLOOP
		stack.program_counter = stack.program_counter + sbx
	end},
	--TFORLOOP
	[33] = {name = "TFORLOOP", action = function(info, chunk, stack, a, b, c, bx, sbx)
		local value = stack[a] --the initial value
		local limit = stack[a + 1]
		local step = stack[a + 2]
		local external_value = stack[a + 3] --the visible value (e.g. i)
		
		--stack[a] = value + step
		
		--jump back if..
		--l_debug_print(a + 3, a + 2 + c)
		--l_debug_print(a + 3, (a + 2 + c) - (a + 3))
		l_place_returns(stack, a + 3, (a + 2 + c) - (a + 3) + 1, stack[a](stack[a + 1], stack[a + 2]))
		
		if stack[a + 3] ~= nil then
			stack[a + 2] = stack[a + 3]
		else
			stack.program_counter = stack.program_counter + 1
		end
	end},
	--SETLIST
	[34] = {name = "SETLIST", action = function(info, chunk, stack, a, b, c, bx)
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
	end},
	--CLOSE
	[35] = {name = "CLOSE", action = function(info, chunk, stack, a, b, c, bx)
		l_close_upvalues(stack, a)
	end},
	--CLOSURE
	[36] = {name = "CLOSURE", action = function(info, chunk, stack, a, b, c, bx)
		local proto = chunk.protos[bx + 1]
		
		local upvalues
		
		--lua's upvalue system is hacky
		for i = 1, proto.num_upvalues do
			local inst = chunk.instructions[stack.program_counter]
			local opcode, reg_a, reg_b, reg_c, reg_bx, reg_sbx = l_decode_inst(inst)
			
			--making tables is scary here
			upvalues = upvalues or table.new(proto.num_upvalues, 0)
			stack.open_upvalues = stack.open_upvalues or table.new(proto.num_upvalues, 0)
			--mark this stack as protected, since otherwise the upvalues will corrupt
			stack.protected = true
			upvalues.protecting = stack
			--l_debug_print("making upvalues table", upvalues)
			
			if opcode == 0 then --MOVE
				--open an upvalue
				--upvalue_num is the index in the origin's stack
				--GETUPVAL uses that index
				--i is the index in the upvalues table
				local upvalue_num = reg_b
				
				l_debug_print("opening upvalue["..i.."] lua "..upvalue_num)
				--print("exposing upvalue["..i.."] lua "..upvalue_num)
				--to save on memory the values are stored consecutively
				upvalues[i] = upvalue_num
				upvalues[-i] = stack
				
				stack.open_upvalues[upvalue_num] = upvalues
			elseif opcode == 4 then --GETUPVAL
				local upvalue_i = reg_b + 1
				local upvalue_num = stack.upvalues[upvalue_i]
				local upvalue_origin = stack.upvalues[-upvalue_i]
				
				--print("exposing GETUPVAL upvalue: index", upvalue_i, "lua", upvalue_num, origin)
				--l_assert(upvalue_num ~= nil, true, "no upvalue found")
				
				--local value = stack.upvalues[(upvalue_num)]
				--local origin = upvalue_origin--stack.upvalues[-(upvalue_num)]
				l_assert(upvalue_origin ~= nil, true, "no upvalue found")
				--for i, v in pairs(stack.upvalues) do print(i, v, type(v) == "table" and tonumber(i) and v[stack.upvalues[tonumber(i) - 1]]) end
				
				upvalues[i] = upvalue_num
				upvalues[-i] = upvalue_origin
				l_debug_print("closure getupval mentioned")
				
				upvalue_origin.open_upvalues[upvalue_num] = upvalues
			else
				l_assert(instructions[opcode].name, "MOVE or GETUPVAL", "unexpected opcode "..opcode.." after closure instruction")
			end
			
			stack.program_counter = stack.program_counter + 1
		end
		
		--wrap the function
		stack[a] = function(...)
			return l_run_chunk(proto, upvalues, ...)
		end
	end},
	--VARARG
	[37] = {name = "VARARG", action = function(info, chunk, stack, a, b, c, bx)
		--this implementation may not be right, but it's the best possible
		local start = a --stack[a]
		local num = b - 1
		
		local i = start
		local evil_i = -1
		
		--if b is 0, the amount of copied parameters will adjust
		l_debug_print("varg", i)
		stack.top = start + num
		
		while (b == 0 and -evil_i <= stack.vararg_num) or (b ~= 0 and i <= start + num) do
			l_debug_print("retrieving "..(evil_i).." into "..i)
			--print("retrieving "..(evil_i).." "..tostring(stack[evil_i]).." ".." into "..i)
			stack[i] = stack[evil_i]
			
			i = i + 1
			evil_i = evil_i - 1
		end
	end},
}

function l_place_returns(stack, target_index, num, ...)
	--pop the function and arguments from the stack
	for i = target_index, stack.top do
		stack[i] = nil
	end
	
	num = num or select("#", ...)
	
	stack.top = target_index - 1 + num

	for i = 1, num do
		--l_debug_print("placing in ", target_index + i - 1, ", ", select(i, ...))
		--print("placing in ", target_index + i - 1, ", ", select(i, ...))
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

function l_decode_inst(inst)
	--first parse the instruction into iABC format
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
	local reg_sbx = reg_bx - ((2 ^ 18) / 2 - 1) --signed bx
	
	return opcode, reg_a, reg_b, reg_c, reg_bx, reg_sbx
end

function l_run_chunk(chunk, upvalues, ...)
	local stack = luna_cache_stacks and free_stacks[1] or setmetatable({}, meta)
	
	stack.upvalues = upvalues
	stack.top = 0
	
	--program_counter is the next instruction to execute
	stack.program_counter = 1
	
	--put the parameters into place
	local VARARG_ISVARARG = 2
	
	if bit.band(chunk.is_vararg, VARARG_ISVARARG) ~= 0 then
		--l_debug_print("varg")
		--l_place_varargs(stack, ...)
	else
		--l_debug_print("not varg")
	end
	l_place_varargs(stack, select(chunk.num_parameters + 1, ...))
	l_place_returns(stack, 0, chunk.num_parameters, ...)
	
	while true do
		local inst = chunk.instructions[stack.program_counter]
		
		l_assert(inst ~= nil, true, "next instruction is nil")
		
		stack.program_counter = stack.program_counter + 1
		
		local opcode, reg_a, reg_b, reg_c, reg_bx, reg_sbx = l_decode_inst(inst)
		
		l_assert(instructions[opcode].action ~= nil, true, "tried running unimplemented opcode "..opcode.." ("..instructions[opcode].name..")")
		
		l_debug_print("inst #"..(stack.program_counter - 1)..":", instructions[opcode].name, reg_a, reg_b, reg_c, reg_bx, reg_sbx)
		
		local is_returnable = instructions[opcode].returnable
		
		--call the opcode
		if not is_returnable then
			l_error_handler(
				stack, chunk,
				pcall(instructions[opcode].action, info, chunk, stack, reg_a, reg_b, reg_c, reg_bx, reg_sbx)
			)
			
			--[[
			local a = "stack: "
			for i, v in ipairs(stack) do a = a..tostring(i).."="..tostring(v).."," end
			l_debug_print(a)
			]]
		else
			--if a return was found, return everything
			if luna_cache_stacks then
				table.insert(free_stacks, stack)
				
				if upvalues then
					upvalues.protecting.protected = nil
				end
			end
			
			return l_finish_chunk(l_error_handler(
				stack, chunk,
				pcall(instructions[opcode].action, info, chunk, stack, reg_a, reg_b, reg_c, reg_bx, reg_sbx)
			))
		end
	end
end

function l_error_handler(stack, chunk, success, ...)
	if not success then
		local message = ...
		local out = tostring(message)..("\n[Luna] Recent instructions (%s):\n"):format(chunk.debugname)
		
		for i = math.max(stack.program_counter - 16 - 32, 1), stack.program_counter - 1 do
			local inst = chunk.instructions[i]
			local opcode, reg_a, reg_b, reg_c, reg_bx, reg_sbx = l_decode_inst(inst)
			
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
	
	return ...
end

--the call operation always makes a stack, so go ahead and clear it for later usage
--clears stacks and returns everything back
function l_finish_chunk(...)
	l_debug_print("RETURNING", ...)
	
	--TODO: assumes we have table.clear
	if #free_stacks > 50 then
		free_stacks[#free_stacks] = nil
	elseif luna_cache_stacks then
		for i = #free_stacks, 1, -1 do
			--pseudo-memory management system
			if not free_stacks[i].protected then
				--table.clear(free_stacks[i])
				
				break
			end
		end
	end
	
	return ...
end

local function l_load(src, env, name)
	local info = {}
	
	l_load_header(src, info)
	
	info.chunk = {}
	
	local chunk = info.chunk
	
	chunk.env = env
	
	l_load_chunk(src, info, chunk, name)
	
	--parse the instructions

	-- return function() end
	return function(...)
		return l_run_chunk(chunk, nil, ...)
	end
end

return l_load
