all: test_lua 

test_lua:
		nvim --headless -u './tests/minimal_init.lua' -c "PlenaryBustedDirectory ./tests/ { minimal_init = './tests/minimal_init.lua', sequential = true }"
