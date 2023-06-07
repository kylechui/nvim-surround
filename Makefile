all: test_lua 

test_lua:
		nvim --headless -u './tests/minimal_init.lua' -c "PlenaryBustedDirectory ./tests/aliases_spec.lua { minimal_init = './tests/minimal_init.lua', sequential = true }"
		nvim --headless -u './tests/minimal_init.lua' -c "PlenaryBustedDirectory ./tests/basics_spec.lua { minimal_init = './tests/minimal_init.lua', sequential = true }"
		nvim --headless -u './tests/minimal_init.lua' -c "PlenaryBustedDirectory ./tests/configuration_spec.lua { minimal_init = './tests/minimal_init.lua', sequential = true }"
		nvim --headless -u './tests/minimal_init.lua' -c "PlenaryBustedDirectory ./tests/dot_repeat_spec.lua { minimal_init = './tests/minimal_init.lua', sequential = true }"
		nvim --headless -u './tests/minimal_init.lua' -c "PlenaryBustedDirectory ./tests/function_calls_spec.lua { minimal_init = './tests/minimal_init.lua', sequential = true }"
		nvim --headless -u './tests/minimal_init.lua' -c "PlenaryBustedDirectory ./tests/html_tags_spec.lua { minimal_init = './tests/minimal_init.lua', sequential = true }"
		nvim --headless -u './tests/minimal_init.lua' -c "PlenaryBustedDirectory ./tests/jumps_spec.lua { minimal_init = './tests/minimal_init.lua', sequential = true }"

