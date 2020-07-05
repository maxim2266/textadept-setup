-- general settings
buffer.use_tabs = true
buffer.tab_width = 4

buffer.property["fold"] = "0"
buffer.fold_flags = 0

buffer.indentation_guides = buffer.IV_NONE

textadept.editing.strip_trailing_spaces = true

keys.cb = function()
	ui.switch_buffer(true)
end

-- theme and tweaks
buffer:set_theme("light", { font = "Liberation Mono", fontsize = 10 })

buffer.property["style.default"] = "font:$(font),size:$(fontsize),fore:0x1D1D1D,back:$(color.light_white)"

buffer.caret_line_back = 0xF6F6F6	-- color in "0xBBGGRR" format
buffer.property["style.type"] = buffer.property["style.keyword"]

-- Shift+Enter handlers
local function line_info()
	-- following the code from modules/textadept/editing.lua:209
	local lno = buffer:line_from_position(buffer.current_pos)
	local b, e = buffer:position_from_line(lno), buffer.line_end_position[lno]
	local i = e

	while i > b do   -- index of the first trailing space char
		local c = buffer.char_at[i - 1]

		if c ~= 0x9 and c ~= 0x20 then	-- tab or space
			break
		end

		i = i - 1
	end

	return { no = lno, pos = b, len = i - b, span = e - b }
end

local function open_block(fn)
	local line = line_info()

	if line.len > 0 then	-- only on non-empty lines
		buffer:begin_undo_action()
		fn(line)
		buffer:end_undo_action()
	end
end

local function add_block(op, clo)
	buffer:add_text(op)
	buffer:new_line()
	buffer:new_line()
	buffer:add_text(clo)
	buffer:line_up()

	if buffer.use_tabs then
		buffer:tab()
	else
		buffer:add_text(string.rep(" ", buffer.tab_width))
	end
end

local function c_open_block()
	open_block(function()
		buffer:line_end()
		buffer:new_line()
		add_block("{", "}")
	end)
end

local function java_open_block()
	open_block(function(line)
		buffer:home()

		if line.len < line.span then	-- cut trailing whitespace
			buffer:delete_range(line.pos + line.len, line.span - line.len)
		end

		buffer:line_end()
		add_block(" {", "}")
	end)
end

local function lua_open_block()
	open_block(function()
		buffer:line_end()
		add_block("", "end")
	end)
end

events.connect(events.LEXER_LOADED, function(lexer)
	local function assign_key_handler(key, fn)
		local k = keys[lexer]

		if k then
			k[key] = fn
		else
			keys[lexer] = { [key] = fn }
		end
	end

	if lexer == "ansi_c" then
		keys.ansi_c["s\n"] = c_open_block
	elseif lexer == "lua" then
		assign_key_handler("s\n", lua_open_block)
	elseif lexer == "go"
		or lexer == "csharp"
		or lexer == "dart"
		or lexer == "java"
		or lexer == "javascript"
		or lexer == "jsp"
		or lexer == "objective_c"
		or lexer == "perl"
		or lexer == "php"
		or lexer == "protobuf"
		or lexer == "vala"
	then
		assign_key_handler("s\n", java_open_block)
	end
end)
